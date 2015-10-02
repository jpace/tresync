#!/usr/bin/ruby -w
# -*- ruby -*-

require 'tresync/filetrees'
require 'tresync/syncker'
require 'tresync/filter'

class Backup < Syncker
  def initialize from, to, dest = to
    @filetrees = FileTrees.new from, to, dest
    @verbose = true
    @filter = Filter.new 

    sync @filetrees.from
    @filetrees.sync_stati
  end

  def ignore_directory? dir
    ignore = !dir.readable? || @filter.skip_dir?(dir)
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
    if from_file.readable?
      to.exist? && to.mtime >= from_file.mtime
    else
      $stderr.puts "unreadable file: #{from_file}"
      true
    end
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
      
      $stderr.puts "unhandled file type: #{from_other}"

      if false
        $stderr.puts ":absolute?: #{from_other.absolute?}"
        $stderr.puts ":blockdev?: #{from_other.blockdev?}"
        $stderr.puts ":chardev?: #{from_other.chardev?}"
        $stderr.puts ":directory?: #{from_other.directory?}"
        $stderr.puts ":executable?: #{from_other.executable?}"
        $stderr.puts ":executable_real?: #{from_other.executable_real?}"
        $stderr.puts ":exist?: #{from_other.exist?}"
        $stderr.puts ":file?: #{from_other.file?}"
        $stderr.puts ":grpowned?: #{from_other.grpowned?}"
        $stderr.puts ":mountpoint?: #{from_other.mountpoint?}"
        $stderr.puts ":owned?: #{from_other.owned?}"
        $stderr.puts ":pipe?: #{from_other.pipe?}"
        $stderr.puts ":readable?: #{from_other.readable?}"
        $stderr.puts ":readable_real?: #{from_other.readable_real?}"
        $stderr.puts ":relative?: #{from_other.relative?}"
        $stderr.puts ":root?: #{from_other.root?}"
        $stderr.puts ":size?: #{from_other.size?}"
        $stderr.puts ":socket?: #{from_other.socket?}"
        $stderr.puts ":sticky?: #{from_other.sticky?}"
        $stderr.puts ":symlink?: #{from_other.symlink?}"
        $stderr.puts ":world_readable?: #{from_other.world_readable?}"
        $stderr.puts ":world_writable?: #{from_other.world_writable?}"
        $stderr.puts ":writable?: #{from_other.writable?}"
        $stderr.puts ":writable_real?: #{from_other.writable_real?}"
      end

      true
    end
  end

  def process_other from_link
    @filetrees.copy_link from_link
  end
end
