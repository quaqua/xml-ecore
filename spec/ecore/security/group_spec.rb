require ::File::expand_path( "../../../spec_helper", __FILE__ )

describe "Ecore::Group" do

  before(:each) do
    Ecore::Group.find( nil, :all ).each { |g| g.delete(:forever => true) }
    @admins = Ecore::Group.create( nil, :name => 'admin' )
    @henry = Ecore::User.create( nil, :name => 'henry', :password => 'england' )
    @session = Ecore::Session.new( :name => 'henry', :password => 'england' )
  end
  
  it "should create a new group" do
    Ecore::Group.create( nil, :name => 'admin' )
    Ecore::Group.find( nil, :name => 'admin' ).size.should == 2
  end
  
  it "should delete a group" do
    admins = Ecore::Group.create( nil, :name => 'admin' )
    Ecore::Group.find( nil, :name => 'admin' ).size.should == 2
    admins.delete(:forever => true )
    Ecore::Group.find( nil, :name => 'admin' ).size.should == 1
  end
  
  it "should add a user to a group" do
    @admins.users.size.should == 0
    @admins.add_user( @henry )
    @admins = Ecore::Group.find(nil, :name => 'admin').first
    @admins.users.size.should == 1
    @admins.users.first.id.should == @henry.id
  end
  
  it "should delete a user from a group" do
    @admins.add_user( @henry )
    @admins.users.size.should == 1
    @admins.remove_user( @henry )
    @admins.users.size.should == 0
  end
  
  it "will not add a user twice" do
    @admins.users.size.should == 0
    @admins.add_user( @henry )
    @admins.users.size.should == 1
    @admins.users.first.id.should == @henry.id
    @admins.add_user( @henry )
    @admins.users.size.should == 1
  end
  
  it "will not add a non User object" do
    lambda { @admins.add_user( Array.new ) }.should raise_error(Ecore::SecurityTransgression)
    @admins.save
  end
  
  it "should return a user's groups" do
    @henry = @session.user
    @henry.groups.should == []
    @admins.add_user( @henry )
    @henry.groups.size.should == 1
    @henry.groups.first.id.should == @admins.id
  end
  
  it "should return a foreign users's groups" do
    george = Ecore::User.create(@session, :name => 'george', :password => 'scotland')
    @admins.add_user( @henry )
    @admins.add_user( george )
    @admins.users.size.should == 2
    george.groups.size.should == 1
  end
  
end
