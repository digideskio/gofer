class Hash
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
end
