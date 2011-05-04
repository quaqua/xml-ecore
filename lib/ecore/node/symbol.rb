class Symbol
  
  def contains
    "#{self}__contains".to_sym
  end
  
  def contains_ci
    "#{self}__contains_ci".to_sym
  end
  
  def gt
    "#{self}__gt".to_sym
  end
  alias_method :greater_than, :gt
  
  def ge
    "#{self}__ge".to_sym
  end
  alias_method :greater_equal, :ge
  
  def lt
    "#{self}__lt".to_sym
  end
  alias_method :less_than, :lt
  
  def le
    "#{self}__le".to_sym
  end
  alias_method :less_equal, :le
  
  def cleanup
    self.to_s.sub('__contains_ci','').sub('__contains','').sub('__gt','').sub('__ge','').sub('__lt','').sub('__le','')
  end
  
end
  
