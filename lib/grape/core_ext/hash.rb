class Hash
  def deep_symbolize_keys
    _deep_transform_keys_in_object(self) do |key|
      begin
       key.to_sym
     rescue
       key
     end
    end
  end unless Hash.method_defined?(:deep_symbolize_keys)

  def deep_symbolize_keys!
    _deep_transform_keys_in_object!(self) do |key|
      begin
        key.to_sym
      rescue
        key
      end
    end
  end unless Hash.method_defined?(:deep_symbolize_keys!)

  def _deep_transform_keys_in_object(object, &block)
    case object
    when Hash
      object.each_with_object({}) do |(key, value), result|
        result[yield(key)] = _deep_transform_keys_in_object(value, &block)
      end
    when Array
      object.map { |e| _deep_transform_keys_in_object(e, &block) }
    else
      object
    end
  end unless Hash.method_defined?(:_deep_transform_keys_in_object)

  def _deep_transform_keys_in_object!(object, &block)
    case object
    when Hash
      object.keys.each do |key|
        value = object.delete(key)
        object[yield(key)] = _deep_transform_keys_in_object!(value, &block)
      end
      object
    when Array
      object.map! { |e| _deep_transform_keys_in_object!(e, &block) }
    else
      object
    end
  end unless Hash.method_defined?(:_deep_transform_keys_in_object!)
end
