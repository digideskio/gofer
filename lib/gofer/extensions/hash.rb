class Hash
  def elegant_merge!(hash)
    merge!(hash) do |key, old_value, new_value|
      old_value.is_a?(Hash) && new_value.is_a?(Hash) ? old_value.elegant_merge!(new_value) : new_value
    end
  end

  unless method_defined?(:stringize!)
    def stringize!
      replace(stringize)
    end
  end

  unless method_defined?(:stringize)
    def stringize
      return self unless size > 0
      inject({}) do |hash, (key, value)|
        hash[key.to_s] = value.to_s
        hash
      end
    end
  end

  unless method_defined?(:merge_if!)
    def merge_if!(hash)
      merge!(hash) do |key, old_value, new_value|
        if new_value.is_a?(Hash) && old_value.is_a?(Hash)
          old_value.merge_if!(new_value)
        else
          ! has_key?(key) || old_value.nil? ? new_value : old_value
        end
      end
    end
  end
end
