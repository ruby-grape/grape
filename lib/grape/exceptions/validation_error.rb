require 'grape/exceptions/base'

class ValidationError < Grape::Exceptions::Base
  attr_accessor :param

  def initialize(args = {})
    @param = args[:param].to_s if args.has_key? :param
    super
  end
end
