require ::File::expand_path( "../../spec_helper", __FILE__ )

describe "Ecore::Auditing" do
  
  before(:all) do
    cleanup
    Ecore::User.create( nil, :name => 'henry', :password => 'england' )
    Ecore::ENV[:sessions] = true
    @session = Ecore::Session.new( :name => 'henry', :password => 'england' )
    @henry = @session.user
  end
  
  after(:all) do
    Ecore::ENV[:sessions] = false
  end
  
  it "should log a node change to the audit log" do
    n = Ecore::Node.create(@session, :name => 'auditing_test')
    t = Ecore::Auditing.tail
    t.size.should == 3
    t.last[:operation].should == 'created'
    t.last[:class_name].should == "Ecore::Node"
    t.last[:time].is_a?(Time).should == true
    t.last[:user_name].should == @henry.name
    t.last[:id].should == n.id  
  end
  
end
