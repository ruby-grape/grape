require 'active_support/concern'

module Grape
  module DSL
    module RequestResponse
      extend ActiveSupport::Concern

      included do

      end

      module ClassMethods
        # Specify the default format for the API's serializers.
        # May be `:json` or `:txt` (default).
        def default_format(new_format = nil)
          new_format ? set(:default_format, new_format.to_sym) : settings[:default_format]
        end

        # Specify the format for the API's serializers.
        # May be `:json`, `:xml`, `:txt`, etc.
        def format(new_format = nil)
          if new_format
            set(:format, new_format.to_sym)
            # define the default error formatters
            set(:default_error_formatter, Grape::ErrorFormatter::Base.formatter_for(new_format, {}))
            # define a single mime type
            mime_type = content_types[new_format.to_sym]
            raise Grape::Exceptions::MissingMimeType.new(new_format) unless mime_type
            settings.imbue(:content_types, new_format.to_sym => mime_type)
          else
            settings[:format]
          end
        end

        # Specify a custom formatter for a content-type.
        def formatter(content_type, new_formatter)
          settings.imbue(:formatters, content_type.to_sym => new_formatter)
        end

        # Specify a custom parser for a content-type.
        def parser(content_type, new_parser)
          settings.imbue(:parsers, content_type.to_sym => new_parser)
        end

        # Specify a default error formatter.
        def default_error_formatter(new_formatter_name = nil)
          if new_formatter_name
            new_formatter = Grape::ErrorFormatter::Base.formatter_for(new_formatter_name, {})
            set(:default_error_formatter, new_formatter)
          else
            settings[:default_error_formatter]
          end
        end

        def error_formatter(format, options)
          if options.is_a?(Hash) && options.key?(:with)
            formatter = options[:with]
          else
            formatter = options
          end

          settings.imbue(:error_formatters, format.to_sym => formatter)
        end

        # Specify additional content-types, e.g.:
        #   content_type :xls, 'application/vnd.ms-excel'
        def content_type(key, val)
          settings.imbue(:content_types, key.to_sym => val)
        end

        # All available content types.
        def content_types
          Grape::ContentTypes.content_types_for(settings[:content_types])
        end

        # Specify the default status code for errors.
        def default_error_status(new_status = nil)
          new_status ? set(:default_error_status, new_status) : settings[:default_error_status]
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
        # @overload rescue_from(*exception_classes, options = {})
        #   @param [Array] exception_classes A list of classes that you want to rescue, or
        #     the symbol :all to rescue from all exceptions.
        #   @param [Block] block Execution block to handle the given exception.
        #   @param [Hash] options Options for the rescue usage.
        #   @option options [Boolean] :backtrace Include a backtrace in the rescue response.
        #   @option options [Boolean] :rescue_subclasses Also rescue subclasses of exception classes
        #   @param [Proc] handler Execution proc to handle the given exception as an
        #     alternative to passing a block
        def rescue_from(*args, &block)
          if args.last.is_a?(Proc)
            handler = args.pop
          elsif block_given?
            handler = block
          end

          options = args.last.is_a?(Hash) ? args.pop : {}
          handler ||= proc { options[:with] } if options.key?(:with)

          if args.include?(:all)
            set(:rescue_all, true)
            imbue :all_rescue_handler, handler
          else
            handler_type =
                case options[:rescue_subclasses]
                when nil, true
                  :rescue_handlers
                else
                  :base_only_rescue_handlers
                end

            imbue handler_type, Hash[args.map { |arg| [arg, handler] }]
          end

          imbue(:rescue_options, options)
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
          raise Grape::Exceptions::InvalidWithOptionForRepresent.new unless options[:with] && options[:with].is_a?(Class)
          imbue(:representations, model_class => options[:with])
        end
      end
    end
  end
end
