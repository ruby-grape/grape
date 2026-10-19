# frozen_string_literal: true

module Grape
  module Formatter
    # Registers Markdown's rendering under +md+ too, for an API that declares
    # +content_type :md+ rather than +:markdown+ (see
    # Grape::ContentTypes::FORMAT_SYNONYMS).
    class Md < Markdown
    end
  end
end
