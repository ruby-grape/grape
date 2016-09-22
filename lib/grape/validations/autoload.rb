module Grape
  module Validations
    class Autoload
      DEFAULT_PATH = %w(api validators)

      def initialize(api)
        @api = api
        @loaded_validators = []
      end

      def try_load(name)
        return nil unless defined?(::ActiveSupport::Dependencies)

        name = name.to_s
        inner_path   = File.join(@api.to_s.deconstantize.underscore, 'validators', name).to_s
        default_path = File.join(DEFAULT_PATH, name).to_s

        found_path = [inner_path, default_path].find do |path|
          begin
            require_dependency(path)
            mark_as_loaded(name)
            update_before_remove_const_callback(path)

            true
          rescue LoadError
            nil
          end
        end
        (found_path && found_path.classify.constantize) || nil
      end

      private

      def mark_as_loaded(name)
        @loaded_validators << name
      end

      def update_before_remove_const_callback(path)
        parent_const = path.classify.split('::').first.constantize

        # see ActiveSupport::Dependencies.remove_unloadable_constants!
        parent_const.class.class_eval %{
          def before_remove_const
            #{@loaded_validators}.each do |validator_name|
              Grape::Validations.validators.delete(validator_name)
            end
          end
        }
      end
    end
  end
end
