# frozen_string_literal: true

module Grape
  module DSL
    module Entity
      # Allows you to make use of Grape Entities by setting
      # the response body to the serializable hash of the
      # entity provided in the `:with` option. This has the
      # added benefit of automatically passing along environment
      # and version information to the serialization, making it
      # very easy to do conditional exposures. See Entity docs
      # for more info.
      #
      # @param args [Array] either `(object)` or `(key, object)` where key is a Symbol
      #   used to nest the representation under that key in the response body.
      # @param root [Symbol, String, nil] wraps the representation under this root key.
      # @param with [Class, nil] the entity class to use for representation.
      #   If omitted, the entity class is inferred from the object via {#entity_class_for_obj}.
      # @param options [Hash] additional options forwarded to the entity's `represent` call.
      #
      # @example
      #
      #   get '/users/:id' do
      #     present User.find(params[:id]),
      #       with: API::Entities::User,
      #       admin: current_user.admin?
      #   end
      def present(*args, root: nil, with: nil, **options)
        key, object = args.count == 2 && args.first.is_a?(Symbol) ? args : [nil, args.first]
        entity_class = with || entity_class_for_obj(object)
        representation = entity_class ? entity_representation_for(entity_class, object, options) : object
        representation = { root => representation } if root

        if key
          representation = body&.merge(key => representation) || { key => representation }
        elsif entity_class.present? && body
          raise ArgumentError, "Representation of type #{representation.class} cannot be merged." unless representation.respond_to?(:merge)

          representation = body.merge(representation)
        end

        body representation
      end

      # Attempt to locate the Entity class for a given object, if not given
      # explicitly. This is done by looking for the presence of Klass::Entity,
      # where Klass is the class of the `object` parameter, or one of its
      # ancestors. Object is excluded from the search: top-level constants
      # live on it, so a global ::Entity class is not a representer.
      # @param object [Object] the object to locate the Entity class for
      # @return [Class] the located Entity class, or nil if none is found
      def entity_class_for_obj(object)
        entity_for_class(object.class) || entity_for_class(element_class(object))
      end

      private

      # The class standing in for a collection or wrapper: ActiveRecord::Relation
      # and the like expose #klass, anything else falls back to the class of its
      # first element.
      #
      # Consulted only once the object's own class has come up empty, because
      # both tests are duck-typed and plenty of single objects answer them —
      # a Struct is Enumerable, so it responds to #first, and so does any model
      # that includes Enumerable. Asking this first meant `represent Model,
      # with: Entity` was silently ignored for those, the entity for the
      # *element* type being looked up instead. Deferring it also keeps #first
      # from being called at all when the object resolves on its own class.
      #
      # @param object [Object] the object to represent.
      # @return [Class, nil]
      def element_class(object)
        return object.klass if object.respond_to?(:klass)

        object.first.class if object.respond_to?(:first)
      end

      # @param klass [Class, nil] the class to look an entity up for.
      # @return [Class, nil] the registered or conventionally named entity.
      def entity_for_class(klass)
        return if klass.nil?

        representations = inheritable_setting.representations
        if representations
          potential = klass.ancestors.detect { |ancestor| representations.key?(ancestor) }
          return representations[potential] if potential && representations[potential]
        end

        owner = klass.ancestors.detect { |ancestor| ancestor != Object && ancestor.const_defined?(:Entity, false) }
        return unless owner

        entity = owner.const_get(:Entity, false)
        entity if entity.respond_to?(:represent)
      end

      # @param entity_class [Class] the entity class to use for representation.
      # @param object [Object] the object to represent.
      # @param options [Hash] additional options forwarded to the entity's `represent` call.
      # @return the representation of the given object as done through the given entity_class.
      def entity_representation_for(entity_class, object, options)
        embeds = env.key?(Grape::Env::API_VERSION) ? { env:, version: env[Grape::Env::API_VERSION] } : { env: }
        entity_class.represent(object, **embeds, **options)
      end
    end
  end
end
