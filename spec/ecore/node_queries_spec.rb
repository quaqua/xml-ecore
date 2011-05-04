require ::File::expand_path( "../../spec_helper", __FILE__ )

describe "Ecore::Node" do

  before(:each) do
    cleanup
  end
  
  it "should only find nodes of type class from which class find method has been invoked" do
    te = TestEvent.create(nil, :name => 'test')
    node = Ecore::Node.create(nil, :name => 'test')
    node_res = TestEvent.find(nil, :name => 'test')
    node_res.size.should == 1
    node_res.first.name.should == 'test'
    node_res.first.class.should == TestEvent
  end
  
  it "should find all nodes (regardless which class) with Ecore::Node.find" do
    te = TestEvent.create(nil, :name => 'test')
    node = Ecore::Node.create(nil, :name => 'test')
    node_res = Ecore::Node.find(nil, :name => 'test')
    node_res.size.should == 2
  end
  
  it "should only find nodes of derived class with :all option" do
    te = TestEvent.create(nil, :name => 'test')
    node = Ecore::Node.create(nil, :name => 'test')
    TestEvent.find(nil, :all).size.should == 1
    Ecore::Node.find(nil, :all).size.should == 2
  end
  
  it "should find a node by comparing ids" do
    test_event_fixtures
    TestEvent.find(nil, :status => 0).first.name.should == "test_status0"
  end
  
  it "should find all nodes with status > 0" do
    test_event_fixtures
    node_res = TestEvent.find(nil, :status.gt => 0)
    node_res.size.should == 2
    node_res.first.name.should == "test_status1"
    node_res.last.name.should == "test_status2"
  end
  
  it "should find all nodes with status >= 0" do
    test_event_fixtures
    node_res = TestEvent.find(nil, :status.ge => 0)
    node_res.size.should == 3
  end
  
  it "should find all nodes with status < 1" do
    test_event_fixtures
    node_res = TestEvent.find(nil, :status.lt => 1)
    node_res.size.should == 1
  end
  
  it "should find all nodes with status <= 1" do
    test_event_fixtures
    node_res = TestEvent.find(nil, :status.le => 1)
    node_res.size.should == 2
  end
  
  it "should find all nodes with status > 1 and name='test'" do
    test_event_fixtures
    TestEvent.create(nil, :name => 'no', :status => 2)
    TestEvent.find(nil, :status.gt => 1).size.should == 2
    TestEvent.find(nil, :status.gt => 1, :name.contains => 'test').size.should == 1
  end
  
  it "should find dates <= Time.now+3600 and >= Time.now-3600" do
    now = test_event_fixtures
    TestEvent.find(nil, :starts_at.ge => now-3600, :ends_at.le => now+3600).size.should == 2
  end
  
  it "should find nodes with name='test' or name='henry'" do
    Ecore::Node.create(nil, :name => 'test')
    Ecore::Node.create(nil, :name => 'henry')
    Ecore::Node.find(nil, :name => ['test','henry']).size.should == 2
  end
  
  it "should find nodes with name contains 'status0','status1' and starts_at < now" do
    now = test_event_fixtures
    TestEvent.find(nil, :name.contains => ['status0','status1'], :starts_at.lt => now).size.should == 1
  end
  
  it "should find nodes with name containing 'status', 'Status', 'STATUS' with :containsCI method" do
    Ecore::Node.create(nil, :name => 'status')
    Ecore::Node.create(nil, :name => 'Status')
    Ecore::Node.create(nil, :name => 'STATUS')
    Ecore::Node.find(nil, :name.contains => 'status').size.should == 1
    Ecore::Node.find(nil, :name.contains_ci => 'status').size.should == 3
  end
  
  it "should define a custom xpath query" do
    now = test_event_fixtures
    Ecore::Node.find(nil, "//nodes/node[(@starts_at >= #{now.to_f}) and (@status > 1)]").size.should == 1
  end
  
  it "should find all nodes and order them by name" do
    now = test_event_fixtures
    nodes = Ecore::Node.find(nil, :all)
    nodes.size.should == 3
    nodes = nodes.order("name DESC")
    nodes.first.name.should == "test_status2"
  end
  
  it "should order date attributes DESC" do
    now = test_event_fixtures
    nodes = Ecore::Node.find(nil, :all)
    nodes = nodes.order("starts_at DESC")
    nodes.first.name.should == "test_status2"
  end
  
  it "should order date attributes ASC" do
    now = test_event_fixtures
    nodes = Ecore::Node.find(nil, :all)
    nodes = nodes.order("starts_at")
    nodes.first.name.should == "test_status0"
  end
  
  it "should order date and name attributes" do
    now = test_event_fixtures
    TestEvent.create(nil, :name => 'test_status00', :starts_at => now+3600)
    nodes = Ecore::Node.find(nil, :all)
    nodes = nodes.order("starts_at DESC, name")
    nodes.size.should == 4
    nodes.first.name.should == "test_status00"
  end
  
end
