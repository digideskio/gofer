module Gofer
  class Ansi
    ANSI_ESCAPE = "\e[%dm"
    COLORS = {
      :clear => 0,
      :reset => 0,
      :bold => 1,
      :dark => 2,
      :mellow => 2,
      :faint => 2,
      :italic => 3,
      :underline => 4,
      :underscore => 4,
      :strikethrough => 9,
      :black => 30,
      :red => 31,
      :green => 32,
      :yellow => 33,
      :blue => 34,
      :magenta => 35,
      :cyan => 36,
      :white => 37
    }

    def self.strip(str)
      str.gsub(/\e\[(?:\d+)(?:;\d+)?m/, "")
    end

    def self.escape(color)
      ANSI_ESCAPE % COLORS[color]
    end

    def self.wrap(color, str)
      "#{escape(color)}#{str}#{escape(:reset)}"
    end

    COLORS.each do |k, v|
      define_singleton_method k do |s|
        wrap(k, s)
      end
    end
  end
end
