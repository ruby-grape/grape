# frozen_string_literal: true

module Grape
  module Util
    # The per-scope settings registry behind the Grape DSL. The semantic
    # accessors below — grouped by concern — are the supported API: +add_*+
    # writers stack one registration per call (read back outermost scope
    # first), plain +=+ writers are nearest-wins scalar overrides, and
    # +!+/+?+ pairs are scope flags. Deep-merged readers return nil when
    # nothing is registered; plain stack readers return a frozen empty
    # Array. The backing stores (InheritableValues, StackableValues and the
    # per-scope Hashes) and their keys are internal.
    #
    # Settings instances form a chain: a scope inherits its parent's values
    # (see #inherit_from), and endpoints snapshot the chain with
    # #point_in_time_copy_for_endpoint.
    class InheritableSetting
      # Maps the callbacks DSL method names to their pluralized
      # namespace-stackable storage keys (see #callbacks / #add_callback).
      CALLBACK_STORE_KEYS = {
        before: :befores,
        before_validation: :before_validations,
        after_validation: :after_validations,
        after: :afters,
        finally: :finallies
      }.freeze

      attr_reader :route, :namespace, :parent

      # The stackable store. Public for ecosystem compatibility — grape-swagger
      # reads it directly (and walks its inherited_values chain) — but treat it
      # as read-only from the outside: every semantic key has a dedicated
      # accessor below, and new code should use those.
      attr_reader :namespace_stackable

      # Retrieve global settings.
      def self.global
        @global ||= {}
      end

      # Clear all global settings.
      # @api private
      # @note only for testing
      def self.reset_global!
        @global = {}
      end

      # Instantiate a new settings instance, with blank values. The fresh
      # instance can then be set to inherit from an existing instance (see
      # #inherit_from).
      def initialize
        @route = {}
        @namespace = InheritableValues.new # only inheritable from a parent when
        # used with a mount, or should every API::Class be a separate namespace by default?
        @namespace_inheritable = InheritableValues.new
        @namespace_stackable = StackableValues.new
        @parent = nil
        @point_in_time_copies = nil
      end

      # Return the class-level global properties.
      def global
        self.class.global
      end

      # Set our inherited values to the given parent's current values. Also,
      # update the inherited values on any settings instances which were forked
      # from us.
      # @param parent [InheritableSetting]
      def inherit_from(parent)
        return if parent.nil?

        @parent = parent

        @namespace_inheritable.inherited_values = parent.namespace_inheritable
        @namespace_stackable.inherited_values = parent.namespace_stackable
        @route = parent.route.merge(route)

        @point_in_time_copies&.each { |cloned_one| cloned_one.inherit_from parent }
      end

      # Create a point-in-time copy of this settings instance, with clones of
      # all our values. Note that, should this instance's parent be set or
      # changed via #inherit_from, it will copy that inheritence to any copies
      # which were made.
      def point_in_time_copy
        new_setting = self.class.new
        (@point_in_time_copies ||= []) << new_setting
        new_setting.copy_state_from(self)
        new_setting.inherit_from(parent)
        new_setting
      end

      # Fork a point-in-time copy prepared for a freshly-built endpoint: the
      # declared params and validations accumulated by the surrounding scopes
      # are snapshotted into the copy's per-route settings, since the
      # namespace stacks are wiped between routes (see #reset_validations!),
      # and request-serving defaults are applied.
      def point_in_time_copy_for_endpoint
        copy = point_in_time_copy
        copy.route[:declared_params] = copy.declared_params.flatten
        copy.route[:validations] = copy.validations.dup
        copy.default_error_status ||= 500
        copy
      end

      # Resets the instance store of per-route settings.
      # @api private
      def route_end
        @route = {}
      end

      # Return a serializable hash of our values.
      def to_hash
        {
          global: global.clone,
          route: route.clone,
          namespace: namespace.to_hash,
          namespace_inheritable: @namespace_inheritable.to_hash,
          namespace_stackable: @namespace_stackable.to_hash,
          rescue_handlers:,
          base_only_rescue_handlers:
        }
      end

      def ==(other)
        other.is_a?(self.class) && to_hash == other.to_hash
      end
      alias eql? ==

      # Validator instances registered by +params+ and +contract+ blocks,
      # outermost scope first. Record them with #add_validation; the backing
      # store is an internal detail.
      def validations
        @namespace_stackable[:validations]
      end

      def add_validation(validator)
        @namespace_stackable[:validations] = validator
      end

      # Declared-params entries registered by +params+ blocks, one Array per
      # scope, outermost scope first. Record them with #add_declared_params;
      # the backing store is an internal detail.
      def declared_params
        @namespace_stackable[:declared_params]
      end

      def add_declared_params(params)
        @namespace_stackable[:declared_params] = params
      end

      # Param documentation recorded by +params+ blocks (see
      # Validations::ParamsDocumentation) as one attribute-name => details
      # Hash per scope, deep-merged on read; nil when nothing is documented.
      # Record entries with #add_params_documentation; the backing store is
      # an internal detail.
      def params_documentation
        namespace_stackable_with_hash(:params)
      end

      def add_params_documentation(documented_attrs)
        @namespace_stackable[:params] = documented_attrs
      end

      # Drops this scope's own validations, declared params and params
      # documentation once an endpoint has consumed them (see
      # +reset_validations!+ in DSL::Validations). Inherited entries are kept.
      def reset_validations!
        @namespace_stackable.delete(:declared_params, :params, :validations)
      end

      # Reusable +params :name do ... end+ blocks defined in helpers, as one
      # name => block Hash per scope, deep-merged on read; nil when none are
      # defined. Consumed by +use+. Record entries with #add_named_params;
      # the backing store is an internal detail.
      def named_params
        namespace_stackable_with_hash(:named_params)
      end

      def add_named_params(named_params)
        @namespace_stackable[:named_params] = named_params
      end

      # Filter blocks registered by the callbacks DSL (see DSL::Callbacks),
      # as a callback-name => blocks Array Hash keyed by the DSL method names
      # (+:before+, +:before_validation+, +:after_validation+, +:after+,
      # +:finally+), outermost scope first. Record them with #add_callback;
      # the backing store is an internal detail.
      def callbacks
        CALLBACK_STORE_KEYS.transform_values { |store_key| @namespace_stackable[store_key] }
      end

      def add_callback(callback_name, block)
        @namespace_stackable[CALLBACK_STORE_KEYS.fetch(callback_name)] = block
      end

      # Response-shaping options recorded by +rescue_from+ (see
      # DSL::RescueOptions): every +rescue_from+ stacks one entry and the
      # nearest scope's latest registration wins on read; nil when
      # +rescue_from+ was never called. Record them with #add_rescue_options;
      # the backing store is an internal detail.
      def rescue_options
        @namespace_stackable[:rescue_options].last
      end

      def add_rescue_options(options)
        @namespace_stackable[:rescue_options] = options
      end

      # Meta-selector registrations from +rescue_from :all+,
      # +:grape_exceptions+ and +:internal_grape_exceptions+ (see
      # DSL::RequestResponse#rescue_from): each records its handler (nil to
      # use the built-in one) and flips the flags the error middleware reads
      # through #rescue_all? / #rescue_grape_exceptions?; the backing store
      # is an internal detail.
      def add_all_rescue_handler(handler)
        @namespace_inheritable[:rescue_all] = true
        @namespace_inheritable[:all_rescue_handler] = handler
      end

      def add_grape_exceptions_rescue_handler(handler)
        @namespace_inheritable[:rescue_all] = true
        @namespace_inheritable[:rescue_grape_exceptions] = true
        @namespace_inheritable[:grape_exceptions_rescue_handler] = handler
      end

      def add_internal_grape_exceptions_rescue_handler(handler)
        @namespace_inheritable[:internal_grape_exceptions_rescue_handler] = handler
      end

      def rescue_all?
        @namespace_inheritable[:rescue_all] == true
      end

      def rescue_grape_exceptions?
        @namespace_inheritable[:rescue_grape_exceptions] == true
      end

      def all_rescue_handler
        @namespace_inheritable[:all_rescue_handler]
      end

      def grape_exceptions_rescue_handler
        @namespace_inheritable[:grape_exceptions_rescue_handler]
      end

      def internal_grape_exceptions_rescue_handler
        @namespace_inheritable[:internal_grape_exceptions_rescue_handler]
      end

      # Rescue-handler maps registered by +rescue_from+, keyed by exception
      # class and merged so a nested scope's handler wins. Record them with
      # #add_rescue_handlers; the backing store is an internal detail.
      def rescue_handlers
        merged_rescue_handlers(:rescue_handlers)
      end

      def base_only_rescue_handlers
        merged_rescue_handlers(:base_only_rescue_handlers)
      end

      # An exception class registered twice in the same scope keeps its first
      # handler, and keeps the position it was first registered at.
      def add_rescue_handlers(mapping, subclasses:)
        @rescue_handler_maps ||= {}
        own = (@rescue_handler_maps[subclasses ? :rescue_handlers : :base_only_rescue_handlers] ||= {})
        own.merge!(mapping) { |_klass, registered, _new| registered }
      end

      # Content negotiation registries recorded by the request/response DSL
      # (see DSL::RequestResponse): the content-type registry (+content_type+
      # and +format+), and the formatter, parser and error-formatter handler
      # maps. Each registration stacks one single-entry Hash, deep-merged on
      # read so a nested scope's registration wins; readers return nil when
      # nothing is registered. Record entries with the corresponding +add_*+
      # writer; the backing store is an internal detail.
      def content_types
        namespace_stackable_with_hash(:content_types)
      end

      def add_content_type(format, content_type)
        @namespace_stackable[:content_types] = { format => content_type }
      end

      def formatters
        namespace_stackable_with_hash(:formatters)
      end

      def add_formatter(content_type, formatter)
        @namespace_stackable[:formatters] = { content_type => formatter }
      end

      def parsers
        namespace_stackable_with_hash(:parsers)
      end

      def add_parser(content_type, parser)
        @namespace_stackable[:parsers] = { content_type => parser }
      end

      def error_formatters
        namespace_stackable_with_hash(:error_formatters)
      end

      def add_error_formatter(format, formatter)
        @namespace_stackable[:error_formatters] = { format => formatter }
      end

      # Model-class => entity-class registrations from +represent+ (see
      # DSL::RequestResponse), one single-entry Hash per registration,
      # deep-merged on read so a nested scope's registration wins; nil when
      # none are registered. Record them with #add_representation; the
      # backing store is an internal detail.
      def representations
        namespace_stackable_with_hash(:representations)
      end

      def add_representation(model_class, entity_class)
        @namespace_stackable[:representations] = { model_class => entity_class }
      end

      # Middleware specs recorded by the middleware DSL (+use+, +insert+,
      # +insert_before+, +insert_after+; see DSL::Middleware), one
      # [operation, *arguments] Array per registration, outermost scope
      # first. Record them with #add_middleware; the backing store is an
      # internal detail.
      def middleware
        @namespace_stackable[:middleware]
      end

      def add_middleware(operation_with_arguments)
        @namespace_stackable[:middleware] = operation_with_arguments
      end

      # Helper modules registered by +helpers+ blocks and modules (see
      # DSL::Helpers), outermost scope first. Record them with #add_helper;
      # the backing store is an internal detail.
      def helpers
        @namespace_stackable[:helpers]
      end

      def add_helper(mod)
        @namespace_stackable[:helpers] = mod
      end

      # Grape::Namespace objects registered by the +namespace+ DSL and its
      # aliases (group, resource, resources, segment; see DSL::Routing),
      # outermost scope first. Not to be confused with the #namespace values
      # store. Record them with #add_namespace; the backing store is an
      # internal detail.
      def namespaces
        @namespace_stackable[:namespace]
      end

      def add_namespace(namespace)
        @namespace_stackable[:namespace] = namespace
      end

      # The normalized path prefix formed by joining every registered
      # namespace's space (see Grape::Namespace.joined_space_path).
      def namespace_path
        Grape::Namespace.joined_space_path(namespaces)
      end

      # The param requirements declared by registered namespaces, outermost
      # scope first.
      def namespace_requirements
        namespaces.filter_map(&:requirements)
      end

      # The path a Grape API is mounted under, recorded on the mounted API's
      # top-level settings by +mount+ (see DSL::Routing). Reading returns the
      # outermost mount path — nil when the API is not mounted; the backing
      # store is an internal detail.
      def mount_path
        @namespace_stackable[:mount_path].first
      end

      def add_mount_path(mount_path)
        @namespace_stackable[:mount_path] = mount_path
      end

      # The full mount-path stack — one entry per mount level, outermost
      # first; what Router::Pattern::Path joins into a route's origin (see
      # #path_settings).
      def mount_paths
        @namespace_stackable[:mount_path]
      end

      # Dry::Schema key maps registered by +contract+ blocks (see
      # Validations::ContractScope), one per contract, outermost scope first;
      # +declared+ uses them to write coerced params back under their
      # declared keys. Record them with #add_contract_key_map; the backing
      # store is an internal detail.
      def contract_key_maps
        @namespace_stackable[:contract_key_map]
      end

      def add_contract_key_map(key_map)
        @namespace_stackable[:contract_key_map] = key_map
      end

      # Serialization and error-response defaults recorded by the
      # request/response DSL's get-or-set methods (see DSL::RequestResponse):
      # +format+ is the enforced API format, +default_format+ the fallback
      # used when a request doesn't specify one, and
      # +default_error_formatter+ / +default_error_status+ shape error
      # responses. Nearest-wins scalars — a nested scope's assignment
      # overrides an inherited one, hence plain +=+ writers rather than the
      # +add_*+ writers used for stackable registrations. Readers return nil
      # when never set (Endpoint applies the request-serving fallbacks); the
      # backing store is an internal detail.
      def format
        @namespace_inheritable[:format]
      end

      def format=(format)
        @namespace_inheritable[:format] = format
      end

      def default_format
        @namespace_inheritable[:default_format]
      end

      def default_format=(default_format)
        @namespace_inheritable[:default_format] = default_format
      end

      def default_error_formatter
        @namespace_inheritable[:default_error_formatter]
      end

      def default_error_formatter=(formatter)
        @namespace_inheritable[:default_error_formatter] = formatter
      end

      def default_error_status
        @namespace_inheritable[:default_error_status]
      end

      def default_error_status=(status)
        @namespace_inheritable[:default_error_status] = status
      end

      # Versioning state recorded by the routing DSL (see DSL::Routing):
      # +version+ holds the Array of version strings registered by the
      # +version+ DSL method, +version_options+ its DSL::VersionOptions
      # value object, and +root_prefix+ the path prefix set by +prefix+.
      # Nearest-wins scalars with plain += writers; readers return nil when
      # never set; the backing store is an internal detail.
      def version
        @namespace_inheritable[:version]
      end

      def version=(versions)
        @namespace_inheritable[:version] = versions
      end

      def version_options
        @namespace_inheritable[:version_options]
      end

      def version_options=(options)
        @namespace_inheritable[:version_options] = options
      end

      def root_prefix
        @namespace_inheritable[:root_prefix]
      end

      def root_prefix=(prefix)
        @namespace_inheritable[:root_prefix] = prefix
      end

      # Cascade flag assigned by the +cascade+ DSL. An explicit nil is
      # meaningful and distinct from never-set (the backing store is
      # key-presence based), so #cascade_defined? reports whether any scope
      # assigned it — Grape::API::Instance#cascade? falls back to the
      # version options' cascade, then to true, when it was never assigned.
      def cascade
        @namespace_inheritable[:cascade]
      end

      def cascade=(value)
        @namespace_inheritable[:cascade] = value
      end

      def cascade_defined?
        @namespace_inheritable.key?(:cascade)
      end

      # Scope flags flipped by the routing DSL's bang methods (see
      # DSL::Routing#do_not_route_head! and friends; Validations::OneofCollector
      # also flips +do_not_document!+): once set in a scope they apply to it
      # and everything nested under it. Readers return false when never set;
      # the backing store is an internal detail.
      def do_not_route_head!
        @namespace_inheritable[:do_not_route_head] = true
      end

      def do_not_route_head?
        @namespace_inheritable[:do_not_route_head] == true
      end

      def do_not_route_options!
        @namespace_inheritable[:do_not_route_options] = true
      end

      def do_not_route_options?
        @namespace_inheritable[:do_not_route_options] == true
      end

      def do_not_document!
        @namespace_inheritable[:do_not_document] = true
      end

      def do_not_document?
        @namespace_inheritable[:do_not_document] == true
      end

      def lint!
        @namespace_inheritable[:lint] = true
      end

      def lint?
        @namespace_inheritable[:lint] == true
      end

      # The params-builder strategy set by +build_with+ (both the
      # API-level DSL::Routing#build_with and the params-block
      # DSL::Parameters#build_with write it), consumed when the endpoint
      # builds its Grape::Request. Nearest-wins scalar; nil when never set;
      # the backing store is an internal detail.
      def build_params_with
        @namespace_inheritable[:build_params_with]
      end

      def build_params_with=(strategy)
        @namespace_inheritable[:build_params_with] = strategy
      end

      # The authentication configuration Hash recorded by the +auth+ DSL
      # (see Middleware::Auth::DSL): {type:, proc:, **options}. Nearest-wins
      # scalar; nil when no authenticator is declared — Endpoint uses that
      # to warn about unauthenticated bare Rack mounts; the backing store is
      # an internal detail.
      def auth
        @namespace_inheritable[:auth]
      end

      def auth=(auth_options)
        @namespace_inheritable[:auth] = auth_options
      end

      # Immutable snapshot of the settings Router::Pattern::Path reads to
      # assemble a route's origin and suffix, built by #path_settings, which
      # always supplies every member (nil where unset) — unlike
      # RescueOptions/VersionOptions, PathSettings has no bare-default
      # production caller, so it stays a plain Data with no keyword
      # defaults.
      PathSettings = Data.define(:mount_path, :root_prefix, :format, :content_types, :version, :version_options)

      # Builds a PathSettings snapshot for Router::Pattern::Path (see
      # Endpoint#to_routes). +mount_path+ is the full stack — one entry per
      # mount level, outermost first — unlike #mount_path, which returns
      # only the outermost entry; +content_types+ is the raw registration
      # stack, because Path counts registrations rather than distinct
      # formats. Unset members are nil.
      def path_settings
        PathSettings.new(
          mount_path: mount_paths.presence,
          root_prefix:,
          format:,
          content_types: @namespace_stackable[:content_types].presence,
          version:,
          version_options:
        )
      end

      protected

      # Peer access to the inheritable store for #inherit_from and
      # #copy_state_from; internal code reads the ivar directly.
      attr_reader :namespace_inheritable

      # This scope's own +rescue_from+ registrations, before inheritance:
      # {rescue_handlers: {klass => handler}, base_only_rescue_handlers: {...}}.
      attr_reader :rescue_handler_maps

      # Nearest scope's handlers first: Middleware::Error scans with +find+,
      # so a nested scope's registrations must precede inherited ones even
      # when an outer scope registered a more specific class.
      def merged_rescue_handlers(key)
        inherited = parent&.merged_rescue_handlers(key)
        own = @rescue_handler_maps&.[](key)
        return inherited unless own

        own.merge(inherited || {}) { |_klass, nearer, _inherited| nearer }
      end

      # Used by +point_in_time_copy+ to populate a freshly-built instance
      # with cloned state from another instance of the same class.
      def copy_state_from(source)
        @namespace = source.namespace.clone
        @namespace_inheritable = source.namespace_inheritable.clone
        @namespace_stackable = source.namespace_stackable.clone
        @rescue_handler_maps = source.rescue_handler_maps&.dup
        @route = source.route.clone
      end

      private

      # Deep-merges a stackable key's registrations into one Hash, nearest
      # scope winning; nil when nothing is registered.
      def namespace_stackable_with_hash(key)
        data = @namespace_stackable[key]
        return if data.blank?

        data.each_with_object({}) { |value, result| result.deep_merge!(value) }
      end
    end
  end
end
