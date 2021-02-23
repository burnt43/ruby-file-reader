require 'minitest/pride'
require 'minitest/autorun'

require 'pathname'
require 'fileutils'

require './lib/ruby-file-reader'

module RubyFileReader
  module Testing
    class << self
      def tmpfile_dir_pathname
        @tmpfile_path ||= Pathname.new('./test/assets/tmp')
      end

      def tmpfile_pathname(name)
        tmpfile_dir_pathname.join(name)
      end

      def ensure_tmpfile_dir_exists!
        FileUtils.mkdir_p(tmpfile_dir_pathname)
      end
    end

    class Test < Minitest::Test
      def teardown
        RubyFileReader::Testing.tmpfile_dir_pathname.each_child do |child|
          FileUtils.rm_f(child)
        end
      end

      private

      def write_to_tmpfile(name, data)
        IO.write(RubyFileReader::Testing.tmpfile_pathname(name), data, mode: 'a')
      end
    end
  end
end

RubyFileReader::Reader.meta_info_dir_pathname = Pathname.new('./test/assets/tmp')
RubyFileReader::Testing.ensure_tmpfile_dir_exists!
