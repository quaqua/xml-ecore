module Ecore
  class Mutex
  
    @@locked_nodes = Array.new
    
    class << self

      def request_lock(node_id)
        timeout = 100
        while locked?(node_id)
          sleep(0.1) 
          raise MutexRequestTimeout.new if (timeout -= 1) < 1
        end
        lock(node_id)
      end
            
      def locked?(node_id)
        @@locked_nodes.include?(node_id)
      end
      
      def lock(node_id)
        raise AlreadyLockedError.new if locked?(node_id)
        @@locked_nodes << node_id
      end
      
      def release(node_id)
        @@locked_nodes.delete(node_id)
      end
      
    end
    
  end
end
