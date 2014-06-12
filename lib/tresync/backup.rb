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
    @filetrees.sync_stati
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
  
  def ignore_other? from_other
    if from_other.symlink?
      to = @filetrees.as_to from_other
      to.symlink?
    else
      # others, from Pathname.new('.').methods.sort.select { |m| m[-1] == '?' }
      
      # :absolute?, :blockdev?, :chardev?, :directory?, :eql?, :equal?,
      # :executable?, :executable_real?, :exist?, :file?, :fnmatch?, :frozen?,
      # :grpowned?, :instance_of?, :instance_variable_defined?, :is_a?,
      # :kind_of?, :mountpoint?, :nil?, :owned?, :pipe?, :readable?,
      # :readable_real?, :relative?, :respond_to?, :root?, :setgid?, :setuid?,
      # :size?, :socket?, :sticky?, :symlink?, :tainted?, :untrusted?,
      # :world_readable?, :world_writable?, :writable?, :writable_real?, :zero?

      $stderr.puts "unhandled file type: #{from_other}"
      true
    end
  end

  def process_other from_link
    @filetrees.copy_link from_link
  end
end
