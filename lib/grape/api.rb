# frozen_string_literal: true

module Grape
  # The API class is the primary entry point for creating Grape APIs. Users
  # should subclass this class in order to build an API.
  class API
    # Class methods that we want to call on the API rather than on the API object
    NON_OVERRIDABLE = %i[base= base_instance? call change! configuration compile! inherit_settings recognize_path reset! routes top_level_setting= top_level_setting].freeze

    Helpers = Grape::DSL::Helpers::BaseHelper

    class Boolean
      def self.build(val)
        return nil if val != true && val != false

        new
      end
    end

    class << self
      extend Forwardable

      attr_accessor :base_instance, :instances

      delegate_missing_to :base_instance

      # This is the interface point between Rack and Grape; it accepts a request
      # from Rack and ultimately returns an array of three values: the status,
      # the headers, and the body. See [the rack specification]
      # (https://github.com/rack/rack/blob/main/SPEC.rdoc) for more.
      # NOTE: This will only be called on an API directly mounted on RACK
      def_delegators :base_instance, :new, :configuration, :call, :change!, :compile!, :recognize_path, :routes

      # Initialize the instance variables on the remountable class, and the base_instance
      # an instance that will be used to create the set up but will not be mounted
      def initial_setup(base_instance_parent)
        @instances = []
        @setup = []
        @base_parent = base_instance_parent
        @base_instance = mount_instance
      end

      # Redefines all methods so that are forwarded to add_setup and be recorded
      def override_all_methods!
        (base_instance.methods - Class.methods - NON_OVERRIDABLE).each do |method_override|
          define_singleton_method(method_override) do |*args, **kwargs, &block|
            add_setup(method: method_override, args: args, kwargs: kwargs, block: block)
          end
        end
      end

      # Configure an API from the outside. If a block is given, it'll pass a
      # configuration hash to the block which you can use to configure your
      # API. If no block is given, returns the configuration hash.
      # The configuration set here is accessible from inside an API with
      # `configuration` as normal.
      def configure
        config = @base_instance.configuration
        if block_given?
          yield config
          self
        else
          config
        end
      end

      # The remountable class can have a configuration hash to provide some dynamic class-level variables.
      # For instance, a description could be done using: `desc configuration[:description]` if it may vary
      # depending on where the endpoint is mounted. Use with care, if you find yourself using configuration
      # too much, you may actually want to provide a new API rather than remount it.
      def mount_instance(configuration: nil)
        Class.new(@base_parent).tap do |instance|
          instance.configuration = Grape::Util::EndpointConfiguration.new(configuration || {})
          instance.base = self
          replay_setup_on(instance)
        end
      end

      private

      # When inherited, will create a list of all instances (times the API was mounted)
      # It will listen to the setup required to mount that endpoint, and replicate it on any new instance
      def inherited(api)
        super

        api.initial_setup(self == Grape::API ? Grape::API::Instance : @base_instance)
        api.override_all_methods!
      end

      # Replays the set up to produce an API as defined in this class, can be called
      # on classes that inherit from Grape::API
      def replay_setup_on(instance)
        @setup.each do |setup_step|
          replay_step_on(instance, **setup_step)
        end
      end

      # Adds a new stage to the set up require to get a Grape::API up and running
      def add_setup(**step)
        @setup << step
        last_response = nil
        @instances.each do |instance|
          last_response = replay_step_on(instance, **step)
        end

        refresh_mount_step if step[:method] != :mount
        last_response
      end

      # Updating all previously mounted classes in the case that new methods have been executed.
      def refresh_mount_step
        @setup.each do |setup_step|
          next if setup_step[:method] != :mount

          refresh_mount_step = setup_step.merge(method: :refresh_mounted_api)
          @setup << refresh_mount_step
          @instances.each do |instance|
            replay_step_on(instance, **refresh_mount_step)
          end
        end
      end

      def replay_step_on(instance, method:, args:, kwargs:, block:)
        return if skip_immediate_run?(instance, args, kwargs)

        eval_args = evaluate_arguments(instance.configuration, *args)
        eval_kwargs = kwargs.deep_transform_values { |v| evaluate_arguments(instance.configuration, v).first }
        response = instance.__send__(method, *eval_args, **eval_kwargs, &block)
        if skip_immediate_run?(instance, [response], kwargs)
          response
        else
          evaluate_arguments(instance.configuration, response).first
        end
      end

      # Skips steps that contain arguments to be lazily executed (on re-mount time)
      def skip_immediate_run?(instance, args, kwargs)
        instance.base_instance? &&
          (any_lazy?(args) || args.any? { |arg| arg.is_a?(Hash) && any_lazy?(arg.values) } || any_lazy?(kwargs.values))
      end

      def any_lazy?(args)
        args.any? { |argument| argument_lazy?(argument) }
      end

      def evaluate_arguments(configuration, *args)
        args.map do |argument|
          if argument_lazy?(argument)
            argument.evaluate_from(configuration)
          elsif argument.is_a?(Hash)
            argument.transform_values { |value| evaluate_arguments(configuration, value).first }
          elsif argument.is_a?(Array)
            evaluate_arguments(configuration, *argument)
          else
            argument
          end
        end
      end

      def argument_lazy?(argument)
        argument.respond_to?(:lazy?) && argument.lazy?
      end
    end
  end
end
