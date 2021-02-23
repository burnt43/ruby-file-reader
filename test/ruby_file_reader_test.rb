require './test/test_helper.rb'

module RubyFileReader
  module Testing
    class RubyFileReaderTest < RubyFileReader::Testing::Test
      def test_simple_read_new_data
        write_to_tmpfile('file0001.txt', "LINE_0001\n")

        RubyFileReader::Reader.read_new_data(RubyFileReader::Testing.tmpfile_pathname('file0001.txt')) do |data|
          assert_equal("LINE_0001\n", data)
        end

        write_to_tmpfile('file0001.txt', "LINE_0002\n")

        RubyFileReader::Reader.read_new_data(RubyFileReader::Testing.tmpfile_pathname('file0001.txt')) do |data|
          assert_equal("LINE_0002\n", data)
        end
      end
    end
  end
end
