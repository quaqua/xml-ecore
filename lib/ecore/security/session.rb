libdir = File::dirname(__FILE__)
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)

require 'user'
require 'group'

module Ecore
  
  class AuthenticationFailed < StandardError
  end
  
  # A session authenticates a user against the
  # database. Once initialized, it can be used
  # to perform node operations
  class Session
    
    attr_reader :user
    
    # Session.new(:email => 'user@email.com', :password => 'cleartextpassword')
    # if authentication fails, a AuthenticationFailed error will be thrown
    def initialize(options)
      options[:hashed_password] = Ecore::User.encrypt_password( options.delete(:password) ) if options[:password]
      ( @user = Ecore::User.anybody ; @user.session = self ; return ) if options[:name] == "anybody"
      raise AuthenticationFailed.new unless (validate_options( options ) and authenticate( options ))
    end
    
    # authenticates given user attributes against index file
    # at least name or email and password has to be given
    def authenticate(options)
      sessions = Ecore::ENV[:sessions]
      Ecore::ENV[:sessions] = false
      @user = Ecore::User.find(nil, :name => options[:name], :hashed_password => options[:hashed_password]) if options.has_key?(:name)
      @user = Ecore::User.find(nil, :email => options[:email], :hashed_password => options[:hashed_password]) if @user.nil? and options.has_key?(:email)
      return false if @user.nil?
      @user = @user.first if @user.is_a?(Ecore::NodeArray)
      return false unless @user.is_a?(Ecore::User)
      @user.session = self
      true
    ensure
      Ecore::ENV[:sessions] = sessions
    end
    
    # reloads a session and updates session's user attributes
    def reload
      sessions = Ecore::ENV[:sessions]
      Ecore::ENV[:sessions] = false
      @user = Ecore::User.find(nil, :id => @user.id)
      Ecore::ENV[:sessions] = sessions
    end
    
    private
    
    def validate_options( options )
      return false if !options.has_key?(:email) and !options.has_key?(:name)
      return false if options.has_key?(:email) and options[:email].empty?
      return false if options.has_key?(:name) and options[:name].empty?
      #return false if !options.has_key?(:hashed_password) or options[:hashed_password].empty?
      true
    end
    
  end
end
