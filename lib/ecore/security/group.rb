module Ecore

  # A group can collect users so acls can set to group and
  # will match to this list of users
  class Group < Ecore::Node
  
    repos_filename  'groups.xml'
    
    # don't show instances of this class in
    # browser (ommits hidden objects by default)
    hidden true
    
    string  :created_by
    time    :created_at
    
    def users
      Ecore::User.find_readonly(:group_ids.contains => @id)
    end
    
    def add_user( user ) 
      raise SecurityTransgression.new("not a user object") unless user.is_a?(Ecore::User)
      user.add_group( self )
      user.save
    end
    
    # removes given user from this group
    def remove_user( user )
      raise SecurityTransgression.new("not a user object") unless user.is_a?(Ecore::User)
      user.remove_group( self )
      user.save
    end
    
  end
end
