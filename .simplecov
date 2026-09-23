# frozen_string_literal: true

# Configuration only. `SimpleCov.start` lives in spec/spec_helper.rb.
# CI hands Coveralls SimpleCov's own coverage/.resultset.json.
SimpleCov.enable_coverage :branch
SimpleCov.skip '/spec/'
