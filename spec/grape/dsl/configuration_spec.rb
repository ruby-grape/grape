# frozen_string_literal: true

module Grape
  module DSL
    module ConfigurationSpec
      class Dummy
        include Grape::DSL::Configuration
      end
    end
    describe Configuration do
      subject { Class.new(ConfigurationSpec::Dummy) }
    end
  end
end
