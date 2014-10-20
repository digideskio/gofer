class Hash
  def elegant_merge(hash)
    merge(hash) do |k, ov, nv|
      ov.is_a?(Hash) && nv.is_a?(Hash) ? ov.elegant_merge(nv) : nv
    end
  end

  def symbolize_keys
    inject({}) do |h, (k, v)|
      # I am not in the business of messing with non-String object keys.
      h.update(k.is_a?(String) ? k.to_sym : k => v.is_a?(Hash) ? v.symbolize_keys : v)
    end
  end

  def merge_if(hash)
    self.merge(hash) do |k, ov, nv|
      if nv.is_a?(Hash) && ov.is_a?(Hash)
        then ov.merge_if(nv)
        else ! has_key?(k) || ov.nil? ? nv : ov
      end
    end
  end
end
