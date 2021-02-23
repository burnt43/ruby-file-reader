require 'pathname'
require 'fileutils'

module RubyFileReader
  class Reader
    class << self
      def meta_info_dir_pathname=(value)
        @meta_info_dir_pathname =
          if pathname.is_a?(Pathname)
            value
          else
            Pathname.new(value.to_s)
          end
      end

      def meta_info_dir_pathname
        @meta_info_dir_pathname ||= Pathname.new("/home/#{`whoami`.strip}/.ruby-file-reader")
      end

      def read_new_data(pathname, &block)
        reader = RubyFileReader::Reader.new(pathname)
        reader.read_new_data(&block)
      end
    end

    def initialize(pathname)
      @pathname =
        if pathname.is_a?(Pathname)
          pathname
        else
          Pathname.new(pathname.to_s)
        end
    end

    def read_new_data(&block)
      read
      block.call(@read_string)
      update_meta_info!
    end

    private

    def read
      @inode = `ls -i #{@pathname.to_s}`.split[0]
      @read_string = IO.read(@pathname, mode: 'r')
      @read_bytes = @read_string.bytesize
    end

    def update_meta_info!
      ensure_meta_info_dir_exists!
    end

    def meta_info_file_pathname
      RubyFileReader::Reader.meta_info_dir_pathname.join(
        @pathname.to_s.gsub('/', '_____')
      )
    end

    def ensure_meta_info_dir_exists!
      FileUtils.mkdir_p(RubyFileReader::Reader.meta_info_dir_pathname)
    end
  end
end
