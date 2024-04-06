# frozen_string_literal: true

module Grape
  module Util
    if Gem::Version.new(Rack.release) >= Gem::Version.new('3')
      require 'rack/headers'
      Header = Rack::Headers
    else
      require 'rack/utils'
      Header = Rack::Utils::HeaderHash
    end
  end
end
