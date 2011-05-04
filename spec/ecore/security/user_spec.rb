require ::File::expand_path( "../../../spec_helper", __FILE__ )

describe "Ecore::User" do

  after(:all) do
    Ecore::ENV[:sessions] = false
  end
  
  before(:each) do
    Ecore::ENV[:sessions] = false
    Ecore::User.find( nil, :all ).each { |u| u.delete(:forever => true) }
    @henry = Ecore::User.create( nil, :name => 'henry', :email => 'henry@localhost.loc', :password => 'england' )
    Ecore::ENV[:sessions] = true
  end
  
  it "should get a session for anybody user" do
    session = Ecore::Session.new(:name => 'anybody')
    session.is_a?(Ecore::Session).should == true
    session.user.id.should == Ecore::User.anybody.id
    session.user.session.should == session
  end
  
  it "should create a new User" do
    Ecore::ENV[:sessions] = false
    Ecore::User.create( nil, :name => 'testuser' )
    Ecore::User.find( nil, :name => 'testuser').size.should == 1
    Ecore::Node.find( nil, :name => 'testuser').size.should == 0
  end
  
  it "should validate the user's email address, if set" do
    Ecore::ENV[:sessions] = false
    u = Ecore::User.new( :name => 'testuser', :email => 'test' )
    u.save.should == false
    u.errors.should == {:email=>["email is not a valid email address"]}
    u.email = "test@localhost.loc"
    u.save.should == true
  end
    
  
  it "should create a crypted password for User" do
    Ecore::ENV[:sessions] = false
    u = Ecore::User.create( nil, :name => 'testuser', :password => 'testpass' )
    require 'digest/sha2'
    u.hashed_password.should == ::Digest::SHA512.hexdigest('testpass')
  end
  
  it "should create a valid session, if name/email and password have been verified" do
    lambda { Ecore::Session.new( :name => 'henry', :password => 'wrong' )}.should raise_error(Ecore::AuthenticationFailed)
    s = Ecore::Session.new( :name => 'henry', :password => 'england' )
    s.is_a?(Ecore::Session).should == true
    s.user.email.should == 'henry@localhost.loc'
    s = Ecore::Session.new( :email => 'henry@localhost.loc', :password => 'england' )
    s.is_a?(Ecore::Session).should == true
    s.user.name.should == 'henry'
    s.user.acl.can_write?(s.user).should == true
  end
  
  it "should not grant access to user" do
    lambda { Ecore::Session.new( :name => 'henry' )}.should raise_error(Ecore::AuthenticationFailed)
    lambda { Ecore::Session.new( :email => 'henry@localhost.loc' )}.should raise_error(Ecore::AuthenticationFailed)
  end
  
  it "should change a users's password" do
    s = Ecore::Session.new( :name => 'henry', :password => 'england' )
    s.user.password = 'different'
    s.user.save
    lambda { Ecore::Session.new( :name => 'henry', :password => 'england' )}.should raise_error(Ecore::AuthenticationFailed)
    s = Ecore::Session.new( :name => 'henry', :password => 'different' )
    s.is_a?(Ecore::Session).should == true
    s.user.name.should == 'henry'
  end

end
