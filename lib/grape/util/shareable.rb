# frozen_string_literal: true

module Grape
  module Util
    # Everything a process has to settle once before a compiled API can be
    # served from non-main Ractors, which may read no unshareable value a
    # class, a module or a constant holds.
    #
    # Each step freezes state that is written while an application boots and
    # only read once it serves, so freezing it costs a booted process nothing
    # -- and says so loudly if something writes to it afterwards.
    module Shareable
      FALLBACK_LOCALE = :en
      private_constant :FALLBACK_LOCALE

      # Whole modules rather than named constants and readers, so that a table
      # added upstream is covered too, and because which ones a given
      # application reaches is not knowable by reading: +Rack::Utils+ is here
      # for +SYMBOL_TO_STATUS_CODE+, which nothing touches until an endpoint
      # answers +status :created+, and for +ESCAPE_HTML+, which only an HTML
      # error response reads, and only on Rack 2.2.
      #
      # Builder backs +to_xml+, and is loaded before they are frozen because
      # the XML formatter would otherwise first reach for it from a Ractor,
      # and find its tables unfrozen. +Rack::Multipart::Parser+ is here
      # although an upload cannot work in a Ractor at all, so that it fails
      # where the reason is (Ruby's Tempfile is a Delegator) rather than on a
      # constant this could have frozen.
      DEPENDENCY_GLOBALS = %w[
        Rack::Utils Rack::QueryParser Rack::Request::Helpers Rack::Headers Rack::Multipart::Parser
        ActiveSupport::XmlMini Builder::XChar JSON MultiJson MultiJSON MultiXml
      ].freeze
      private_constant :DEPENDENCY_GLOBALS

      module_function

      # Ruby 3.3 and 3.4 refuse to make a Method or an UnboundMethod shareable,
      # and an API is full of them: every endpoint holds its route block as one
      # (Endpoint#source), and dry-types builds its coercers out of them. So
      # nothing can be finalized there, whatever the API looks like.
      def supported?
        ::Ractor.make_shareable(Object.instance_method(:itself))
        true
      rescue ::Ractor::Error
        false
      end

      def freeze_globals!
        freeze_config!
        freeze_dependency_globals!
        snapshot_translations!
      end

      # dry-configurable memoizes a setting the first time it is read, so a
      # config frozen before that raises FrozenError on the first read instead
      # of answering it. Read every setting first and the memo is complete,
      # which is what makes the frozen config readable at all -- from any
      # Ractor, from then on.
      def freeze_config!
        return if Grape.config.frozen?

        Grape.config._settings.each { |setting| Grape.config[setting.name] }
        ::Ractor.make_shareable(Grape.config)
      end

      # The tables and options a request reads out of Grape's dependencies,
      # which a non-main Ractor may not touch while they are mutable. Both
      # places they are kept: constants, such as Rack's media type lists, and
      # class instance variables, such as Rack's default query parser or the
      # json gem's +dump_default_options+, which every JSON response reads
      # before json 3. Each is filled as its library loads and only read
      # afterwards, so freezing it costs a booted process nothing -- upstream
      # candidates, all.
      def freeze_dependency_globals!
        begin
          require 'builder'
        rescue LoadError
          nil
        end

        # Grape's own copy of Rack's default parser, frozen: Rack keeps its in a
        # class instance variable, and this leaves that one alone.
        Grape::Request.query_parser = ::Ractor.make_shareable(Rack::Utils.default_query_parser.dup)

        DEPENDENCY_GLOBALS.each do |name|
          next unless Object.const_defined?(name)

          mod = Object.const_get(name)
          mod.constants.each { |const| share { mod.const_get(const) } }
          mod.instance_variables.each { |ivar| share { mod.instance_variable_get(ivar) } }
        end
      end

      # What cannot be read or frozen is what this never promised to cover: the
      # request path reaches for tables and options, not for live objects, and
      # a constant can also be one an optional file would have to define
      # (JSON::GenericObject, for one, which +constants+ lists and +const_get+
      # then refuses).
      def share
        ::Ractor.make_shareable(yield)
      rescue ::Ractor::Error, NameError
        nil
      end

      # I18n is out of reach entirely: its configuration lives in class
      # variables, which a non-main Ractor may not even read. Take a frozen
      # copy of the loaded translations instead, which {Translation} answers
      # from in Ractor mode -- for the default locale, since choosing one per
      # request is exactly what is out of reach.
      #
      # Only the +grape+ subtree is taken, which is everything Grape ever looks
      # a message up under. The rest of a locale is not ours to freeze, and
      # cannot be anyway -- ActiveSupport's own +en+ holds lambdas.
      def snapshot_translations!
        ::I18n.backend.__send__(:init_translations) unless ::I18n.backend.initialized?

        loaded = ::I18n.backend.translations
        locale = loaded.key?(::I18n.default_locale) ? ::I18n.default_locale : FALLBACK_LOCALE
        subtree = loaded.dig(locale, :grape) || loaded.dig(FALLBACK_LOCALE, :grape)
        @translations = ::Ractor.make_shareable({ grape: subtree.deep_dup })
      end

      # The frozen translations for the locale that was default when the
      # process was finalized, or nil before that.
      def translations
        @translations
      end
    end
  end
end
