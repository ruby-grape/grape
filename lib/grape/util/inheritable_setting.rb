# frozen_string_literal: true

module Grape
  module Util
    # The per-scope settings registry behind the Grape DSL. The semantic
    # accessors below — grouped by concern — are the supported API: +add_*+
    # writers stack one registration per call (read back outermost scope
    # first), plain +=+ writers are nearest-wins scalar overrides, and
    # +!+/+?+ pairs are scope flags. Deep-merged readers return nil when
    # nothing is registered; plain stack readers return a frozen empty
    # Array. The backing stores — a per-scope Hash per kind of state, each
    # holding only what that scope itself set — and their keys are internal.
    #
    # Settings instances form a chain: a scope inherits its parent's values
    # (see #inherit_from), and endpoints snapshot the chain with
    # #point_in_time_copy_for_endpoint. Nothing is copied down the chain when
    # a scope is created; every reader resolves against #parent on demand, so
    # a value an enclosing scope gains later is visible through scopes already
    # nested inside it.
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

      # Shared empty result for #stacked / #stacked_keys when nothing is
      # registered anywhere in the chain, so neither hands out a mutable Array.
      EMPTY_STACK = [].freeze

      attr_reader :route, :namespace, :parent

      # A StackableValues view of this scope's registrations, rebuilt on each
      # call. Public for ecosystem compatibility only — grape-swagger reads it
      # directly and walks its inherited_values chain — and read-only: it is a
      # view, not the store, so writing to it registers nothing. Every
      # semantic key has a dedicated accessor below; new code should use those.
      def namespace_stackable
        StackableValues.new(@stackable_values, parent&.namespace_stackable || {})
      end

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
        # Namespace settings are scope-local by design: nothing ever layers
        # them over a parent's (see #inherit_from, and the nesting behaviour
        # DSL::Settings#namespace_setting is specified to have), so a plain
        # Hash is the whole store.
        @namespace = {}
        # This scope's own inheritable overrides. Like @stackable_values it
        # stays nil until the first write, and inheritance is resolved by
        # walking #parent (see #inheritable) rather than by keeping a second
        # chain of stores alongside it.
        @namespace_inheritable = nil
        # This scope's own stackable registrations, one Array per key. Stays
        # nil until the first registration so scopes that only inherit don't
        # each carry an empty Hash.
        @stackable_values = nil
        @parent = nil
        @point_in_time_copies = nil
      end

      # Return the class-level global properties.
      def global
        self.class.global
      end

      # Inherit from the given parent: its values resolve behind ours from now
      # on, including any it gains later. Also re-parents any settings
      # instances which were forked from us.
      # @param parent [InheritableSetting]
      def inherit_from(parent)
        return if parent.nil?

        @parent = parent

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
        copy.route_declared_params = copy.declared_params.flatten
        copy.route_validations = copy.validations.dup
        copy.default_error_status ||= 500
        copy
      end

      # Resets the instance store of per-route settings.
      # @api private
      def route_end
        @route = {}
      end

      # Validator instances and declared-params entries for the route currently
      # being built. Unlike the same-named namespace stacks (#validations /
      # #declared_params), these are flat per-route snapshots: seeded when an
      # endpoint copy is forked (see #point_in_time_copy_for_endpoint), topped
      # up from mounting parents (see Endpoint#inherit_settings), and read back
      # by run_validators / #declared.
      def route_validations
        @route[:validations]
      end

      def route_validations=(validations)
        @route[:validations] = validations
      end

      def route_declared_params
        @route[:declared_params]
      end

      def route_declared_params=(declared_params)
        @route[:declared_params] = declared_params
      end

      # Path => renamed-name map recorded by +as:+ (see ParamsScope), consumed
      # by #declared. Record entries with #add_route_renamed_param; an empty
      # Hash when nothing was renamed.
      def route_renamed_params
        @route[:renamed_params] || {}
      end

      def add_route_renamed_param(path, new_name)
        (@route[:renamed_params] ||= {})[path] = new_name
      end

      # Endpoint description recorded by +desc+ (see DSL::Desc), consumed by
      # +route+. An empty Hash when +desc+ was never called.
      def route_description
        @route[:description] || {}
      end

      def route_description=(description)
        @route[:description] = description
      end

      # The route-scope settings handed to each Grape::Router::Route: every
      # +route_setting+ registration plus the description, minus the internal
      # param snapshots (#route_validations / #route_declared_params).
      def route_settings
        route.except(:declared_params, :validations)
      end

      # Read (when +value+ is nil) or write an arbitrary route-scoped setting.
      # This is the open store behind the +route_setting+ DSL; the known keys
      # have the dedicated accessors above.
      def route_setting(key, value = nil)
        return @route[key] if value.nil?

        @route[key] = value
      end

      # Fold a mounting parent scope's accumulated validations and declared
      # params into this endpoint copy's per-route snapshots (see
      # Endpoint#inherit_settings). Both are appended, so the parent's entries
      # follow the ones already seeded from the surrounding scopes.
      def inherit_route_params(parent)
        parent_validations = parent.validations
        route_validations.concat(parent_validations) if parent_validations.any?

        parent_declared_params = parent.declared_params
        route_declared_params.concat(parent_declared_params.flatten) if parent_declared_params.any?
      end

      # Return a serializable hash of our values.
      def to_hash
        {
          global: global.clone,
          route: route.clone,
          namespace: namespace.dup,
          namespace_inheritable: inheritable_values,
          namespace_stackable: stacked_keys.to_h { |key| [key, stacked(key)] },
          rescue_handlers:,
          base_only_rescue_handlers:
        }
      end

      def ==(other)
        return true if equal?(other)
        return false unless other.is_a?(self.class)

        # Endpoint copies are siblings of the scope they were forked from, not
        # children of it (see #point_in_time_copy), so every endpoint of an API
        # hangs off the same parent object — which is the case the duplicate
        # check in DSL::Routing#route runs on. Both sides then inherit the same
        # values, so comparing own state decides it without serializing either
        # chain; #global is class-level and identical for both either way.
        # Stacks concatenate and #stack never records an empty one, so matching
        # own stacks means matching resolved ones; the rescue handler maps
        # merge, where a scope can restate an inherited mapping, so those are
        # compared resolved.
        return to_hash == other.to_hash unless parent.equal?(other.parent)

        same_own_store?(@stackable_values, other.stackable_values) &&
          route == other.route &&
          @namespace_inheritable == other.namespace_inheritable &&
          namespace == other.namespace &&
          rescue_handlers == other.rescue_handlers &&
          base_only_rescue_handlers == other.base_only_rescue_handlers
      end
      alias eql? ==

      # Validator instances registered by +params+ and +contract+ blocks,
      # outermost scope first. Record them with #add_validation; the backing
      # store is an internal detail.
      def validations
        stacked(:validations)
      end

      def add_validation(validator)
        stack(:validations, validator)
      end

      # Declared-params entries registered by +params+ blocks, one Array per
      # scope, outermost scope first. Record them with #add_declared_params;
      # the backing store is an internal detail.
      def declared_params
        stacked(:declared_params)
      end

      def add_declared_params(params)
        stack(:declared_params, params)
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
        stack(:params, documented_attrs)
      end

      # Drops this scope's own validations, declared params and params
      # documentation once an endpoint has consumed them (see
      # +reset_validations!+ in DSL::Validations). Inherited entries are kept.
      def reset_validations!
        unstack(:declared_params, :params, :validations)
      end

      # Reusable +params :name do ... end+ blocks defined in helpers, as one
      # name => block Hash per scope, deep-merged on read; nil when none are
      # defined. Consumed by +use+. Record entries with #add_named_params;
      # the backing store is an internal detail.
      def named_params
        namespace_stackable_with_hash(:named_params)
      end

      def add_named_params(named_params)
        stack(:named_params, named_params)
      end

      # Filter blocks registered by the callbacks DSL (see DSL::Callbacks),
      # as a callback-name => blocks Array Hash keyed by the DSL method names
      # (+:before+, +:before_validation+, +:after_validation+, +:after+,
      # +:finally+), outermost scope first. Record them with #add_callback;
      # the backing store is an internal detail.
      def callbacks
        CALLBACK_STORE_KEYS.transform_values { |store_key| stacked(store_key) }
      end

      def add_callback(callback_name, block)
        stack(CALLBACK_STORE_KEYS.fetch(callback_name), block)
      end

      # Response-shaping options recorded by +rescue_from+ (see
      # DSL::RescueOptions): every +rescue_from+ stacks one entry and the
      # nearest scope's latest registration wins on read; nil when
      # +rescue_from+ was never called. Record them with #add_rescue_options;
      # the backing store is an internal detail.
      def rescue_options
        stacked(:rescue_options).last
      end

      def add_rescue_options(options)
        stack(:rescue_options, options)
      end

      # Meta-selector registrations from +rescue_from :all+,
      # +:grape_exceptions+ and +:internal_grape_exceptions+ (see
      # DSL::RequestResponse#rescue_from): each records its handler (nil to
      # use the built-in one) and flips the flags the error middleware reads
      # through #rescue_all? / #rescue_grape_exceptions?; the backing store
      # is an internal detail.
      def add_all_rescue_handler(handler)
        set_inheritable(:rescue_all, true)
        set_inheritable(:all_rescue_handler, handler)
      end

      def add_grape_exceptions_rescue_handler(handler)
        set_inheritable(:rescue_all, true)
        set_inheritable(:rescue_grape_exceptions, true)
        set_inheritable(:grape_exceptions_rescue_handler, handler)
      end

      def add_internal_grape_exceptions_rescue_handler(handler)
        set_inheritable(:internal_grape_exceptions_rescue_handler, handler)
      end

      def rescue_all?
        inheritable(:rescue_all) == true
      end

      def rescue_grape_exceptions?
        inheritable(:rescue_grape_exceptions) == true
      end

      def all_rescue_handler
        inheritable(:all_rescue_handler)
      end

      def grape_exceptions_rescue_handler
        inheritable(:grape_exceptions_rescue_handler)
      end

      def internal_grape_exceptions_rescue_handler
        inheritable(:internal_grape_exceptions_rescue_handler)
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
        stack(:content_types, { format => content_type })
      end

      def formatters
        namespace_stackable_with_hash(:formatters)
      end

      def add_formatter(content_type, formatter)
        stack(:formatters, { content_type => formatter })
      end

      def parsers
        namespace_stackable_with_hash(:parsers)
      end

      def add_parser(content_type, parser)
        stack(:parsers, { content_type => parser })
      end

      def error_formatters
        namespace_stackable_with_hash(:error_formatters)
      end

      def add_error_formatter(format, formatter)
        stack(:error_formatters, { format => formatter })
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
        stack(:representations, { model_class => entity_class })
      end

      # Middleware specs recorded by the middleware DSL (+use+, +insert+,
      # +insert_before+, +insert_after+; see DSL::Middleware), one
      # [operation, *arguments] Array per registration, outermost scope
      # first. Record them with #add_middleware; the backing store is an
      # internal detail.
      def middleware
        stacked(:middleware)
      end

      def add_middleware(operation_with_arguments)
        stack(:middleware, operation_with_arguments)
      end

      # Helper modules registered by +helpers+ blocks and modules (see
      # DSL::Helpers), outermost scope first. Record them with #add_helper;
      # the backing store is an internal detail.
      def helpers
        stacked(:helpers)
      end

      def add_helper(mod)
        stack(:helpers, mod)
      end

      # Grape::Namespace objects registered by the +namespace+ DSL and its
      # aliases (group, resource, resources, segment; see DSL::Routing),
      # outermost scope first. Not to be confused with the #namespace values
      # store. Record them with #add_namespace; the backing store is an
      # internal detail.
      def namespaces
        stacked(:namespace)
      end

      def add_namespace(namespace)
        stack(:namespace, namespace)
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
        stacked(:mount_path).first
      end

      def add_mount_path(mount_path)
        stack(:mount_path, mount_path)
      end

      # The full mount-path stack — one entry per mount level, outermost
      # first; what Router::Pattern::Path joins into a route's origin (see
      # #path_settings).
      def mount_paths
        stacked(:mount_path)
      end

      # Dry::Schema key maps registered by +contract+ blocks (see
      # Validations::ContractScope), one per contract, outermost scope first;
      # +declared+ uses them to write coerced params back under their
      # declared keys. Record them with #add_contract_key_map; the backing
      # store is an internal detail.
      def contract_key_maps
        stacked(:contract_key_map)
      end

      def add_contract_key_map(key_map)
        stack(:contract_key_map, key_map)
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
        inheritable(:format)
      end

      def format=(format)
        set_inheritable(:format, format)
      end

      def default_format
        inheritable(:default_format)
      end

      def default_format=(default_format)
        set_inheritable(:default_format, default_format)
      end

      def default_error_formatter
        inheritable(:default_error_formatter)
      end

      def default_error_formatter=(formatter)
        set_inheritable(:default_error_formatter, formatter)
      end

      def default_error_status
        inheritable(:default_error_status)
      end

      def default_error_status=(status)
        set_inheritable(:default_error_status, status)
      end

      # Versioning state recorded by the routing DSL (see DSL::Routing):
      # +version+ holds the Array of version strings registered by the
      # +version+ DSL method, +version_options+ its DSL::VersionOptions
      # value object, and +root_prefix+ the path prefix set by +prefix+.
      # Nearest-wins scalars with plain += writers; readers return nil when
      # never set; the backing store is an internal detail.
      def version
        inheritable(:version)
      end

      def version=(versions)
        set_inheritable(:version, versions)
      end

      def version_options
        inheritable(:version_options)
      end

      def version_options=(options)
        set_inheritable(:version_options, options)
      end

      def root_prefix
        inheritable(:root_prefix)
      end

      def root_prefix=(prefix)
        set_inheritable(:root_prefix, prefix)
      end

      # Cascade flag assigned by the +cascade+ DSL. An explicit nil is
      # meaningful and distinct from never-set (the backing store is
      # key-presence based), so #cascade_defined? reports whether any scope
      # assigned it — Grape::API::Instance#cascade? falls back to the
      # version options' cascade, then to true, when it was never assigned.
      def cascade
        inheritable(:cascade)
      end

      def cascade=(value)
        set_inheritable(:cascade, value)
      end

      def cascade_defined?
        inheritable?(:cascade)
      end

      # Scope flags flipped by the routing DSL's bang methods (see
      # DSL::Routing#do_not_route_head! and friends; Validations::OneofCollector
      # also flips +do_not_document!+): once set in a scope they apply to it
      # and everything nested under it. Readers return false when never set;
      # the backing store is an internal detail.
      def do_not_route_head!
        set_inheritable(:do_not_route_head, true)
      end

      def do_not_route_head?
        inheritable(:do_not_route_head) == true
      end

      def do_not_route_options!
        set_inheritable(:do_not_route_options, true)
      end

      def do_not_route_options?
        inheritable(:do_not_route_options) == true
      end

      def do_not_document!
        set_inheritable(:do_not_document, true)
      end

      def do_not_document?
        inheritable(:do_not_document) == true
      end

      def lint!
        set_inheritable(:lint, true)
      end

      def lint?
        inheritable(:lint) == true
      end

      # The params-builder strategy set by +build_with+ (both the
      # API-level DSL::Routing#build_with and the params-block
      # DSL::Parameters#build_with write it), consumed when the endpoint
      # builds its Grape::Request. Nearest-wins scalar; nil when never set;
      # the backing store is an internal detail.
      def build_params_with
        inheritable(:build_params_with)
      end

      def build_params_with=(strategy)
        set_inheritable(:build_params_with, strategy)
      end

      # The authentication configuration Hash recorded by the +auth+ DSL
      # (see Middleware::Auth::DSL): {type:, proc:, **options}. Nearest-wins
      # scalar; nil when no authenticator is declared — Endpoint uses that
      # to warn about unauthenticated bare Rack mounts; the backing store is
      # an internal detail.
      def auth
        inheritable(:auth)
      end

      def auth=(auth_options)
        set_inheritable(:auth, auth_options)
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
          content_types: stacked(:content_types).presence,
          version:,
          version_options:
        )
      end

      protected

      # This scope's own inheritable overrides, before inheritance; nil when
      # the scope overrode nothing. Peer access for #copy_state_from.
      attr_reader :namespace_inheritable

      # The nearest scope's value for +key+: this scope's own override when it
      # has one, otherwise the enclosing scope's. Keyed on presence rather than
      # truthiness, so a scope can deliberately override an inherited value
      # with nil (see #cascade).
      def inheritable(key)
        return @namespace_inheritable[key] if @namespace_inheritable&.key?(key)

        parent&.inheritable(key)
      end

      # Whether any scope along the chain assigned +key+ — including one that
      # assigned nil, which #inheritable cannot distinguish from never-set.
      def inheritable?(key)
        return true if @namespace_inheritable&.key?(key)

        parent&.inheritable?(key) || false
      end

      # Every inheritable value along the chain resolved into one Hash, nearest
      # scope winning. Like #stacked it hands back the backing Hash when only
      # one scope in the chain has values, so callers must treat the result as
      # read-only.
      def inheritable_values
        inherited = parent&.inheritable_values
        own = @namespace_inheritable
        return own || {} unless inherited

        own ? inherited.merge(own) : inherited
      end

      # This scope's own +rescue_from+ registrations, before inheritance:
      # {rescue_handlers: {klass => handler}, base_only_rescue_handlers: {...}}.
      attr_reader :rescue_handler_maps

      # This scope's own stackable registrations, before inheritance; nil when
      # the scope registered nothing. Peer access for #copy_state_from.
      attr_reader :stackable_values

      # Every registration for +key+ along the chain, outermost scope first.
      # Returns the frozen EMPTY_STACK when nothing is registered anywhere, and
      # — like the store it replaced — the backing Array itself when only this
      # scope registered anything, so callers must treat the result as
      # read-only.
      def stacked(key)
        inherited = parent&.stacked(key)
        own = @stackable_values&.[](key)
        return own || EMPTY_STACK unless inherited

        own ? inherited + own : inherited
      end

      # Every key registered along the chain, outermost scope's keys first.
      def stacked_keys
        inherited = parent&.stacked_keys || EMPTY_STACK
        return inherited if @stackable_values.blank?

        (inherited + @stackable_values.keys).uniq
      end

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
        @namespace = source.namespace.dup
        @namespace_inheritable = source.namespace_inheritable&.dup
        # Shallow, matching the store this replaced: the per-key Arrays stay
        # shared with the source, so a registration made on the source after
        # the copy was taken is still visible through it.
        @stackable_values = source.stackable_values&.dup
        @rescue_handler_maps = source.rescue_handler_maps&.dup
        @route = source.route.clone
      end

      private

      # Overrides +key+ for this scope, leaving the enclosing scopes' value
      # untouched. The store is allocated on first use. Returns the assigned
      # value, since the writers built on it are +=+ methods.
      def set_inheritable(key, value)
        (@namespace_inheritable ||= {})[key] = value
      end

      # Appends one registration for +key+ to this scope, leaving inherited
      # ones untouched. The store is allocated on first use. Returns the
      # registered value, since this replaced an assignment expression and the
      # +add_*+ writers built on it inherited that return value.
      def stack(key, value)
        ((@stackable_values ||= {})[key] ||= []) << value
        value
      end

      # Drops this scope's own registrations for +keys+; inherited ones are
      # kept, since they belong to the enclosing scopes.
      def unstack(*keys)
        return if @stackable_values.nil?

        keys.each { |key| @stackable_values.delete(key) }
      end

      # Compares two lazily-allocated own-registration stores (see #stack and
      # #add_rescue_handlers): nil and an emptied Hash both mean "this scope
      # registered nothing", so #== must not tell them apart.
      def same_own_store?(mine, theirs)
        return theirs.blank? if mine.blank?

        mine == theirs
      end

      # Deep-merges a stackable key's registrations into one Hash, nearest
      # scope winning; nil when nothing is registered.
      def namespace_stackable_with_hash(key)
        data = stacked(key)
        return if data.blank?

        data.each_with_object({}) { |value, result| result.deep_merge!(value) }
      end
    end
  end
end
