# frozen_string_literal: true

module Chunks
  def read_chunks(body)
    buffer = []
    body.each { |chunk| buffer << chunk }

    buffer
  end
end

RSpec.configure do |config|
  config.include Chunks
end
