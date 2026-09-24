# frozen_string_literal: true

module Grape
  # The API class is the primary entry point for creating Grape APIs. Users
  # should subclass this class in order to build an API.
  class API
    # Marks this and every subclass as a mountable Grape app (see Grape::Mountable).
    extend Grape::Mountable

    # Class methods that we want to call on the API rather than on the API object.
    # +inherit_settings+ is protected on the base instance, and +.methods+ answers
    # protected methods too, so it has to be named here for {.override_all_methods!}
    # to leave it alone. +base+ is read on the API class itself whenever a mount
    # is refreshed, so recording it would refresh every mount below it again.
    NON_OVERRIDABLE = %i[base base= base_instance? call change! configuration compile! inherit_settings recognize_path reset! routes top_level_setting].freeze

    # DSL methods that answer a setting when called with nothing to set -- no
    # argument, keyword or block -- and change none. Such a call is a read, and
    # is answered without being recorded: as a setup step it was replayed on
    # every mount and, like any step, refreshed every mount made before it,
    # which discards the compiled API, so a read after boot made the next
    # request recompile it. +helpers+ is left out: called bare it includes the
    # helpers in scope and calls +change!+ itself.
    SETTING_READERS = %i[
      auth cascade content_types default_error_formatter default_error_status default_format endpoints format
      group inheritable_setting logger middleware namespace prefix resource resources segment version versions
    ].freeze

    Helpers = Grape::DSL::Helpers::BaseHelper

    Boolean = Class.new

    class << self
      extend Forwardable

      attr_accessor :base_instance, :instances

      delegate_missing_to :base_instance

      # Every NON_OVERRIDABLE name the base instance answers is forwarded here
      # rather than left to +delegate_missing_to+, which stays for the names
      # this list cannot know: anything defined on Grape::API::Instance after
      # an API class was created, since {.override_all_methods!} copies the
      # methods it finds at that moment.
      #
      # +inherit_settings+ is left out: it is protected on the base instance, so
      # a delegator would raise NoMethodError just as the missing one does.
      # +call+ is written out below.
      def_delegators :base_instance, :new, :configuration, :change!, :compile!, :recognize_path, :routes,
                     :base, :base=, :base_instance?, :reset!, :top_level_setting

      # The interface point between Rack and Grape; it accepts a request from
      # Rack and ultimately returns an array of three values: the status, the
      # headers, and the body. See [the rack specification]
      # (https://github.com/rack/rack/blob/main/SPEC.rdoc) for more.
      # NOTE: This will only be called on an API directly mounted on RACK
      #
      # Not delegated with the rest because it runs on every request, and a
      # Forwardable delegator checks its target with +defined?+ and forwards
      # through +...+ each time: about as much again as the call it makes.
      def call(env)
        base_instance.call(env)
      end

      # Initialize the instance variables on the remountable class, and the base_instance
      # an instance that will be used to create the set up but will not be mounted
      def initial_setup(base_instance_parent)
        @instances = []
        @setup = []
        @base_parent = base_instance_parent
        @base_instance = mount_instance
      end

      # Redefines all methods so that are forwarded to add_setup and be recorded.
      # A read (see SETTING_READERS) is answered by the last instance, which is
      # where add_setup takes its answer from, without being recorded.
      def override_all_methods!
        (base_instance.methods - Class.methods - NON_OVERRIDABLE).each do |method_override|
          define_singleton_method(method_override) do |*args, **kwargs, &block|
            step = { method: method_override, args:, kwargs:, block: }
            return replay_step_on(@instances.last, **step) if setting_read?(method_override, args, kwargs, block)

            add_setup(**step)
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
        return config unless block_given?

        yield config
        self
      end

      # The remountable class can have a configuration hash to provide some dynamic class-level variables.
      # For instance, a description could be done using: `desc configuration[:description]` if it may vary
      # depending on where the endpoint is mounted. Use with care, if you find yourself using configuration
      # too much, you may actually want to provide a new API rather than remount it.
      def mount_instance(configuration: nil)
        instance = Class.new(@base_parent)
        instance.configuration = Grape::Util::EndpointConfiguration.new(configuration || {})
        instance.base = self
        replay_setup_on(instance)
        instance
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

        return response if skip_immediate_run?(instance, [response], kwargs)

        evaluate_arguments(instance.configuration, response).first
      end

      def setting_read?(method, args, kwargs, block)
        SETTING_READERS.include?(method) && args.empty? && kwargs.empty? && block.nil?
      end

      # Skips steps that contain arguments to be lazily executed (on re-mount time)
      def skip_immediate_run?(instance, args, kwargs)
        instance.base_instance? &&
          (any_lazy?(args) || args.any? { |arg| arg.is_a?(Hash) && any_lazy?(arg.values) } || any_lazy?(kwargs.values))
      end

      def any_lazy?(args)
        args.any?(Grape::Util::Lazy::Base)
      end

      def evaluate_arguments(configuration, *args)
        args.map do |argument|
          case argument
          when Grape::Util::Lazy::Base
            argument.evaluate_from(configuration)
          when Hash
            argument.transform_values { |value| evaluate_arguments(configuration, value).first }
          when Array
            evaluate_arguments(configuration, *argument)
          else
            argument
          end
        end
      end
    end
  end
end
