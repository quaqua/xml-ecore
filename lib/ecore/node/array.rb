module Ecore
  class NodeArray < Array
    
    def order( order_attrs )
      new_order = self.class.new
      order_attrs.split(',').each do |a|
        clean_a = a.sub(' DESC','').sub(' ASC','')
        next unless self.first.respond_to?(clean_a)
        self.each do |node|
          tmp_order = self.class.new(new_order)
          ( new_order << node ; next ) if node == self.first
          new_order.each_with_index do |n,i|
            if eval("node.#{clean_a} < n.#{clean_a}")
              tmp_order.insert(i,node)
              break
            elsif tmp_order.size-1 == i
              tmp_order << node
              break
            end
          end
          new_order = self.class.new(tmp_order)
        end
        new_order.reverse! if a.include?(' DESC')
      end
      new_order
    end
    
    def to_hash
      self.inject(Array.new) { |array, n| array << n.to_hash ; array }
    end
    
  end
end
