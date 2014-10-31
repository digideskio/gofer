class Hash
  def deep_merge(hash)
    merge(hash) do |key, ovalue, nvalue|
      if ovalue.respond_to?(:deep_merge) && nvalue.respond_to?(:deep_merge)
        ovalue.deep_merge(nvalue)
      else
        nvalue
      end
    end
  end

  def deep_merge!(hash)
    replace(deep_merge(hash))
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

  def merge_if(hash)
    merge(hash) do |key, ovalue, nvalue|
      if ovalue.respond_to?(:merge_if) && nvalue.respond_to?(:merge_if)
        ovalue.merge_if(nvalue)
      else
        ! has_key?(key) ? nvalue : ovalue
      end
    end
  end

  def merge_if!(hash)
    replace(merge_if(hash))
  end
end
