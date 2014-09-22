module Gofer
  module Helpers
    def to_s
      "#{@username}@#{@hostname}"
    end

    def inspect
      "<#{self.class} @host = #{@hostname}, @user = #{@username}>"
    end
  end
end
