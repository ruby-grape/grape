# frozen_string_literal: true

module Grape
  module Validations
    module Validators
      # Rejects an element that is not a Hash in an Array param given a block,
      # which ParamsScope registers this for: the block declares the keys of
      # each element, and an element with no keys cannot hold any of them.
      # Without it, an element like +"x"+ or a nested Array only failed where
      # the block required a key of it, so a block of optional params let
      # anything through.
      #
      # An Array whose elements are all blank is passed over, as the block's
      # own validators pass over an optional scope whose elements are all
      # blank. Otherwise a blank element is not a Hash either. Elements are
      # scrubbed first, since String#blank? raises on bytes their encoding
      # does not allow.
      class HashElementsValidator < Base
        default_message_key :coerce

        # Registered not required, so it is only asked about params that are a
        # Hash (see Base#validate!).
        def validate_param!(attr_name, params)
          elements = params[attr_name]
          return unless elements.is_a?(Array)
          return if elements.all? { |element| scrub(element).blank? }

          index = elements.index { |element| !hash_like?(element) }
          validation_error!(["#{scope.full_name(attr_name)}[#{index}]"]) if index
        end
      end
    end
  end
end
