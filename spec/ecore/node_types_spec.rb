require ::File::expand_path( "../../spec_helper", __FILE__ )

describe "Ecore::Types" do

  it "should define a string" do
    class TestString < Ecore::Node
      string    :testname
    end
    TestString.new( :testname => "test" ).testname.should == "test"
  end

  it "should define a text" do
    class TestText < Ecore::Node
      text    :testtext
    end
    TestText.new( :testtext => "text" ).testtext.should == "text"
  end
  
  it "should define a float" do
    class TestFloat < Ecore::Node
      float     :testfloat
    end
    TestFloat.new( :testfloat => 1.55 ).testfloat.should == 1.55
    TestFloat.new( :testfloat => "12.5" ).testfloat.should == 12.5
    TestFloat.new( :testfloat => 12 ).testfloat.should == 12.0
  end
  
  it "should define an integer" do
    class TestInt < Ecore::Node
      integer   :testint
    end
    TestInt.new( :testint => 1 ).testint.should == 1
    TestInt.new( :testint => "235" ).testint.should == 235
  end
  
  it "should define a time" do
    require 'time'
    class TestTime < Ecore::Node
      time      :testtime
    end
    time = Time.now
    TestTime.new( :testtime => time ).testtime.should == time
    TestTime.new( :testtime => "2010-03-10" ).testtime.should == Time.parse("2010-03-10")
    TestTime.new( :testtime => "2010-05-29 10:30" ).testtime.should == Time.parse("2010-05-29 10:30")
  end
  
  it "should define a boolean" do
    class TestBoolean < Ecore::Node
      boolean   :testboolean
    end
    TestBoolean.new( :testboolean => true ).testboolean.should == true
    TestBoolean.new( :testboolean => "true" ).testboolean.should == true
    TestBoolean.new( :testboolean => "false" ).testboolean.should == false
    TestBoolean.new( :testboolean => "1" ).testboolean.should == true
    TestBoolean.new( :testboolean => "0" ).testboolean.should == false
    TestBoolean.new( :testboolean => 1 ).testboolean.should == true
    TestBoolean.new( :testboolean => 0 ).testboolean.should == false
    TestBoolean.new( :testboolean => false ).testboolean.should == false
  end
  
  it "should define a hidden attribute (used to make Nodes invisible in browser, e.g. User)" do
    class TestUser < Ecore::Node
      hidden    true
    end
    TestUser.new.hidden.should == true
  end
  
end
