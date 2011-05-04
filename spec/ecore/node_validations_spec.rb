require ::File::expand_path( "../../spec_helper", __FILE__ )
  
describe "Ecore::Validations" do
  
  it "should validate presence of name (by default)" do
    class TestValidation < Ecore::Node
    end
    TestValidation.new.do_validation.should == false
    TestValidation.new( :name => 'testname' ).do_validation.should == true
  end
  
  it "should validate presence of attribute if defined with :presence => true" do
    class TestCustomValidation < Ecore::Node
      boolean :enabled, :presence => true
    end
    TestCustomValidation.new.do_validation.should == false
    TestCustomValidation.new( :enabled => true ).do_validation.should == false
    TestCustomValidation.new( :enabled => true, :name => 'testname' ).do_validation.should == true
  end
  
  it "should return false along with an error message, if validation fails" do
    class TestErrorMessage < Ecore::Node
    end
    testerror = TestErrorMessage.new
    testerror.do_validation
    testerror.errors.should == {:name => ['name is required']}
  end
  
  it "should validate through all Ecore::Node superclasses of current class" do
    class TestOne < Ecore::Node
      string :a1, :required => true
    end
    class TestTestOne < TestOne
      string :b1, :required => true
    end
    testerror = TestTestOne.new
    testerror.do_validation
    testerror.errors.should == {:name => ['name is required']}
    testerrora1 = TestTestOne.new(:name => 'test')
    testerrora1.do_validation
    testerrora1.errors.should == {:a1 => ['a1 is required']}
    testerrora2 = TestTestOne.new(:name => 'test', :a1 => 'test')
    testerrora2.do_validation
    testerrora2.errors.should == {:b1 => ['b1 is required']}
  end
  
end
