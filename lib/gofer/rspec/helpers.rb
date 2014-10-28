module Gofer
  module Rspec
    module Helpers
      def with_tmp(&block)
        tmpdir = Tmp.new
        block.call(tmpdir)
      ensure
        if tmpdir
          tmpdir.destroy
        end
      end
    end
  end
end
