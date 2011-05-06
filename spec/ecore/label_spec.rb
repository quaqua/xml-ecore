require ::File::expand_path( "../../spec_helper", __FILE__ )

class Worker < Ecore::Node
  has_labels :company
end

class Company < Ecore::Node
  scope :worker
end
    
describe "Ecore::Label" do
  
  before(:each) do
    cleanup
    @worker = Worker.create(nil, :name => 'worker1')
    @company = Company.create(nil, :name => 'testcompany')
  end
  
  it "should define a scope for a class (associating with another class)" do
    @worker.respond_to?(:company_node_ids).should == true
    
    @company.respond_to?(:workers).should == true
    @company.workers.size.should == 0
    
    @company.add_worker(@worker)
    @worker.save
    @worker.company_node_ids.should == @company.id
    
    @company.workers.size.should == 1
  end
  
  it "should define cache methods" do
    @company.respond_to?(:clear_workers_cache).should == true
  end
  
  it "should remove an associated label" do
    @company.add_worker(@worker)
    @worker.save
    @company.workers.size.should == 1
    @company.remove_worker(@worker)
    @worker.save
    @company.workers.size.should == 0
  end
  
  it "should return workers as an array" do
    @worker.add_company(@company)
    @worker.save
    @company.workers.first.id.should == @worker.id
  end
  
  it "should return find workers within company without reloading xml" do
    @worker.add_company(@company)
    @worker.save
    worker2 = Worker.create(nil, :name => 'worker2')
    worker2.add_company(@company)
    worker2.save
    @company.workers.size.should == 2
    @company.workers.find(:id => worker2.id).name.should == 'worker2'
  end
  
  it "should also define difficult class names" do
    class TestClassOne < Ecore::Node
      has_labels :test_underscore_class
    end
    
    class TestUnderscoreClass < Ecore::Node
      scope :test_class_one
    end
    
    tco = TestClassOne.create(nil, :name => 'tco')
    tuc = TestUnderscoreClass.create(nil, :name => 'tuc')
    
    tco.add_test_underscore_class(tuc)
    tco.save
    
    tuc.test_class_ones.size.should == 1
  end
  
end
