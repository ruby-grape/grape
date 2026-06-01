# frozen_string_literal: true

module Grape
  class Router
    # Grape-style path patterns for Mustermann: `:param`, `*splat`, `{name}` /
    # `{+splat}`, `( )` optionals, `|`, and an Integer digit-only constraint
    # (driven by Grape's `params` option).
    #
    # Inlined from the mustermann-grape gem (MIT) by namusyaka, Konstantin Haase
    # and Daniel Doubrovkine. Grape instantiates this class directly (see
    # {Grape::Router::Pattern}), so unlike the gem it is not registered as a
    # Mustermann `type: :grape`.
    class MustermannPattern < ::Mustermann::AST::Pattern
      supported_options :params

      on(nil, '?', ')') { |c| unexpected(c) }

      on('*') { |_c| scan(/\w+/) ? node(:named_splat, buffer.matched) : node(:splat) }
      on(':') do |_c|
        param_name = scan(/\w+/)
        # Integer params (declared via Grape's `params` option) match digits only;
        # any other capture matches a single path segment (anything but / ? # .).
        param_type = pattern&.options&.dig(:params, param_name, :type)
        constraint = param_type == 'Integer' ? /\d/ : '[^/?#.]'
        node(:capture, param_name, constraint:) { scan(/\w+/) }
      end
      on('\\') { |_c| node(:char, expect(/./)) }
      on('(') { |_c| node(:optional, node(:group) { read unless scan(')') }) }
      on('|') { |_c| node(:or) }

      on('{') do |_c|
        type = scan('+') ? :named_splat : :capture
        name = expect(/[\w.]+/)
        type = :splat if (type == :named_splat) && (name == 'splat')
        expect('}')
        node(type, name)
      end

      suffix('?') do |_c, element|
        node(:optional, element)
      end
    end
  end
end
