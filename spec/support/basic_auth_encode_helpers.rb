# frozen_string_literal: true

require 'base64'

module Spec
  module Support
    module Helpers
      def encode_basic_auth(username, password)
        "Basic #{Base64.encode64("#{username}:#{password}")}"
      end
    end
  end
end
