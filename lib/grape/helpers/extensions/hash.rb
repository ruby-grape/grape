class Hash
  # Recursively replace key names that should be symbols with symbols.
  def key_strings_to_symbols
    new_hash = Hash.new
    self.each_pair do |k,v|
      new_value = (v.kind_of?(Hash) && v.respond_to?(:key_strings_to_symbols)) ? v.key_strings_to_symbols : v
      new_key = k.kind_of?(String) ? k.to_sym : k
      new_hash[new_key] = new_value
    end
    new_hash
  end
end