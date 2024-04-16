# frozen_string_literal: true

module Chunks
  def read_chunks(body)
    buffer = []
    body.each { |chunk| buffer << chunk } # rubocop:disable Style/MapIntoArray

    buffer
  end
end

RSpec.configure do |config|
  config.include Chunks
end
