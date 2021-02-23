module Warning
  def warn(msg)
    # NoOp
  end
end

require 'minitest/pride'
require 'minitest/autorun'

require 'pathname'
require 'fileutils'

require './lib/ruby-file-reader'

module RubyFileReader
  module Testing
    class << self
      # Pathname for the tmpfile directory.
      def tmpfile_dir_pathname
        @tmpfile_path ||= Pathname.new('./test/assets/tmp')
      end

      # Return a Pathname for a file in the tmpfile directory with the
      # specified name.
      def tmpfile_pathname(name)
        tmpfile_dir_pathname.join(name)
      end

      # Create the tmpfile directory if it does not exist. This directory
      # probably won't be in the repo, because it is empty, so we need to
      # create it if it does not exist.
      def ensure_tmpfile_dir_exists!
        FileUtils.mkdir_p(tmpfile_dir_pathname)
      end
    end

    class Test < Minitest::Test
      def teardown
        # Remove all the files in the tmpfile directory.
        RubyFileReader::Testing.tmpfile_dir_pathname.each_child do |child|
          FileUtils.rm_f(child)
        end
      end

      private

      def write_to_tmpfile(name, data, append: true, new_inode: false)
        # Get the Pathname for the tmpfile with specified name.
        p = RubyFileReader::Testing.tmpfile_pathname(name)

        if new_inode && p.exist?
          # File exists and we want a new inode.

          # Create a Pathname to represent where we will move the
          # existing file. This will maintain its inode, so when
          # we create a new file with the same name it will have to have
          # a different inode than before.
          renamed_p = p.parent.join("#{p.basename}.bak")

          # Rename the old file by moving it.
          FileUtils.mv(p, renamed_p)

          # Copy the renamed file to its original name. This will effectively
          # change the inode, but the file will remain the same otherwise.
          FileUtils.cp(renamed_p, p)
        end

        # Write the data to the file.
        p.write(data, mode: (append ? 'a' : 'w'))
      end
    end
  end
end

RubyFileReader::Reader.debug = false
RubyFileReader::Reader.meta_info_dir_pathname = Pathname.new('./test/assets/tmp')
RubyFileReader::Testing.ensure_tmpfile_dir_exists!
