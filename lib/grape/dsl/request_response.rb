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

        inheritable_setting.namespace_stackable[:content_types] = { symbolic_new_format => content_type }
      end

      # Specify a custom formatter for a content-type.
      def formatter(content_type, new_formatter)
        inheritable_setting.namespace_stackable[:formatters] = { content_type.to_sym => new_formatter }
      end

      # Specify a custom parser for a content-type.
      def parser(content_type, new_parser)
        inheritable_setting.namespace_stackable[:parsers] = { content_type.to_sym => new_parser }
      end

      # Specify a default error formatter.
      def default_error_formatter(new_formatter_name = nil)
        return inheritable_setting.namespace_inheritable[:default_error_formatter] if new_formatter_name.nil?

        new_formatter = Grape::ErrorFormatter.formatter_for(new_formatter_name)
        inheritable_setting.namespace_inheritable[:default_error_formatter] = new_formatter
      end

      def error_formatter(format, options)
        formatter = if options.is_a?(Hash) && options.key?(:with)
                      options[:with]
                    else
                      options
                    end

        inheritable_setting.namespace_stackable[:error_formatters] = { format.to_sym => formatter }
      end

      # Specify additional content-types, e.g.:
      #   content_type :xls, 'application/vnd.ms-excel'
      def content_type(key, val)
        inheritable_setting.namespace_stackable[:content_types] = { key.to_sym => val }
      end

      # All available content types.
      def content_types
        c_types = inheritable_setting.namespace_stackable_with_hash(:content_types)
        Grape::ContentTypes.content_types_for c_types
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
      # @overload rescue_from(*exception_classes, **options)
      #   @param [Array] exception_classes A list of classes that you want to rescue, or
      #     the symbol :all to rescue from all exceptions.
      #   @param [Block] block Execution block to handle the given exception.
      #   @param [Hash] options Options for the rescue usage.
      #   @option options [Boolean] :backtrace Include a backtrace in the rescue response.
      #   @option options [Boolean] :rescue_subclasses Also rescue subclasses of exception classes
      #   @param [Proc] handler Execution proc to handle the given exception as an
      #     alternative to passing a block.
      def rescue_from(*args, **options, &block)
        if args.last.is_a?(Proc)
          handler = args.pop
        elsif block
          handler = block
        end

        raise ArgumentError, 'both :with option and block cannot be passed' if block && options.key?(:with)

        handler ||= extract_with(options)

        if args.include?(:all)
          inheritable_setting.namespace_inheritable[:rescue_all] = true
          inheritable_setting.namespace_inheritable[:all_rescue_handler] = handler
        elsif args.include?(:grape_exceptions)
          inheritable_setting.namespace_inheritable[:rescue_all] = true
          inheritable_setting.namespace_inheritable[:rescue_grape_exceptions] = true
          inheritable_setting.namespace_inheritable[:grape_exceptions_rescue_handler] = handler
        else
          handler_type =
            case options[:rescue_subclasses]
            when nil, true
              :rescue_handlers
            else
              :base_only_rescue_handlers
            end

          inheritable_setting.namespace_reverse_stackable[handler_type] = args.to_h { |arg| [arg, handler] }
        end

        inheritable_setting.namespace_stackable[:rescue_options] = options
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
      def represent(model_class, options)
        raise Grape::Exceptions::InvalidWithOptionForRepresent.new unless options[:with].is_a?(Class)

        inheritable_setting.namespace_stackable[:representations] = { model_class => options[:with] }
      end

      private

      def extract_with(options)
        return unless options.key?(:with)

        with_option = options.delete(:with)
        return with_option if with_option.instance_of?(Proc)
        return with_option.to_sym if with_option.instance_of?(Symbol) || with_option.instance_of?(String)

        raise ArgumentError, "with: #{with_option.class}, expected Symbol, String or Proc"
      end
    end
  end
end
