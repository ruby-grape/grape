module Grape
  # The RemountableAPI class can replace most API classes, except for the base one that is to be mounted in rack.
  # should subclass this class in order to build an API.
  class RemountableAPI
    class << self
      # When inherited, will create a list of all instances (times the API was mounted)
      # It will listen to the setup required to mount that endpoint, and replicate it on any new instance
      def inherited(remountable_class)
        remountable_class.instance_variable_set(:@instances, [])
        remountable_class.instance_variable_set(:@setup, [])

        base_instance = Class.new(Grape::API)
        base_instance.define_singleton_method(:configuration) { {} }

        remountable_class.instance_variable_set(:@base_instance, base_instance)
        base_instance.constants.each do |constant_name|
          remountable_class.const_set(constant_name, base_instance.const_get(constant_name))
        end
      end

      # The remountable class can have a configuration hash to provide some dynamic class-level variables.
      # For instance, a descripcion could be done using: `desc configuration[:description]` if it may vary
      # depending on where the endpoint is mounted. Use with care, if you find yourself using configuration
      # too much, you may actually want to provide a new API rather than remount it.
      def new_instance(configuration: {})
        instance = Class.new(Grape::API)
        instance.instance_variable_set(:@configuration, configuration)
        instance.define_singleton_method(:configuration) { @configuration }
        replay_setup_on(instance)
        @instances << instance
        instance
      end

      # Replays the set up to produce an API as defined in this class, can be called
      # on classes that inherit from Grape::API
      def replay_setup_on(instance)
        @setup.each do |setup_stage|
          instance.send(setup_stage[:method], *setup_stage[:args], &setup_stage[:block])
        end
      end

      private

      # Adds a new stage to the set up require to get a Grape::API up and running
      def add_setup(method, *args, &block)
        setup_stage = { method: method, args: args, block: block }
        @setup << setup_stage
        @base_instance.send(setup_stage[:method], *setup_stage[:args], &setup_stage[:block])
      end

      def method_missing(method, *args, &block)
        if respond_to_missing?(method, true)
          add_setup(method, *args, &block)
        else
          super
        end
      end

      def respond_to_missing?(name, include_private = false)
        @base_instance.respond_to?(name, include_private)
      end
    end
  end
end
