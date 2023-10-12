# frozen_string_literal: true

require 'test_prof/recipes/rspec/let_it_be'

TestProf::BeforeAll.adapter = Class.new do
  def begin_transaction; end

  def rollback_transaction; end
end.new
