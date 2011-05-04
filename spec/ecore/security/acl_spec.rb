require ::File::expand_path( "../../../spec_helper", __FILE__ )

describe "Ecore::Node permissions (acl)" do

  before(:all) do
    cleanup
    Ecore::Node.find( nil, :all ).each { |u| u.delete(:forever => true) }
    Ecore::User.create( nil, :name => 'henry', :password => 'england' )
    Ecore::User.create( nil, :name => 'george', :password => 'scotland' )
    (0..3).each { |i| TestEvent.create( nil, :name => "test#{i}" ) }
    Ecore::ENV[:sessions] = true
    @session = Ecore::Session.new( :name => 'henry', :password => 'england' )
    @george = Ecore::Session.new(:name => 'george', :password => 'scotland' ).user
    @henry = @session.user
    @te = TestEvent.create( @session, :name => 'test event' )
  end
  
  after(:all) do
    Ecore::ENV[:sessions] = false
  end

  it "should create a node and keep privileges for creator" do
    te = TestEvent.create( @session, :name => 'henrys test event' )
    te.can_read?.should == true
  end
  
  it "should find that node with the creator user (henry)" do
    te = TestEvent.find( @session, :name => 'henrys test event')
    te.size.should == 1
    te.first.name.should == 'henrys test event'
  end

  it "should grant deleting that previously created node" do
    te = TestEvent.find( @session, :name => 'henrys test event')
    te.first.delete.should == true
    TestEvent.find( @session, :name => 'henrys test event').should == []
  end
  
  it "should find all nodes" do
    Ecore::ENV[:sessions] = false
    Ecore::Node.find( nil, :all ).size.should == 5
    Ecore::ENV[:sessions] = true
  end
  
  it "should find all user's nodes" do
    Ecore::Node.find(@session, :all).size.should == 1
    te = TestEvent.create( @session, :name => 'testevent' )
    Ecore::Node.find(@session, :all).size.should == 2
  end
  
  it "should not share a node with another user after creation" do
    oldsize = Ecore::Node.find(@george.session, :all).size
    Ecore::Node.create(@session, :name => 'notshare')
    Ecore::Node.find(@george.session, :name => 'notshare').size.should == 0
    Ecore::Node.find(@george.session, :all).size.should == oldsize
  end

  it "should share a node with another user" do
    @te.acl.can_read?( @george ).should == false
    @te.share( @george, 'r' )
    @te.save.should == true
    @te.can_read?( @george ).should == true
  end
  
  it "should deny saving a node" do
    session = Ecore::Session.new( :name => 'george', :password => 'scotland' )
    te = Ecore::Node.find(session, :name => 'test event' ).first
    te.name = 'other'
    lambda{ te.save }.should raise_error(Ecore::SecurityTransgression)
  end
  
  it "should deny deleting a node" do
    session = Ecore::Session.new( :name => 'george', :password => 'scotland' )
    te = Ecore::Node.find(session, :name => 'test event' ).first
    lambda{ te.delete }.should raise_error(Ecore::SecurityTransgression)
  end
  
  it "should inherit node's acls" do
    @te.acl.can_read?( @george ).should == true
    te2 = TestEvent.create( @session, :name => 'subnode of testevent' )
    te2.can_read?( @george ).should == false
    te2.add_label( @te )
    te2.save
    te2.can_read?( @george ).should == true
  end
  
  it "should list effective acls for this node" do
    te2 = TestEvent.create( @session, :name => 'subnode of testevent' )
    te2.add_label( @te )
    te2.save
    te2.effective_acl.keys.sort.should == [@henry.id,@george.id].sort
  end
  
  it "should share a node with User anobody" do
    @te.acl.can_read?( Ecore::User.anybody ).should == false
    @te.share( Ecore::User.anybody, 'r' )
    @te.save.should == true
    @te.acl.can_read?( Ecore::User.anybody ).should == true
  end
  
  it "should not allow sharing with User anybody if permissions > read_only" do
    lambda { @te.share( Ecore::User.anybody, 'rw' ) }.should raise_error( Ecore::PrivilegesTransgression )
  end
  
  it "should remove a granted user from acl" do
    @te.share( Ecore::User.anybody, 'r' )
    @te.save.should == true
    @te.acl.include?( Ecore::User.anybody.id ).should == true
    @te.unshare( Ecore::User.anybody )
    @te.acl.include?( Ecore::User.anybody.id ).should == false
  end
  
  it "should override a user's privileges if user is already defined in node's acl" do
    @te.share( @george, 'r' )
    @te.save.should == true
    @te.acl.size.should == 2
    @te.can_read?( @george ).should == true
    @te.acl.can_write?( @george ).should == false
    @te.share( @george, 'rw' )
    @te.save.should == true
    @te.acl.size.should == 2
    @te.acl.can_write?( @george ).should == true
  end
  
  it "should grant privileges to george, if anybody has read access" do
    @te.unshare( @george )
    @te.save
    TestEvent.find(@george.session, :id => @te.id).should == nil
    @te.share( Ecore::User.anybody, 'r' )
    @te.save.should == true
    TestEvent.find(@george.session, :id => @te.id).class.should == TestEvent
  end
  
  it "should find a node with user anybody" do
    node = TestEvent.create(@session, :name => 'anybody node')
    node.share( Ecore::User.anybody, 'r')
    node.save
    tes = TestEvent.find(Ecore::Session.new(:name => 'anybody'), :name => 'anybody node')
    tes.size.should == 1
    tes.first.id.should == node.id
  end
  
end
