# frozen_string_literal: true

module Grape
  module Formatter
    # Registers Md's rendering under +markdown+ too, for an API that declares
    # +content_type :markdown+ rather than +:md+ (see
    # Grape::ContentTypes::FORMAT_SYNONYMS).
    class Markdown < Md
      FORMAT = 'markdown'
    end
  end
end
