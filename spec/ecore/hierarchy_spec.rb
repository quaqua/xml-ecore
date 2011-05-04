require ::File::expand_path( "../../spec_helper", __FILE__ )

describe "Ecore::Node hierarchy" do

  before(:each) do
    cleanup
  end
  
  it "should create a new node and a subnode" do
    main = Ecore::Node.create(nil, :name => "main")
    main.subnodes.size.should == 0
    sub = Ecore::Node.create(nil, :name => "sub of main")
    sub.add_label(main)
    sub.save
    main.subnodes.size.should == 1
  end
  
  it "should add subnodes b,c to a" do
    a = Ecore::Node.create(nil, :name => "a")
    b = Ecore::Node.create(nil, :name => "b")
    c = Ecore::Node.create(nil, :name => "c")
    b.add_label(a)
    b.save
    c.add_label(a)
    c.save
    a.subnodes.size.should == 2
  end
  
  it "should create a a->b->c hierarchy relation" do
    a = Ecore::Node.create(nil, :name => "a")
    a.subnodes.size.should == 0
    b = Ecore::Node.create(nil, :name => "b")
    b.add_label(a)
    b.save
    c = Ecore::Node.create(nil, :name => "c")
    c.add_label(b)
    c.save
    c.labels.first.id.should == b.id
    b.labels.first.id.should == a.id
    a.subnodes.first.id.should == b.id
    b.subnodes.first.id.should == c.id
  end
  
  it "should return all node's ancestors" do
    a = Ecore::Node.create(nil, :name => "a")
    a.subnodes.size.should == 0
    b = Ecore::Node.create(nil, :name => "b")
    b.add_label(a)
    b.save
    c = Ecore::Node.create(nil, :name => "c")
    c.add_label(b)
    c.save
    n = Ecore::Node.find(nil, :id => c.id)
    n.ancestors.map{|a| a.name}.should == ["a","b"]
  end
  
end
