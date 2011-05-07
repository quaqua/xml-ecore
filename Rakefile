require 'bundler'
Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new do |test|
  #test.pattern = "./spec/**/*_spec.rb"
end

RSpec::Core::RakeTask.new(:coverage) do |t|
  t.pattern = "./spec/**/*_spec.rb" # don't need this, it's default.
  t.rcov = true
  t.rcov_opts = ['--exclude', 'spec']
end

require 'reek/rake/task'
Reek::Rake::Task.new do |t|
  t.fail_on_error = true
  t.verbose = false
  t.source_files = 'lib/**/*.rb'
end

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "ecore #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

task :stresstest do
  require File::expand_path("../lib/ecore",__FILE__)
  #require 'fileutils'
  #FileUtils::rm_rf('repos')
  init_time = Time.now
  n = 10000
  Ecore::Repository.new :repos_path => 'repos', :sessions => false, :loglevel => :warn
  (1..n).each do |i|
    Ecore::Node.create(nil, :name => "test#{i}")
  end
  puts "created #{n} nodes in #{Time.now - init_time} seconds"
  init_time = Time.now
  nodes = Ecore::Node.find(nil, :name.contains => "test")
  puts "looked up #{n} nodes and found #{nodes.size} nodes matching contains('test') in #{Time.now - init_time} seconds"
  init_time = Time.now
  nodes = Ecore::Node.find(nil, :name => "test#{n}")
  puts "lookded up #{n} nodes and found node.name='test#{n}' in #{Time.now - init_time} seconds"
end

task :stressread do
  require File::expand_path("../lib/ecore",__FILE__)
  Ecore::Repository.new :repos_path => 'repos', :sessions => false
  init_time = Time.now
  nodes = Ecore::Node.find(nil, :name => "test9500")
  puts "found node.name='test9500' in #{Time.now - init_time} seconds"
  init_time = Time.now
  node = Ecore::Node.find(nil, :id => nodes.first.id)
  puts "found node with id = #{node.id} in #{Time.now - init_time} seconds"
end

task :default => :spec
