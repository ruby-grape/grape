# frozen_string_literal: true

module Grape
  module DSL
    module RequestResponse
      # Specify the default format for the API's serializers.
      # May be `:json` or `:txt` (default).
      def default_format(new_format = nil)
        return inheritable_setting.namespace_inheritable[:default_format] if new_format.nil?

        inheritable_setting.namespace_inheritable[:default_format] = new_format.to_sym
      end

      # Specify the format for the API's serializers.
      # May be `:json`, `:xml`, `:txt`, etc.
      def format(new_format = nil)
        return inheritable_setting.namespace_inheritable[:format] if new_format.nil?

        symbolic_new_format = new_format.to_sym
        inheritable_setting.namespace_inheritable[:format] = symbolic_new_format
        inheritable_setting.namespace_inheritable[:default_error_formatter] = Grape::ErrorFormatter.formatter_for(symbolic_new_format)

        content_type = content_types[symbolic_new_format]
        raise Grape::Exceptions::MissingMimeType.new(new_format) unless content_type

        inheritable_setting.add_content_type(symbolic_new_format, content_type)
      end

      # Specify a custom formatter for a content-type.
      def formatter(content_type, new_formatter)
        inheritable_setting.add_formatter(content_type.to_sym, new_formatter)
      end

      # Specify a custom parser for a content-type.
      def parser(content_type, new_parser)
        inheritable_setting.add_parser(content_type.to_sym, new_parser)
      end

      # Specify a default error formatter.
      def default_error_formatter(new_formatter_name = nil)
        return inheritable_setting.namespace_inheritable[:default_error_formatter] if new_formatter_name.nil?

        new_formatter = Grape::ErrorFormatter.formatter_for(new_formatter_name)
        inheritable_setting.namespace_inheritable[:default_error_formatter] = new_formatter
      end

      def error_formatter(format, options = nil, with: nil)
        formatter = with || options
        inheritable_setting.add_error_formatter(format.to_sym, formatter)
      end

      # Specify additional content-types, e.g.:
      #   content_type :xls, 'application/vnd.ms-excel'
      def content_type(key, val)
        inheritable_setting.add_content_type(key.to_sym, val)
      end

      # All available content types.
      def content_types
        Grape::ContentTypes.content_types_for(inheritable_setting.content_types)
      end

      # Specify the default status code for errors.
      def default_error_status(new_status = nil)
        return inheritable_setting.namespace_inheritable[:default_error_status] if new_status.nil?

        inheritable_setting.namespace_inheritable[:default_error_status] = new_status
      end

      # Allows you to rescue certain exceptions that occur to return
      # a grape error rather than raising all the way to the
      # server level.
      #
      # @example Rescue from custom exceptions
      #     class ExampleAPI < Grape::API
      #       class CustomError < StandardError; end
      #
      #       rescue_from CustomError
      #     end
      #
      META_RESCUE_SELECTORS = %i[all grape_exceptions internal_grape_exceptions].freeze
      private_constant :META_RESCUE_SELECTORS

      # @overload rescue_from(*exception_classes, **options)
      #   @param [Array] exception_classes A list of classes that you want to rescue, or
      #     one of the meta selectors +:all+, +:grape_exceptions+,
      #     +:internal_grape_exceptions+. Meta selectors must be used alone;
      #     mixing with exception classes raises +ArgumentError+.
      #   @param [Block] block Execution block to handle the given exception.
      #   @param [Proc] with Execution proc to handle the given exception as an alternative
      #     to passing a block.
      #   @param [Boolean] rescue_subclasses Also rescue subclasses of exception classes;
      #     defaults to +true+.
      #   @param [Boolean] backtrace Include the rescued exception's backtrace in the
      #     rescue response body.
      #   @param [Boolean] original_exception Include +inspect+ of the rescued exception
      #     in the rescue response body.
      def rescue_from(*args, with: nil, rescue_subclasses: true, backtrace: false, original_exception: false, &block)
        handler = extract_handler(args, with:, block:)
        meta_selector = (args & META_RESCUE_SELECTORS).first
        raise ArgumentError, "rescue_from #{meta_selector.inspect} does not accept additional arguments" if meta_selector && args.size > 1

        case meta_selector
        when :all
          inheritable_setting.add_all_rescue_handler(handler)
        when :grape_exceptions
          inheritable_setting.add_grape_exceptions_rescue_handler(handler)
        when :internal_grape_exceptions
          inheritable_setting.add_internal_grape_exceptions_rescue_handler(handler)
        else
          inheritable_setting.add_rescue_handlers(args.to_h { |klass| [klass, handler] }, subclasses: rescue_subclasses)
        end

        inheritable_setting.add_rescue_options(RescueOptions.new(backtrace:, original_exception:))
      end

      # Allows you to specify a default representation entity for a
      # class. This allows you to map your models to their respective
      # entities once and then simply call `present` with the model.
      #
      # @example
      #   class ExampleAPI < Grape::API
      #     represent User, with: Entity::User
      #
      #     get '/me' do
      #       present current_user # with: Entity::User is assumed
      #     end
      #   end
      #
      # Note that Grape will automatically go up the class ancestry to
      # try to find a representing entity, so if you, for example, define
      # an entity to represent `Object` then all presented objects will
      # bubble up and utilize the entity provided on that `represent` call.
      #
      # @param model_class [Class] The model class that will be represented.
      # @option options [Class] :with The entity class that will represent the model.
      def represent(model_class, with:)
        raise Grape::Exceptions::InvalidWithOptionForRepresent.new unless with.is_a?(Class)

        inheritable_setting.namespace_stackable[:representations] = { model_class => with }
      end

      private

      def extract_handler(args, with:, block:)
        raise ArgumentError, 'both :with option and block cannot be passed' if block && with

        return args.pop if args.last.is_a?(Proc)
        return block if block
        return unless with

        case with
        when Proc, Symbol then with
        when String then with.to_sym
        else raise ArgumentError, "with: #{with.class}, expected Symbol, String or Proc"
        end
      end
    end
  end
end
