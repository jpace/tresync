#!/usr/bin/ruby -w
# -*- ruby -*-

require 'tresync/filetrees'
require 'tresync/syncker'

class Backup < Syncker
  SKIP_DIRECTORY_FILES = %w{ .nobackup .archive }

  def initialize from, to, dest = to
    @filetrees = FileTrees.new from, to, dest
    @verbose = true
    sync @filetrees.from
  end

  def ignore_directory? dir
    ignore = SKIP_DIRECTORY_FILES.find { |fname| (dir + fname).exist? }
    puts "skipping: #{dir}" if @verbose && ignore
    ignore
  end

  def process_each_entry entries
    entries.each do |entry|
      sync entry
    end
  end

  def process_directory from_dir
    kids = from_dir.children.sort
    if kids.empty?
      @filetrees.create_dir from_dir
    else
      process_each_entry kids
    end
  end

  def ignore_file? from_file
    to = @filetrees.as_to from_file
    to.exist? && to.mtime > from_file.mtime
  end

  def process_file from_file
    @filetrees.copy_file from_file
  end
  
  def ignore_other? other
    # @TODO: support for links?
    $stderr.puts "unhandled file type: #{other}"
    true
  end
end
