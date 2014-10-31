class Hash
  def deep_merge!(hash)
    merge!(hash) do |key, ovalue, nvalue|
      ovalue.is_a?(Hash) && nvalue.is_a?(Hash) ? ovalue.deep_merge!(nvalue) : nvalue
    end
  end

  def stringize!
    replace(stringize)
  end

  def stringize
    return self unless size > 0
    inject({}) do |hash, (key, value)|
      hash[key.to_s] = value.to_s
      hash
    end
  end

  def merge_if!(hash)
    merge!(hash) do |key, ovalue, nvalue|
      if nvalue.is_a?(Hash) && ovalue.is_a?(Hash)
        ovalue.merge_if!(nvalue)
      else
        ! has_key?(key) || ovalue.nil? ? nvalue : ovalue
      end
    end
  end
end
