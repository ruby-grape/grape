require 'grape/router'
require 'grape/api/instance'

module Grape
  # The API class is the primary entry point for creating Grape APIs. Users
  # should subclass this class in order to build an API.
  class API
    # Class methods that we want to call on the API rather than on the API object
    NON_OVERRIDABLE = Class.new.methods.freeze + %i[call call!]

    class << self
      attr_accessor :base_instance, :instances

      # Rather than initializing an object of type Grape::API, create an object of type Instance
      def new(*args, &block)
        base_instance.new(*args, &block)
      end

      # When inherited, will create a list of all instances (times the API was mounted)
      # It will listen to the setup required to mount that endpoint, and replicate it on any new instance
      def inherited(api, base_instance_parent = Grape::API::Instance)
        api.initial_setup(base_instance_parent)
        api.override_all_methods!
        make_inheritable(api)
      end

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
        (base_instance.methods - NON_OVERRIDABLE).each do |method_override|
          define_singleton_method(method_override) do |*args, &block|
            add_setup(method_override, *args, &block)
          end
        end
      end

      # This is the interface point between Rack and Grape; it accepts a request
      # from Rack and ultimately returns an array of three values: the status,
      # the headers, and the body. See [the rack specification]
      # (http://www.rubydoc.info/github/rack/rack/master/file/SPEC) for more.
      # NOTE: This will only be called on an API directly mounted on RACK
      def call(*args, &block)
        base_instance.call(*args, &block)
      end

      # Allows an API to itself be inheritable:
      def make_inheritable(api)
        # When a child API inherits from a parent API.
        def api.inherited(child_api)
          # The instances of the child API inherit from the instances of the parent API
          Grape::API.inherited(child_api, base_instance)
        end
      end

      # Alleviates problems with autoloading by tring to search for the constant
      def const_missing(*args)
        if base_instance.const_defined?(*args)
          base_instance.const_get(*args)
        elsif parent && parent.const_defined?(*args)
          parent.const_get(*args)
        else
          super
        end
      end

      # The remountable class can have a configuration hash to provide some dynamic class-level variables.
      # For instance, a descripcion could be done using: `desc configuration[:description]` if it may vary
      # depending on where the endpoint is mounted. Use with care, if you find yourself using configuration
      # too much, you may actually want to provide a new API rather than remount it.
      def mount_instance(opts = {})
        instance = Class.new(@base_parent)
        instance.configuration = opts[:configuration] || {}
        instance.base = self
        replay_setup_on(instance)
        instance
      end

      # Replays the set up to produce an API as defined in this class, can be called
      # on classes that inherit from Grape::API
      def replay_setup_on(instance)
        @setup.each do |setup_stage|
          instance.send(setup_stage[:method], *setup_stage[:args], &setup_stage[:block])
        end
      end

      def respond_to?(method, include_private = false)
        super(method, include_private) || base_instance.respond_to?(method, include_private)
      end

      def respond_to_missing?(method, include_private = false)
        base_instance.respond_to?(method, include_private)
      end

      def method_missing(method, *args, &block)
        # If there's a missing method, it may be defined on the base_instance instead.
        if respond_to_missing?(method)
          base_instance.send(method, *args, &block)
        else
          super
        end
      end

      private

      # Adds a new stage to the set up require to get a Grape::API up and running
      def add_setup(method, *args, &block)
        setup_stage = { method: method, args: args, block: block }
        @setup << setup_stage
        last_response = nil
        @instances.each do |instance|
          last_response = instance.send(setup_stage[:method], *setup_stage[:args], &setup_stage[:block])
        end
        last_response
      end
    end
  end
end
