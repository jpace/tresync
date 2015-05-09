require 'rubygems'
require 'fileutils'
require 'rake/testtask'
require 'rubygems/package_task'

task :default => :test

APP_NAME = "tresync"

Rake::TestTask.new('test') do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.warning = true
  t.verbose = true
end

directory "man"

desc "generate man page"
task :generate_manpage => [ "man" ] do
  sh "ronn -r --pipe README.md > man/#{APP_NAME}.1"
end

spec = Gem::Specification.new do |s| 
  s.name               = APP_NAME
  s.version            = "0.0.1"
  s.author             = "Jeff Pace"
  s.email              = "jeugenepace@gmail.com"
  s.homepage           = "http://github.com/jpace/#{APP_NAME}"
  s.platform           = Gem::Platform::RUBY
  s.summary            = "Creates full and incremental backups."
  s.description        = <<-EODESC
Tresync ...
EODESC
  s.files              = FileList["{lib,man}/**/*"].to_a + FileList["bin/#{APP_NAME}"].to_a
  s.require_path       = "lib"
  s.test_files         = FileList["{test}/**/*.rb"].to_a
  s.has_rdoc           = false
  s.bindir             = 'bin'
  s.executables        = [ APP_NAME ]
  s.default_executable = APP_NAME
  s.license            = 'MIT'
end

Gem::PackageTask.new(spec) do |pkg| 
  pkg.need_zip = true 
  pkg.need_tar_gz = true 
end 
