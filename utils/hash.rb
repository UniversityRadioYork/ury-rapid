class Hash
  # Public: Like Hash#map, but returns a new Hash.
  #
  # Yields the key and value (expects a new key and value back).
  #
  # Returns the new Hash.
  def map_to_hash
    each_with_object({}) do |(key, value), hash|
      new_key, new_value = yield(key, value)
      hash[new_key] = new_value
    end
  end

  # Public: Creates a new Hash by transforming the values of this Hash.
  #
  # Yields each value (expects a new value back).
  #
  # Returns the new Hash.
  def transform_values
    map_to_hash { |key, value| [key, yield(value)] }
  end
end
