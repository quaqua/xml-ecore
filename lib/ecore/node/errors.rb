module Ecore

	# raised, if attribute is tried to set, which isn't present
	# for this (Node) class
	class UnknownAttributeError < StandardError
	end
	
	# raised, if xml_node or node itself could not be found any more
	# but was there when starting with an operation
	class NodeDisapearedError < StandardError
	end
	
	# raised, in case of a security / permission transgression,
	# e.g. if a user is trying to access an object, he doesn't have
	# privileges on
	class SecurityTransgression < StandardError
	end
	
	# raised, if lock request did not return true after given time
	class MutexRequestTimeout < StandardError
	end
	
	# raised if a lock request occured at the same time but one was first
	class AlreadyLockedError < StandardError
	end
	
	# raised if node is accessed but has never been saved to the database before
	class NotSavedYetError < StandardError
	end
	
end
