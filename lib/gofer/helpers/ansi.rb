module Gofer
  module Helpers
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

      def self.mcolor_single(*strs, color)
        strs.map do |str|
          wrap(color, str)
        end
      end

      def self.strip(str)
        str.gsub(/\e\[(?:\d+)(?:;\d+)?m/, "")
      end

      def self.escape(color)
        ANSI_ESCAPE % COLORS[color]
      end

      def self.wrap(color, str)
        "#{escape(color)}#{str}#{escape(:reset)}"
      end

      COLORS.each do |key, value|
        define_singleton_method key do |str|
          wrap(key, str)
        end
      end
    end
  end
end
