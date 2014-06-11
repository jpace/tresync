#!/usr/bin/ruby -w
# -*- ruby -*-

require 'pathname'
require 'fileutils'

# I could subclass Pathname to add these methods, and Pathname almost always
# works fine, doing self.class.new instead of Pathname.new ... usually. However,
# the Pathname#parent method does Pathname.new, so the resulting object would
# have none of these methods. Thus I'm monkey-patching instead.

class Pathname
  def self.fullpath name
    new(name).expand_path
  end

  def copy to
    puts "copy: #{self} => #{to}" # if $verbose
    dir = to.parent
    origmode = nil
    unless dir.writable?
      origmode = dir.make_world_writable
    end
    FileUtils.cp to_s, to.to_s
    if origmode
      dir.chmod origmode
    end
  end

  def make_world_writable
    origmode = stat.mode
    newmode = origmode | 0222
    File.chmod newmode, to_s
    origmode
  end

  def sub_pathname rootfrom, tgt
    # pathname has #sub now, evidently ...
    self.class.new sub(rootfrom.to_s, tgt.to_s)
  end

  def sync_status tgt
    st = stat
    tgt.chmod st.mode
    tgt.chown st.uid, st.gid
  end
end
