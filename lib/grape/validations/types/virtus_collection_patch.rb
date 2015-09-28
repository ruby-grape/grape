require 'virtus/attribute/collection'

# See https://github.com/solnic/virtus/pull/343
# This monkey-patch fixes type validation for collections,
# ensuring that type assertions are applied to collection
# members.
#
# This patch duplicates the code in the above pull request.
# Once the request, or equivalent functionality, has been
# published into the +virtus+ gem this file should be deleted.
Virtus::Attribute::Collection.class_eval do
  # @api public
  def value_coerced?(value)
    super && value.all? { |item| member_type.value_coerced? item }
  end
end
