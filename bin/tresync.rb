#!/usr/bin/ruby -w
# -*- ruby -*-

require 'pathname'
require 'fileutils'

# full backup mode:
# usage: backup.rb src dest
#  - will sync files from <src> to <dest>

# iterative backup mode:
# usage: backup.rb src ref dest 
#  - will sync files from <src> to <dest> that are newer/not in <ref>

# so running:
# monday  : backup.rb /home/me /media/home/me
#  - full copy of /home/me in /media/home/me
# tuesday  : backup.rb /home/me /media/home/me /media/home/me.1
#  - files in /home/me newer/not in /media/home/me are copied to /media/home/me.1
# wednesday: backup.rb /home/me /media/home/me /media/home/me.2
#  - as above (note that /media/home/me.2 can have files also in /media/home/me.1)

# thursday:
#  - hard drive crash, whatever ... to restore /home/me/src:
#  - first the last full backup:
#      rsync -rav /media/home/me/src/ /home/me/src
#  - now any updated files since then:
#      rsync -rav /media/home/me.1/src/ /home/me/src
#      rsync -rav /media/home/me.2/src/ /home/me/src
#  - note the trailing slashes, for rsync ... or do
#      rsync -rav /media/home/me/src /home/me
#      rsync -rav /media/home/me.1/src /home/me
#      rsync -rav /media/home/me.2/src /home/me

class PathnameFactory
  def initialize from, to, dest
    @from = from
    @to = to
    @dest = dest
    @verbose = true
  end

  def create name
    Pathname.new name
  end
end

class Pathname
  def copy to
    puts "copy: #{self} => #{to}" # if $verbose
    FileUtils.cp to_s, to.to_s
  end

  def sub_pathname rootfrom, tgt
    # pathname has #sub now, evidently ...
    self.class.new sub(rootfrom.to_s, tgt.to_s)
  end

  def sync_status dest
    dest_path = dest.to_path
    stat = File.stat to_path
    sync_permissions dest_path, stat
    sync_owner dest_path, stat
  end

  def sync_permissions dest_path, stat
    File.chmod stat.mode, dest_path
  end

  def sync_owner dest_path, stat
    File.chown stat.uid, stat.gid, dest_path
  end
end

class Backup
  SKIP_DIRECTORIES = %w{ .nobackup .archive }

  def initialize from, to, dest = to
    @from = to_fullpath from
    @to = to_fullpath to
    @dest = to_fullpath dest
    @verbose = true

    @dest.mkpath

    sync @from
  end

  def to_fullpath what
    Pathname.new(what).expand_path
  end

  def to_pathname from_pn
    from_pn.sub_pathname @from, @to
  end

  def dest_pathname from_pn
    from_pn.sub_pathname @from, @dest
  end

  def copy from_pn, whither
    from_pn.copy whither
  end

  def ignore_dir? dir
    SKIP_DIRECTORIES.find { |fname| (dir + fname).exist? }
  end

  def sync_status from, dest
    from.sync_status dest
  end

  def create_dir from_dir
    dest = dest_pathname from_dir
    return if dest.exist?
    
    if dest != @dest
      create_dir from_dir.parent
    end
    
    dest.mkdir
    from_dir.sync_status dest
  end

  def create_empty_dir from_dir
    create_dir from_dir
  end

  def sync_directory_entries from_dir
    kids = from_dir.children.sort
    if kids.empty?
      create_empty_dir from_dir
    else
      kids.each do |kid|
        sync kid
      end
    end
  end

  def sync_directory from_dir
    if ignore_dir? from_dir
      puts "skipping: #{from_dir}" if @verbose
    else
      sync_directory_entries from_dir
    end
  end
  
  def copy_file from_file
    create_dir from_file.parent
    dest = dest_pathname from_file
    copy from_file, dest
    from_file.sync_status dest
  end

  def to_file_current? from_file
    to = to_pathname from_file
    to.exist? && to.mtime > from_file.mtime
  end

  def sync_file from_file
    unless to_file_current? from_file
      copy_file from_file
    end
  end
  
  def sync from_pn
    if from_pn.directory?
      sync_directory from_pn
    elsif from_pn.file?
      sync_file from_pn
    else
      # @TODO: support for links?
      $stderr.puts "unhandled file type: #{from_pn}"
    end
  end
end

from = ARGV.shift
to = ARGV.shift
dest = ARGV.shift || to

Backup.new from, to, dest
