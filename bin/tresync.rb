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


# I could subclass Pathname to add these methods, and Pathname almost always
# works fine, doing self.class.new instead of Pathname.new ... usually. However,
# the Pathname#parent method doing Pathname.new, so it would have none of these
# methods. Thus I'm monkey-patching instead.

class Pathname

  def self.fullpath name
    new(name).expand_path
  end
  def copy to
    puts "copy: #{self} => #{to}" # if $verbose
    FileUtils.cp to_s, to.to_s
  end

  def sub_pathname rootfrom, tgt
    # pathname has #sub now, evidently ...
    self.class.new sub(rootfrom.to_s, tgt.to_s)
  end

  def sync_status tgt
    tgt_path = tgt.to_path
    stat = File.stat to_path
    sync_permissions tgt_path, stat
    sync_owner tgt_path, stat
  end

  def sync_permissions tgt_path, stat
    File.chmod stat.mode, tgt_path
  end

  def sync_owner tgt_path, stat
    File.chown stat.uid, stat.gid, tgt_path
  end
end

class FileTrees
  attr_reader :from
  attr_reader :to
  attr_reader :dest
  
  def initialize from, to, dest = to
    @from = Pathname.fullpath from
    @to = Pathname.fullpath to
    @dest = Pathname.fullpath dest
    @dest.mkpath
  end

  def as_to fr
    fr.sub_pathname @from, @to
  end

  def as_destination fr
    fr.sub_pathname @from, @dest
  end

  def create_dir fromdir
    dest = as_destination fromdir
    unless dest.exist?
      mkdirs dest, fromdir
    end
  end

  def mkdirs tgtdir, fromdir
    if tgtdir != @dest
      create_dir fromdir.parent
    end
    mkdir tgtdir, fromdir
  end

  def mkdir tgtdir, fromdir
    tgtdir.mkdir
    fromdir.sync_status tgtdir
  end

  def copy_file from_file
    create_dir from_file.parent
    dest = as_destination from_file
    from_file.copy dest
    from_file.sync_status dest
  end
end

class Syncker
  def ignore_directory? dir
    false
  end

  def ignore_file? file
    false
  end

  def ignore_other? other
    false
  end

  def process_directory dir
  end

  def process_file file
  end

  def process_other other
  end

  def sync_directory dir
    ignore_directory?(dir) || process_directory(dir)
  end

  def sync_file file
    ignore_file?(file) || process_file(file)
  end

  def sync_other other
    ignore_other?(other) || process_other(other)
  end
  
  def sync pn
    if pn.directory?
      sync_directory pn
    elsif pn.file?
      sync_file pn
    else
      sync_other pn
    end
  end
end

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

from = ARGV.shift
to = ARGV.shift
dest = ARGV.shift || to

Backup.new from, to, dest
