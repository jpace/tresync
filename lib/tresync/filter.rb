#!/usr/bin/ruby -w
# -*- ruby -*-

require 'tresync/filetrees'
require 'tresync/syncker'

class Filter
  SKIP_DIRECTORY_FILES = %w{ .nobackup .archive }
  SKIP_DIRECTORY_NAMES = %w{ .Private }

  def initialize skipdirs = Array.new, skipfiles = Array.new, skippaths = Array.new
    @skipdirs = skipdirs
    @skipfiles = skipfiles
    @skippaths = skippaths
  end

  def skip_dir? dir
    return true if SKIP_DIRECTORY_NAMES.include? dir.basename.to_s
    return true if SKIP_DIRECTORY_FILES.find { |fname| (dir + fname).exist? }
    return true if @skipdirs.include? dir.basename.to_s
    return true if @skippaths.include? dir.to_s
    false
  end
end
