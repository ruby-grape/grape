require 'hashie'

module Grape
  # An Entity is a lightweight structure that allows you to easily
  # represent data from your application in a consistent and abstracted
  # way in your API. Entities can also provide documentation for the
  # fields exposed.
  #
  # @example Entity Definition
  #
  #   module API
  #     module Entities
  #       class User < Grape::Entity
  #         expose :first_name, :last_name, :screen_name, :location
  #         expose :field, :documentation => {:type => "string", :desc => "describe the field"}
  #         expose :latest_status, :using => API::Status, :as => :status, :unless => {:collection => true}
  #         expose :email, :if => {:type => :full}
  #         expose :new_attribute, :if => {:version => 'v2'}
  #         expose(:name){|model,options| [model.first_name, model.last_name].join(' ')}
  #       end
  #     end
  #   end
  #
  # Entities are not independent structures, rather, they create
  # **representations** of other Ruby objects using a number of methods
  # that are convenient for use in an API. Once you've defined an Entity,
  # you can use it in your API like this:
  #
  # @example Usage in the API Layer
  #
  #   module API
  #     class Users < Grape::API
  #       version 'v2'
  #
  #       desc 'User index', { :object_fields => API::Entities::User.documentation }
  #       get '/users' do
  #         @users = User.all
  #         type = current_user.admin? ? :full : :default
  #         present @users, :with => API::Entities::User, :type => type
  #       end
  #     end
  #   end
  class Entity
    attr_reader :object, :options

    # This method is the primary means by which you will declare what attributes
    # should be exposed by the entity.
    #
    # @option options :as Declare an alias for the representation of this attribute.
    # @option options :if When passed a Hash, the attribute will only be exposed if the
    #   runtime options match all the conditions passed in. When passed a lambda, the
    #   lambda will execute with two arguments: the object being represented and the
    #   options passed into the representation call. Return true if you want the attribute
    #   to be exposed.
    # @option options :unless When passed a Hash, the attribute will be exposed if the
    #   runtime options fail to match any of the conditions passed in. If passed a lambda,
    #   it will yield the object being represented and the options passed to the
    #   representation call. Return true to prevent exposure, false to allow it.
    # @option options :using This option allows you to map an attribute to another Grape
    #   Entity. Pass it a Grape::Entity class and the attribute in question will
    #   automatically be transformed into a representation that will receive the same
    #   options as the parent entity when called. Note that arrays are fine here and
    #   will automatically be detected and handled appropriately.
    # @option options :proc If you pass a Proc into this option, it will
    #   be used directly to determine the value for that attribute. It
    #   will be called with the represented object as well as the
    #   runtime options that were passed in. You can also just supply a
    #   block to the expose call to achieve the same effect.
    # @option options :documentation Define documenation for an exposed
    #   field, typically the value is a hash with two fields, type and desc.
    def self.expose(*args, &block)
      options = args.last.is_a?(Hash) ? args.pop : {}

      if args.size > 1
        raise ArgumentError, "You may not use the :as option on multi-attribute exposures." if options[:as]
        raise ArgumentError, "You may not use block-setting on multi-attribute exposures." if block_given?
      end

      raise ArgumentError, "You may not use block-setting when also using format_with" if block_given? && options[:format_with].respond_to?(:call)

      options[:proc] = block if block_given?

      args.each do |attribute|
        exposures[attribute.to_sym] = options
      end
    end

    # Returns a hash of exposures that have been declared for this Entity or ancestors. The keys
    # are symbolized references to methods on the containing object, the values are
    # the options that were passed into expose.
    def self.exposures
      @exposures ||= {}

      if superclass.respond_to? :exposures
        @exposures = superclass.exposures.merge(@exposures)
      end

      @exposures
    end

    # Returns a hash, the keys are symbolized references to fields in the entity,
    # the values are document keys in the entity's documentation key. When calling
    # #docmentation, any exposure without a documentation key will be ignored.
    def self.documentation
      @documentation ||= exposures.inject({}) do |memo, value|
                           unless value[1][:documentation].nil? || value[1][:documentation].empty?
                             memo[value[0]] = value[1][:documentation]
                           end
                           memo
                         end

      if superclass.respond_to? :documentation
        @documentation = superclass.documentation.merge(@documentation)
      end

      @documentation
    end

    # This allows you to declare a Proc in which exposures can be formatted with.
    # It take a block with an arity of 1 which is passed as the value of the exposed attribute.
    #
    # @param name [Symbol] the name of the formatter
    # @param block [Proc] the block that will interpret the exposed attribute
    #
    #
    #
    # @example Formatter declaration
    #
    #   module API
    #     module Entities
    #       class User < Grape::Entity
    #         format_with :timestamp do |date|
    #           date.strftime('%m/%d/%Y')
    #         end
    #
    #         expose :birthday, :last_signed_in, :format_with => :timestamp
    #       end
    #     end
    #   end
    #
    # @example Formatters are available to all decendants
    #
    #   Grape::Entity.format_with :timestamp do |date|
    #     date.strftime('%m/%d/%Y')
    #   end
    #
    def self.format_with(name, &block)
      raise ArgumentError, "You must pass a block for formatters" unless block_given?
      formatters[name.to_sym] = block
    end

    # Returns a hash of all formatters that are registered for this and it's ancestors.
    def self.formatters
      @formatters ||= {}

      if superclass.respond_to? :formatters
        @formatters = superclass.formatters.merge(@formatters)
      end

      @formatters
    end

    # This allows you to set a root element name for your representation.
    #
    # @param plural   [String] the root key to use when representing
    #   a collection of objects. If missing or nil, no root key will be used
    #   when representing collections of objects.
    # @param singular [String] the root key to use when representing
    #   a single object. If missing or nil, no root key will be used when
    #   representing an individual object.
    #
    # @example Entity Definition
    #
    #   module API
    #     module Entities
    #       class User < Grape::Entity
    #         root 'users', 'user'
    #         expose :id
    #       end
    #     end
    #   end
    #
    # @example Usage in the API Layer
    #
    #   module API
    #     class Users < Grape::API
    #       version 'v2'
    #
    #       # this will render { "users": [ {"id":"1"}, {"id":"2"} ] }
    #       get '/users' do
    #         @users = User.all
    #         present @users, :with => API::Entities::User
    #       end
    #
    #       # this will render { "user": {"id":"1"} }
    #       get '/users/:id' do
    #         @user = User.find(params[:id])
    #         present @user, :with => API::Entities::User
    #       end
    #     end
    #   end
    def self.root(plural, singular=nil)
      @collection_root = plural
      @root = singular
    end

    # This convenience method allows you to instantiate one or more entities by
    # passing either a singular or collection of objects. Each object will be
    # initialized with the same options. If an array of objects is passed in,
    # an array of entities will be returned. If a single object is passed in,
    # a single entity will be returned.
    #
    # @param objects [Object or Array] One or more objects to be represented.
    # @param options [Hash] Options that will be passed through to each entity
    #   representation.
    #
    # @option options :root [String] override the default root name set for the
    #   entity. Pass nil or false to represent the object or objects with no
    #   root name even if one is defined for the entity.
    def self.represent(objects, options = {})
      inner = if objects.respond_to?(:to_ary)
        objects.to_ary().map{|o| self.new(o, {:collection => true}.merge(options))}
      else
        self.new(objects, options)
      end

      root_element = if options.has_key?(:root)
        options[:root]
      else
        objects.respond_to?(:to_ary) ? @collection_root : @root
      end
      root_element ? { root_element => inner } : inner
    end

    def initialize(object, options = {})
      @object, @options = object, options
    end

    def exposures
      self.class.exposures
    end

    def documentation
      self.class.documentation
    end

    def formatters
      self.class.formatters
    end

    # The serializable hash is the Entity's primary output. It is the transformed
    # hash for the given data model and is used as the basis for serialization to
    # JSON and other formats.
    #
    # @param options [Hash] Any options you pass in here will be known to the entity
    #   representation, this is where you can trigger things from conditional options
    #   etc.
    def serializable_hash(runtime_options = {})
      return nil if object.nil?
      opts = options.merge(runtime_options || {})
      exposures.inject({}) do |output, (attribute, exposure_options)|
        if exposure_options.has_key?(:proc) || object.respond_to?(attribute) && conditions_met?(exposure_options, opts)
          partial_output = value_for(attribute, opts)
          output[key_for(attribute)] =
            if partial_output.respond_to? :serializable_hash
              partial_output.serializable_hash(runtime_options)
            elsif partial_output.kind_of?(Array) && !partial_output.map {|o| o.respond_to? :serializable_hash}.include?(false)
              partial_output.map {|o| o.serializable_hash}
            else
              partial_output
            end
        end
        output
      end
    end

    alias :as_json :serializable_hash

    protected

    def key_for(attribute)
      exposures[attribute.to_sym][:as] || attribute.to_sym
    end

    def value_for(attribute, options = {})
      exposure_options = exposures[attribute.to_sym]

      if exposure_options[:proc]
        exposure_options[:proc].call(object, options)
      elsif exposure_options[:using]
        exposure_options[:using].represent(object.send(attribute), :root => nil)
      elsif exposure_options[:format_with]
        format_with = exposure_options[:format_with]

        if format_with.is_a?(Symbol) && formatters[format_with]
          formatters[format_with].call(object.send(attribute))
        elsif format_with.is_a?(Symbol)
          self.send(format_with, object.send(attribute))
        elsif format_with.respond_to? :call
          format_with.call(object.send(attribute))
        end
      else
        object.send(attribute)
      end
    end

    def conditions_met?(exposure_options, options)
      if_condition = exposure_options[:if]
      unless_condition = exposure_options[:unless]

      case if_condition
        when Hash; if_condition.each_pair{|k,v| return false if options[k.to_sym] != v }
        when Proc; return false unless if_condition.call(object, options)
      end

      case unless_condition
        when Hash; unless_condition.each_pair{|k,v| return false if options[k.to_sym] == v}
        when Proc; return false if unless_condition.call(object, options)
      end

      true
    end
  end
end
