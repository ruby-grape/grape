# frozen_string_literal: true

module Grape
  class Railtie < ::Rails::Railtie
    initializer 'grape.deprecator' do |app|
      app.deprecators[:grape] = Grape.deprecator
    end
  end
end
