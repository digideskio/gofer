class String
  def rpl(what, value)
    gsub("%{#{Regexp.escape(what)}}", value)
  end
end
