libdir = File::dirname(__FILE__)
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)

require 'ace'

module Ecore

  class PrivilegesTransgression < StandardError
  end
    
  # Access Control list
  # for Ecore::Node
  class Acl < Hash
    
    # adds a given user or user's id address with
    # given privileges to this acl
    # e.g.:
    # acl << karl@localhost.loc, 'rw' # adds user karl@localhost.loc with read/write
    #                                 # permissions to this acl
    # acl << user, 'rwsd'        # adds user object 
    def <<(options)
      user, privileges = options[:user], options[:privileges]
      raise PrivilegesTransgression.new("anybody can't get more than write permissions") if user.id == User::anybody.id and privileges != 'r'
      self[user.id] = Ace.new(:user_id => user.id, :privileges => privileges)
    end
    alias_method :push, :<<
    
    # returns true or false if given user or given user's id
    # address can read within this acl
    def can_read?(user)
      raise TypeError.new('no user was given, when asking for read permissions') if user.nil?
      return true if ((has_key?(User.anybody.id) and self[User.anybody.id].can_read?))
      return true if ((has_key?(User.everybody.id) and self[User.everybody.id].can_read?) and not user.nil?)
      return true if ((has_key?(user.id) and self[user.id].can_read?))
      user.groups.each do |group|
        return true if can_read?(group)
      end if user.is_a?(Ecore::User)
      false
    end
    
    # returns true or false if given user or given user's id
    # address can write within this acl
    def can_write?(user)
      return true if (has_key?(user.id) and self[user.id].can_write?)
      user.groups.each do |group|
        return true if can_write?(group)
      end if user.is_a?(Ecore::User)
      false
    end
    
    # returns true or false if given user or given user's id
    # address can share (manage acls) within this acl
    def can_share?(user)
      return true if (has_key?(user.id) and self[user.id].can_share?)
      user.groups.each do |group|
        return true if can_share?(group)
      end if user.is_a?(Ecore::User)
      false
    end
    
    # returns true or false if given user or given user's id
    # address can delete this acl holding node
    def can_delete?(user)
      return true if (has_key?(user.id) and self[user.id].can_delete?)
      user.groups.each do |group|
        return true if can_delete?(group)
      end if user.is_a?(Ecore::User)
      false
    end
    
  end
  
    
  # Node instance methods for acl simplification
  module AclSimplifications
    
    # returns privileges for current node's session
    def privileges
      eff_acl = effective_acl
      if eff_acl[@session.user.id]
        return eff_acl[@session.user.id].privileges
      end
      @session.user.group_ids.split(',').each do |group_id|
        return eff_acl[group_id].privileges if eff_acl[group_id]
      end
      return eff_acl[Ecore::User.everybody.id].privileges if eff_acl[Ecore::User.everybody.id]
      return eff_acl[Ecore::User.anybody.id].privileges if eff_acl[Ecore::User.anybody.id]
      []
    end
    
    # checks, if given user has read access for this
    # node or for parent node
    def can_read?(user=nil)
      return true unless Ecore::ENV[:sessions]
      user = @session.user if @session and user.nil?
      return false unless user
      effective_acl.can_read?(user)
    end
    
    # returns effective acl also considering parent nodes
    def effective_acl(parsed_labels=[])
      a = labels.inject(Acl.new) do |res, label| 
        unless labels.include?(label.id)
          res.merge!(label.effective_acl(parsed_labels << @id))
        end
        res
      end
      acl.nil? ? a : a.merge(acl)
    end
    
    # alias for acl.can_write?(@session.user)
    def can_write?(user=@session.user)
      effective_acl.can_write?(user)
    end
    
    # alias for acl.can_share?(@session.user)
    def can_share?(user=@session.user)
      effective_acl.can_share?(user)
    end
    
    # alias for acl.can_delete?(@session.user)
    def can_delete?(user=@session.user)
      effective_acl.can_delete?(user)
    end
    
    # shares current node with user and provides access given as
    # privileges
    # e.g.:
    # node.share( user, 'rw' )
    def share( user, privileges )
      self.acl << { :user => user, :privileges => privileges } if user.is_a?(Ecore::User) or user.is_a?(Ecore::Group)
    end
    
    # removes user from current node acls
    def unshare( user )
      self.acl.delete(user.id) if ( user.is_a?(Ecore::User) or user.is_a?(Ecore::Group) ) and acl.has_key?( user.id )
    end
    
  end
  
end
