class String

  # Allows you to replace a piece of a string with a word, it's a cheap sub
  # method that allows me to do things.

  def rpl(wat, val)
    gsub("%{#{Regexp.escape(wat)}}", val)
  end
end
