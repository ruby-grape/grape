# frozen_string_literal: true

module Grape
  if defined?(::MultiJSON)
    # Since multi_json 1.21.0, MultiJSON.dump is deprecated in favor of
    # MultiJSON.generate (removed in 2.0). Keep Grape's dump surface but route
    # it to the non-deprecated name — identical output, no deprecation warning.
    # https://github.com/sferik/multi_json/blob/v1.21.1/CHANGELOG.md#deprecated
    module Json
      ParseError = ::MultiJSON::ParseError

      class << self
        def dump(object)
          ::MultiJSON.generate(object)
        end

        # parse is not deprecated; it's re-exposed (not renamed) because this
        # facade is its own module and no longer inherits MultiJSON's methods.
        def parse(source)
          ::MultiJSON.parse(source)
        end
      end
    end
  elsif defined?(::MultiJson)
    # Legacy multi_json (< 1.21) predates generate/parse and only exposes
    # dump/load. Map Grape's surface onto them so the call sites stay
    # engine-agnostic (these names are not deprecated on < 1.21).
    module Json
      # Mutually exclusive with the MultiJSON branch above; only one runs.
      ParseError = ::MultiJson::ParseError # rubocop:disable Lint/ConstantReassignment

      class << self
        def dump(object)
          ::MultiJson.dump(object)
        end

        def parse(source)
          ::MultiJson.load(source)
        end
      end
    end
  else
    Json = ::JSON
    Json::ParseError = Json::ParserError
  end
end
