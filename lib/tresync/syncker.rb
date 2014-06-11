#!/usr/bin/ruby -w
# -*- ruby -*-

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
