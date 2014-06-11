#!/usr/bin/ruby -w
# -*- ruby -*-

require 'tresync/extpathname'

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
    par = tgtdir.parent
    origmode = nil
    if par.writable?
      origmode = par.make_world_writable
    end
    tgtdir.mkdir
    if origmode
      par.chmod origmode
    end
    fromdir.sync_status tgtdir
  end

  def copy_file from_file
    create_dir from_file.parent
    dest = as_destination from_file
    from_file.copy dest
    from_file.sync_status dest
  end
end
