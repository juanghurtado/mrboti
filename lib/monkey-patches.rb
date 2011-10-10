class String
  
  def is_numeric?
    begin Float(self) ; true end rescue false
  end
  
end

class NilClass
  
  def is_numeric?
    return false
  end
  
end