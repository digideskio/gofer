class Hash
  def merge_if(hash)
    self.merge(hash) do |k, ov, nv|
      if nv.is_a?(Hash) && ov.is_a?(Hash)
        then ov.merge_if(nv)
        else ! has_key?(k) || ov.nil? ? nv : ov
      end
    end
  end
end
