# Reopening of the Hash class to add utility functions.
class Hash
  # Like Hash#map, but returns a new Hash.
  #
  # Yields the key and value (expects a new key and value back).
  #
  # @return [Hash] The new, transformed Hash.
  def map_to_hash
    each_with_object({}) do |(key, value), hash|
      new_key, new_value = yield(key, value)
      hash[new_key] = new_value
    end
  end

  # Creates a new Hash by transforming the values of this Hash.
  #
  # Yields each value (expects a new value back).
  #
  # @return [Hash] (see #map_to_hash)
  def transform_values
    map_to_hash { |key, value| [key, yield(value)] }
  end

  # Creates a new Hash with the given contents and default block
  #
  # @param contents [Hash] A hash containing the desired initial mapping.
  #
  # @return [Hash] A new hash with the given contents and default block.
  def self.new_with_default_block(contents, &block)
    new(&block).merge!(contents)
  end
end
