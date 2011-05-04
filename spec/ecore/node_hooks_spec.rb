require ::File::expand_path( "../../spec_helper", __FILE__ )
  
describe "Ecore::Hooks" do
  
  it "should run before saving node" do
    class TestHookA < Ecore::Node
      string :h
      before :save do
        @h = "before save"
      end
    end
    th = TestHookA.create(nil, :name => 'test')
    th.h.should == "before save"
    th.h = "test"
    th.save
    th.h.should == "before save"
  end
  
  it "should run after saving node" do
    class TestHookB < Ecore::Node
      string :h
      after :save, lambda{ @h = "after save" }
    end
    th = TestHookB.create(nil, :name => 'test')
    th.h.should == "after save"
    th.h = "test"
    th.save
    th.h.should == "after save"
  end
  
  it "should run before creating a node, but not before saving a node" do
    class TestHookC < Ecore::Node
      string :h
      before :create, Proc.new{ @h = "before create" }
    end
    th = TestHookC.create(nil, :name => 'test')
    th.h.should == "before create"
    th.h = "test"
    th.save
    th.h.should == "test"
  end
  
  it "should run after createing a node, but not after saving a node" do
    class TestHookD < Ecore::Node
      string :h
      after :create, :run_after_create
      
      private
      
      def run_after_create
        @h = "after create"
      end
    end
    th = TestHookD.create(nil, :name => 'test')
    th.h.should == "after create"
    th.h = "test"
    th.save
    th.h.should == "test"
  end
  
  it "should run before destroying a node" do
    class TestHookE < Ecore::Node
      string :h
      before :create, lambda{ @h = "before destroy" }
    end
    th = TestHookE.create(nil, :name => 'test')
    th.destroy
    th.deleted?.should == true
    th.h.should == "before destroy"
  end
  
  it "should run after destroying a node" do
    class TestHookE < Ecore::Node
      string :h
      after :destroy, lambda{ @h = "after destroy" }
    end
    th = TestHookE.create(nil, :name => 'test')
    th.destroy
    th.deleted?.should == true
    th.h.should == "after destroy"
  end
  
end
  
