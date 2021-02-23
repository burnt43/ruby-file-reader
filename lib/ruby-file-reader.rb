require 'pathname'
require 'fileutils'

module RubyFileReader
  class Reader
    class << self
      def debug=(value)
        @debug = value
      end

      def debug?
        @debug
      end

      def meta_info_dir_pathname=(value)
        @meta_info_dir_pathname =
          if value.is_a?(Pathname)
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

      @data_read = false
    end

    def read_new_data(&block)
      read
      block.call(@read_string)
      update_meta_info!
    end

    def to_s
      @pathname.to_s
    end

    private

    def read
      if RubyFileReader::Reader.debug?
        puts "[DEBUG] - #{self}##{__method__}----------------------------------------"
      end

      # Determine the inode number of the file we want to read.
      @inode = `ls -i #{@pathname.to_s}`.split[0].to_i

      # Read the meta info file for the file we want to read.
      meta_info = read_meta_info

      if meta_info[:inode] != @inode
        # The inode has changed for this file since we last read it, so
        # we need to read it from the beginning.

        offset = 0

        if RubyFileReader::Reader.debug?
          puts "[DEBUG] - #{self}##{__method__}: inode has changed!"
          puts "[DEBUG] - #{self}##{__method__}: offset: #{offset}"
        end

        @read_string = IO.read(@pathname, nil, offset, mode: 'r')
        @read_bytes = @read_string.bytesize
      elsif @pathname.size < meta_info[:bytes_read]
        # The inode has not changed, but the file size is smaller, which means
        # the file may have been truncated at some point, so we will read the
        # while file.

        offset = 0

        if RubyFileReader::Reader.debug?
          puts "[DEBUG] - #{self}##{__method__}: inode match. possible truncated file."
          puts "[DEBUG] - #{self}##{__method__}: offset: #{offset}"
        end

        @read_string = IO.read(@pathname, nil, 0, mode: 'r')
        @read_bytes = @read_string.bytesize
      else
        # The inode is the same as the last time we read it and the file size
        # is >= than last time, so we can read from where we left off.

        offset = meta_info[:bytes_read]

        if RubyFileReader::Reader.debug?
          puts "[DEBUG] - #{self}##{__method__}: inode match"
          puts "[DEBUG] - #{self}##{__method__}: offset: #{offset}"
        end

        @read_string = IO.read(@pathname, nil, offset, mode: 'r')
        @read_bytes = meta_info[:bytes_read] + @read_string.bytesize
      end

      @data_read = true

      if RubyFileReader::Reader.debug?
        puts "[DEBUG] - #{self}##{__method__}: inode: #{@inode}"
        puts "[DEBUG] - #{self}##{__method__}: read_string: #{@read_string}"
        puts "[DEBUG] - #{self}##{__method__}: read_bytes #{@read_bytes}"
        puts "[DEBUG] - #{self}##{__method__}: data_read: #{@data_read}"
      end
    end

    def has_been_read?
      @data_read
    end

    def read_meta_info
      if meta_info_file_pathname.exist?
        inode, bytes_read = meta_info_file_pathname.read.strip.split(':').map(&:to_i)
        {
          inode:      inode,
          bytes_read: bytes_read
        }
      else
        {
          inode: nil,
          bytes_read: 0
        }
      end
    end

    def update_meta_info!
      return unless has_been_read?

      ensure_meta_info_dir_exists!
      meta_info_file_pathname.write("#{@inode}:#{@read_bytes}")
    end

    def meta_info_file_pathname
      return @meta_info_file_pathname if @meta_info_file_pathname

      pathname_non_hidden = RubyFileReader::Reader.meta_info_dir_pathname.join(
        @pathname.to_s.gsub('/', '_____')
      )
      @meta_info_file_pathname = pathname_non_hidden.parent.join(".#{pathname_non_hidden.basename.to_s}")
    end

    def ensure_meta_info_dir_exists!
      FileUtils.mkdir_p(RubyFileReader::Reader.meta_info_dir_pathname)
    end
  end
end
