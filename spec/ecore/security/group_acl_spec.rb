require ::File::expand_path( "../../../spec_helper", __FILE__ )

describe "Ecore::Group permissions (acl)" do

  before(:all) do
  end
  
  before(:each) do
    cleanup
    Ecore::User.create( nil, :name => 'henry', :password => 'england' )
    Ecore::User.create( nil, :name => 'george', :password => 'scotland' )
    @george = Ecore::Session.new(:name => 'george', :password => 'scotland' ).user
    Ecore::ENV[:sessions] = true
    @session = Ecore::Session.new( :name => 'henry', :password => 'england' )
    Ecore::Group.find(@session, :name => 'admin').each { |a| a.delete }
    @henry = @session.user
    TestEvent.find( @session, :all ).each { |a| a.delete }
    @te = TestEvent.create( @session, :name => 'test event' )
    @admins = Ecore::Group.create( @session, :name => 'admin' )
  end
  
  after(:all) do
    Ecore::ENV[:sessions] = false
  end
  
  it "should share a node with a group" do
    @te.can_read?( @admins ).should == false
    @te.share( @admins, 'r' )
    @te.save.should == true
    @te.can_read?( @admins ).should == true
  end
  
  it "should share a node with a group and the underlying user" do
    @te.share( @admins, 'r' )
    @te.save.should == true
    @te.can_read?( @george ).should == false
    @admins.add_user( @george )
    @admins.save(@session)
    @te.can_read?( @admins ).should == true
    @te.can_read?( @george ).should == true
    gte = Ecore::Node.find( @george.session, :name => 'test event').first
    gte.class.should == TestEvent
    gte.name = 'other test event'
    lambda{ gte.save}.should raise_error(Ecore::SecurityTransgression)
  end
  
  it "should share a node with write permissions to group admin" do
    @admins.add_user( @george )
    @admins.save
    @te.can_write?( @admins ).should == false
    @te.share(@admins, 'rws')
    @te.save.should == true
    @te.can_write?( @admins ).should == true
    @te.can_delete?( @admins ).should == false
    @te.can_write?( @george ).should == true
    gte = Ecore::Node.find( @george.session, :name => 'test event').first
    gte.name = 'other test event'
    gte.save.should == true
    gte.can_delete?.should == false
    lambda{ gte.delete }.should raise_error(Ecore::SecurityTransgression)
  end
  
  it "should share a node and all it's subnodes with a group's member" do
    @admins.add_user( @george )
    @admins.save
    TestEvent.find(@session, :all).each { |te| te.delete }
    a = TestEvent.create(@session, :name => 'a')
    b = TestEvent.create(@session, :name => 'b')
    c = TestEvent.create(@session, :name => 'c')
    d = TestEvent.create(@session, :name => 'd')
    b.add_label(a)
    b.save
    c.add_label(a)
    c.save
    d.add_label(c)
    d.save
    TestEvent.find(@george.session, :all).size.should == 0
    c.share(@admins, 'r')
    c.save
    TestEvent.find(@george.session, :all).size.should == 2
  end
  
  
end
