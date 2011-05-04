require ::File::expand_path( "../../spec_helper", __FILE__ )

describe "Ecore::NodeAsset" do

  before(:each) do
    cleanup
  end
  
  it "should build an asset" do
    asset = Ecore::NodeAsset.new(:name => 'test')
    asset.is_a?(Ecore::NodeAsset).should == true
  end
  
  it "should attach an asset to a node" do
    node = Ecore::Node.new(:name => 'node')
    node.assets.size.should == 0
    node.assets << Ecore::NodeAsset.new(:name => 'asset')
    node.assets.size.should == 1
    node.assets.first.name.should == 'asset'
  end
  
  it "should save an asset, if a node has been saved" do
    node = Ecore::Node.new(:name => 'node')
    node.assets << Ecore::NodeAsset.new(:name => 'asset')
    node.save.should == true
    node.assets.size.should == 1
    node = Ecore::Node.find(nil, :name => 'node').first
    node.assets.size.should == 1
  end
  
  it "should save multiple assets and finds them again" do
    node = Ecore::Node.new(:name => 'node')
    node.assets << Ecore::NodeAsset.new(:name => 'asset')
    node.assets << Ecore::NodeAsset.new(:name => 'asset2')
    node.assets.size.should == 2
    node.save.should == true
    node = Ecore::Node.find(nil, :name => 'node').first
    node.assets.first.name.should == 'asset'
    node.assets.last.name.should == 'asset2'
  end
  
  it "will delete assets along with node removal" do
    node = Ecore::Node.create(nil,:name => 'node')
    node.assets << Ecore::NodeAsset.new(:name => 'asset')
    node.assets << Ecore::NodeAsset.new(:name => 'asset2')
    node.save.should == true
    node.destroy
    Ecore::Node.find(nil, :name => 'node').size.should == 0
    trashed_node = Ecore::Node.find(nil, {:name => 'node'}, :trashed).first
    trashed_node.assets.size.should == 2
  end
  
  it "should find only specific types of assets in a node" do
    class TestAsset < Ecore::NodeAsset
      integer :kilo
    end
    node = Ecore::Node.new(:name => 'node')
    node.assets << TestAsset.new(:name => 'zsset', :kilo => 40)
    node.assets << TestAsset.new(:name => 'asset', :kilo => 22)
    node.assets << Ecore::NodeAsset.new(:name => 'asset2')
    node.save.should == true
    node.assets.size.should == 3
    node.assets(:type => TestAsset).size.should == 2
  end
  
  it "should find specific types with well known search options" do
    class TestAssetA < Ecore::NodeAsset
      integer :kilo
    end
    node = Ecore::Node.create(nil, :name => 'node')
    node.assets << Ecore::NodeAsset.new(:name => 'asset2')
    node.assets << TestAssetA.new(:name => 'zsset', :kilo => 40)
    node.assets << TestAssetA.new(:name => 'asset', :kilo => 22)
    node.assets << TestAssetA.new(:name => 'tomm', :kilo => 22)
    node.save.should == true
    node.assets.size.should == 4
    node.assets(:type => TestAssetA).size.should == 3
    node.assets(:type => TestAssetA, :name.contains => 'sset').size.should == 2
  end
  
  it "should order assets" do
    node = Ecore::Node.new(:name => 'node')
    node.assets << Ecore::NodeAsset.new(:name => 'asset')
    node.assets << Ecore::NodeAsset.new(:name => 'zesset')
    node.assets << Ecore::NodeAsset.new(:name => 'csset')
    node.save.should == true
    order = node.assets.order("name")
    order.first.name.should == "asset"
    order.last.name.should == "zesset"
  end
  
  it "should filter and order assets" do
    node = Ecore::Node.new(:name => 'node')
    node.assets << Ecore::NodeAsset.new(:name => 'asset')
    node.assets << Ecore::NodeAsset.new(:name => 'zesset')
    node.assets << Ecore::NodeAsset.new(:name => 'csset')
    node.save.should == true
    order = node.assets(:name.contains => 'ss').order("name DESC")
    order.first.name.should == "zesset"
    order.last.name.should == "asset"
  end
  
  it "should find current asset's parental node" do
    node = Ecore::Node.new(:name => 'node')
    node.assets << Ecore::NodeAsset.new(:name => 'asset')
    node.save.should == true
    node = Ecore::Node.find(nil, :id => node.id)
    asset = node.assets.first
    node.assets.node_id.should == node.id
    asset.parent_node_id.should == node.id
    asset.node.id.should == node.id
  end
  
end
