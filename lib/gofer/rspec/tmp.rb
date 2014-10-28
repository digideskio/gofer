module Gofer
  module Rspec
    class Tmp
      attr_reader :tmpdir

      def initialize
        @tmpdir = Pathname.new(Dir.mktmpdir("gofertest"))
      end

      def create_tmpfile(file, val = nil)
        file = FileUtils.touch(@tmpdir.join(file)).first
        File.write(file, val) if val
        file
      end

      def destroy
        FileUtils.remove_entry_secure @tmpdir, {
          :force => true, :recursive => true
        }
      end
    end
  end
end
