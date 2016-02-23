module Grape
  module DSL
    module Desc
      include Grape::DSL::Settings

      # Add a description to the next namespace or function.
      # @param description [String] descriptive string for this endpoint
      #   or namespace
      # @param options [Hash] other properties you can set to describe the
      #   endpoint or namespace. Optional.
      # @option options :detail [String] additional detail about this endpoint
      # @option options :params [Hash] param types and info. normally, you set
      #   these via the `params` dsl method.
      # @option options :entity [Grape::Entity] the entity returned upon a
      #   successful call to this action
      # @option options :http_codes [Array[Array]] possible HTTP codes this
      #   endpoint may return, with their meanings, in a 2d array
      # @option options :named [String] a specific name to help find this route
      # @option options :headers [Hash] HTTP headers this method can accept
      # @yield a block yielding an instance context with methods mapping to
      #   each of the above, except that :entity is also aliased as #success
      #   and :http_codes is aliased as #failure.
      #
      # @example
      #
      #     desc 'create a user'
      #     post '/users' do
      #       # ...
      #     end
      #
      #     desc 'find a user' do
      #       detail 'locates the user from the given user ID'
      #       failure [ [404, 'Couldn\'t find the given user' ] ]
      #       success User::Entity
      #     end
      #     get '/user/:id' do
      #       # ...
      #     end
      #
      def desc(description, options = {}, &config_block)
        if block_given?
          config_class = desc_container

          config_class.configure do
            description description
          end

          config_class.configure(&config_block)
          unless options.empty?
            warn '[DEPRECATION] Passing a options hash and a block to `desc` is deprecated. Move all hash options to block.'
          end
          options = config_class.settings
        else
          options = options.merge(description: description)
        end

        namespace_setting :description, options
        route_setting :description, options
      end

      def description_field(field, value = nil)
        if value
          description = route_setting(:description)
          description ||= route_setting(:description, {})
          description[field] = value
        else
          description = route_setting(:description)
          description[field] if description
        end
      end

      def unset_description_field(field)
        description = route_setting(:description)
        description.delete(field) if description
      end

      # Returns an object which configures itself via an instance-context DSL.
      def desc_container
        Module.new do
          include Grape::Util::StrictHashConfiguration.module(
            :description,
            :detail,
            :params,
            :entity,
            :http_codes,
            :named,
            :headers
          )

          def config_context.success(*args)
            entity(*args)
          end

          def config_context.failure(*args)
            http_codes(*args)
          end
        end
      end
    end
  end
end
