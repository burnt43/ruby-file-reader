require './test/test_helper.rb'

module RubyFileReader
  module Testing
    class RubyFileReaderTest < RubyFileReader::Testing::Test
      def test_read_new_data_on_appended_file
        filename = 'file0001.txt'
        reader = RubyFileReader::Reader.new(RubyFileReader::Testing.tmpfile_pathname(filename))

        write_to_tmpfile(filename, "LINE_0001\n")

        reader.read_new_data do |data|
          assert_equal("LINE_0001\n", data)
        end

        write_to_tmpfile(filename, "LINE_0002\n")

        reader.read_new_data do |data|
          assert_equal("LINE_0002\n", data)
        end

        write_to_tmpfile(filename, "LINE_0003a")

        reader.read_new_data do |data|
          assert_equal("LINE_0003a", data)
        end

        write_to_tmpfile(filename, "LINE_0003b")

        reader.read_new_data do |data|
          assert_equal("LINE_0003b", data)
        end
      end

      def test_read_new_data_on_truncated_file
        filename = 'file0002.txt'
        reader = RubyFileReader::Reader.new(RubyFileReader::Testing.tmpfile_pathname(filename))

        write_to_tmpfile(filename, "LINE_0001\n", append: false)

        reader.read_new_data do |data|
          assert_equal("LINE_0001\n", data)
        end

        write_to_tmpfile(filename, "foo\n", append: false)

        reader.read_new_data do |data|
          assert_equal("foo\n", data)
        end
      end

      def test_read_new_data_when_inode_changes
        filename = 'file0003.txt'
        reader = RubyFileReader::Reader.new(RubyFileReader::Testing.tmpfile_pathname(filename))

        write_to_tmpfile(filename, "LINE_0001\n")

        reader.read_new_data do |data|
          assert_equal("LINE_0001\n", data)
        end

        write_to_tmpfile(filename, "LINE_0002\n", new_inode: true)

        reader.read_new_data do |data|
          assert_equal("LINE_0001\nLINE_0002\n", data)
        end
      end
    end
  end
end
