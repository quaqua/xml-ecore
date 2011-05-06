require ::File::expand_path( "../../spec_helper", __FILE__ )

class Worker < Ecore::Node
  labels :company
end

class Company < Ecore::Node
  scope :worker, "Worker"
end
    
describe "Ecore::Label" do
  
  before(:each) do
    cleanup
  end
  
  it "should define a scope for a class (associating with another class)" do
    worker = Worker.create(nil, :name => 'worker1')
    worker.respond_to?(:company_node_ids).should == true
    
    company = Company.create(nil, :name => 'testcompany')
    company.respond_to?(:workers).should == true
    company.workers.size.should == 0
    
    company.add_worker(worker)
    worker.save
    worker.company_node_ids.should == company.id
    
    company.workers.size.should == 1
  end
  
  it "should remove an associated label" do
    worker = Worker.create(nil, :name => 'worker1')
    company = Company.create(nil, :name => 'testcompany')
    company.add_worker(worker)
    worker.save
    company.workers.size.should == 1
    company.remove_worker(worker)
    worker.save
    company.workers.size.should == 0
  end
  
  it "should return workers as an array" do
    worker = Worker.create(nil, :name => 'worker1')
    company = Company.create(nil, :name => 'testcompany')
    worker.add_company(company)
    worker.save
    company.workers.first.id.should == worker.id
  end
  
end
