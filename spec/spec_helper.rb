require ::File::expand_path( "../../lib/ecore", __FILE__ )
require ::File::expand_path( "../fixtures/test_event", __FILE__ )

require 'rspec'
require 'rspec/autorun'
require 'fileutils'

def cleanup
  FileUtils::rm_rf(::File::join(Dir.pwd,'repos'))
  Ecore::Repository.new :repos_path => 'repos', :sessions => false, :loglevel => :debug, :logfile => $stdout
end

cleanup

