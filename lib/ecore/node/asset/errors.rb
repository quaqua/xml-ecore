module Ecore

  # raised if an asset was expected, but not given
  class InvalidAssetError < StandardError
  end
  
  #raised if asset carrier (node) has not been saved yet
  class CantSaveAssetBeforeNode < StandardError
  end
  
end
