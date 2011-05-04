require ::File::expand_path( "../../spec_helper", __FILE__ )

describe "Ecore::Node" do

  before(:each) do
    cleanup
  end
  
  it "should create a new node" do
    Ecore::Node.new(:name => "test").save(nil).should == true
  end
  
  it "should return if node is a new_node (has been saved yet)" do
    node = Ecore::Node.new(:name => 'test')
    node.new_record?.should == true
    node.save(nil)
    node.new_record?.should == false
  end
  
  it "should create and find a node" do
    Ecore::Node.create(nil, :name => 'test')
    Ecore::Node.find(nil, :name => 'test').first.name.should == 'test'
  end
  
  it "should return if node is persisted? (has been saved to the repos yet)" do
    node = Ecore::Node.new(:name => 'test')
    node.persisted?.should == false
    node.save(nil)
    node.persisted?.should == true
    node.name = "test2"
    node.persisted?.should == false
  end
  
  it "should return persisted? true, if node has been loaded from repos" do
    Ecore::Node.create(nil, :name => 'test')
    node = Ecore::Node.find(nil, :name => 'test').first
    node.persisted?.should == true
  end

  it "should find a previously created node" do
    node = Ecore::Node.create(nil, :name => "test")
    node_res = Ecore::Node.find(nil, :id => node.id)
    node_res.class.should == Ecore::Node
    node_res.name.should == node.name
    node_res.mtime.class.should == Time
    node_res.mtime.to_s.should == node.mtime.to_s
  end
  
  it "should find nodes with name 'test'" do
    node1 = Ecore::Node.create(nil, :name => 'test')
    node2 = Ecore::Node.create(nil, :name => 'test')
    node3 = Ecore::Node.create(nil, :name => 'chronic')
    node_res = Ecore::Node.find(nil, :name => 'test')
    node_res.class.should == Ecore::NodeArray
    node_res.first.id.should == node1.id
    node_res.last.id.should == node2.id
  end
  
  it "should find nodes with name '*test' but not 'chronic'" do
    node1 = Ecore::Node.create(nil, :name => ' this could be a test')
    node2 = Ecore::Node.create(nil, :name => ' with a little test from my friends')
    node3 = Ecore::Node.create(nil, :name => 'chronic')
    node_res = Ecore::Node.find(nil, :name.contains => 'test')
    node_res.size.should == 2
  end
  
  it "should create a node derived from Ecore::Node" do
    te = TestEvent.new(:name => 'test event')
    te.save(nil).should == true
  end
  
  it "should update a node's attributes like with params[:ecore_node]" do
    node = TestEvent.create(nil, :name => 'test event')
    node.persisted?.should == true
    node.name = "test event 2"
    node.persisted?.should == false
    node.save.should == true
    TestEvent.find(nil, :name => 'test event').size.should == 0
    TestEvent.find(nil, :name => 'test event 2').size.should == 1
    node.persisted?.should == true
  end
  
  it "should update a node's attributes with update_attributes method" do
    node = TestEvent.create(nil, :name => 'test event')
    node.update_attributes(:name => 'othername', :starts_at => Time.now).should == true
    TestEvent.find(nil, :name => 'othername').size.should == 1
    TestEvent.find(nil, :name => 'test event').size.should == 0
  end
  
  it "should delete a node (and move it to trashed_nodes.xml" do
    node = TestEvent.create(nil, :name => 'test event')
    TestEvent.find(nil, :name => 'test event').size.should == 1
    node.delete.should == true
    node.deleted?.should == true
    TestEvent.find(nil, :name => 'test event').size.should == 0
  end
  
  it "should destroy (delete) a node by calling hooks before and after performing the action" do
    class TestBeforeDestroyHooks < Ecore::Node
      before :destroy, lambda{ @name = "before" }
    end
    node = TestBeforeDestroyHooks.create(nil, :name => 'test')
    Ecore::Node.find(nil, :name => 'test').size.should == 1
    node.destroy.should == true
    node.deleted?.should == true
    node.name.should == "before"
    Ecore::Node.find(nil, :name => ['test','before']).size.should == 0
  end
  
  it "should destroy (delete) a node and call after hooks" do
    class TestAfterDestroyHooks < Ecore::Node
      after :destroy, lambda{ @name = "after" }
    end
    node = TestAfterDestroyHooks.create(nil, :name => 'test')
    Ecore::Node.find(nil, :name => 'test').size.should == 1
    node.destroy.should == true
    node.name.should == "after"
    Ecore::Node.find(nil, :name => ['test','after']).size.should == 0
  end
  
  it "should restore a deleted node" do
    node = TestEvent.create(nil, :name => 'test event')
    TestEvent.find(nil, :name => 'test event').size.should == 1
    node.delete.should == true
    TestEvent.find(nil, :name => 'test event').size.should == 0
    trashed_node = TestEvent.find(nil, {:name => 'test event'}, :trashed).first
    trashed_node.class.should == TestEvent
    trashed_node.deleted?.should == true
    trashed_node.restore.should == true
    trashed_node.deleted?.should == false
    TestEvent.find(nil, :name => 'test event').size.should == 1
    TestEvent.find(nil, {:name => 'test event'}, :trashed).size.should == 0
  end
  
  it "should find labels and filter them " do
    node = TestEvent.create(nil, :name => 'test event')
    node.add_label( TestEvent.create(nil, :name => 'test') )
    node.add_label( TestEvent.create(nil, :name => 'notest') )
    node.labels.size.should == 2
    node.labels(:name => 'test').size.should == 1
  end
  
end
