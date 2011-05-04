require 'rubygems'
require 'active_support/inflector'
require 'fileutils'
require 'logger'

require ::File::expand_path("../version", __FILE__)
require ::File::expand_path("../auditing", __FILE__)

module Ecore

  # ENVIRONMENT for ecore operations
  ENV = {} unless Ecore.const_defined?("ENV")
  
  # logging
  @@log = nil
  
  # =using Ecore::Repository
  # an ecore repository is used to initialize the repository by
  # passing some parameters (non is really required)
  #
  # e.g.:
  #
  #   Ecore::Repository.new
  # initializes a new repository in the current directory by using
  # "repos/" as the default directory
  #
	#   Ecore::Repository.new :sessions => true, #default
  #                    		:repos_path => 'repos', #default
  #                    		:loglevel => :debug,
  #                    		:logfile => $stdout
  class Repository

    # setup a new repository
    # see class description for usage
    def initialize(options={})
      setup_default_values
      setup_other_options(options)
      setup_path(options[:repos_path])
      Ecore::Auditing::start
      Ecore::log.info("Ecore v#{Ecore::VERSION} initialized. Using #{ENV[:repos_path]}.")
    end

    private

    def setup_path(pathname)
      if pathname
        ENV[:repos_path] = ::File::join(Dir.pwd,pathname)
      else
        begin
          Ecore::log.info('trying java...')
          require 'java'
          java_import java.lang.System
          ENV[:repos_path] =  System.getProperty('repos_path')
          Ecore::log.info("Ecore using java commandline repos_path #{ENV[:repos_path]}")
        ensure
          ENV[:repos_path] = ::File::join(Dir.pwd,'repos') unless ENV[:repos_path]
        end
      end
      Ecore::log.info("Ecore::Repository path is #{ENV[:repos_path]}")
      unless ::File::exists?(ENV[:repos_path])
        Ecore::log.info("Ecore::Repository is setting up datastore directories in #{ENV[:repos_path]}")
        FileUtils::mkdir_p(ENV[:repos_path])
      end
    end
    
    def setup_other_options(options)
      options.each_pair do |key,value|
        next if [:repos_path].include?(key)
        ENV[key] = value
      end
    end
    
    def setup_default_values
      ENV[:sessions] = true
      ENV[:audit_logfile] = "ecore_audit.log"
    end
    
  end
  
  # creates a logger instance. Will keep a module variable
  # once initialized and keep the file open for fast logging
  def self.log
    unless @@log
      @@log = Logger.new((ENV[:logfile] || $stdout))
      @@log.level = eval("Logger::#{(ENV[:loglevel] || :debug).to_s.upcase}")
    end
    @@log
  end

end
