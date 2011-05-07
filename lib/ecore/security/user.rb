require 'digest/sha2'

module Ecore

  # A user is required to access the repository through a session
  # Users can also keep additional information
  class User < Ecore::Node
  
    class << self
    
      def anybody
        User.new(:id => "00000000", :name => 'anybody')
      end
          
      def everybody
        User.new(:id => "00000001", :name => 'everybody')
      end
      
      def find_readonly(attrs)
        if attrs.is_a?(Hash) and attrs[:id] and attrs[:id].include?("0000000")
          return anybody if attrs[:id] == anybody.id
          return everybody if attrs[:id] == everybody.id
        end
        super(attrs)
      end
    
      def encrypt_password( password )
        ::Digest::SHA512.hexdigest(password)
      end
        
    end
    
    repos_filename  'users.xml'
    
    # don't show instances of this class in
    # browser (ommits hidden objects by default)
    hidden true
    
    # temporary used in forms
    attr_accessor :password
    attr_accessor :id
    attr_accessor :send_confirmation
    
    string  :email, :index => true
    string  :fullname
    
    string  :role, :index => true
    string  :group_ids, :index => true

    string  :last_login_ip
    time    :last_login_at
    
    string  :last_request_ip
    time    :last_request_at
    
    # used for first login ( if admin doesn't set password,
    # respectively if default user has invited/shared-content-with
    # other user
    string  :confirmation_key, :index => true
    
    boolean :suspended, :index => true
    string  :hashed_password, :index => true
    string  :forgot_password_key, :index => true
    
    string  :avatar
    
    validates :email_format, :email
    
    before  :create, :check_and_setup_password
    before  :save, :hash_password
    
    after   :create, :setup_user_as_its_own_owner
        
    def initialize( args={} )
      @group_ids = "" unless args.has_key?(:id)
      super(args)
    end
        
    def groups
      return [] if @id.include?("0000000")
      @group_ids.split(',').inject(Array.new) { |res, n_id| res << Ecore::Group.find_readonly(:id => n_id ) ; res }
    end
    
    def online?
      last_request_at and (last_request_at > Time.now - 240)
    end
    
    def suspended?
      suspended
    end
    
    def enabled?
      !suspended
    end
    
    def is_admin?
      role == "manager"
    end
    
    def add_group( group )
      raise SecurityTransgression.new("not a group object") unless group.is_a?(Ecore::Group)
      Ecore::log.info "adding group #{group.name} to user #{self.name}"
      tmp_groups = @group_ids.split(',')
      tmp_groups.delete( group.id )
      tmp_groups << group.id
      @group_ids = tmp_groups.join(',')
    end
    
    def remove_group( group )
      raise SecurityTransgression.new("not a group object") unless group.is_a?(Ecore::Group)
      Ecore::log.info "removing group #{group.name} from user #{self.name}"
      tmp_groups = @group_ids.split(',')
      tmp_groups.delete( group.id )
      @group_ids = tmp_groups.join(',')
    end
      
    private
    
    def hash_password
      return if @password.nil? or @password.empty?
      @hashed_password = self.class.encrypt_password(@password)
      @password = nil
    end
    
    def setup_user_as_its_own_owner
      sessions = Ecore::ENV[:sessions]
      Ecore::ENV[:sessions] = false
      self.acl << { :user => self, :privileges => 'rwsd' }
      save
      Ecore::ENV[:sessions] = sessions
    end
    
    def check_and_setup_password
      if @password.nil? or @password.empty?
        @hashed_password = self.class.encrypt_password(Time.now.to_s)
        @confirmation_key = @hashed_password.to_s
      end
    end
    
  end
  
end
