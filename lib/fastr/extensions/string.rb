class String
  def camelcase
    split = self.split('_')
    newStr = []
    
    split.each { |s| newStr << s.capitalize }
    
    newStr.join('')
  end
  
  def uncamelcase
    self.gsub(/::/, '/').
      gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
      gsub(/([a-z\d])([A-Z])/,'\1_\2').
      tr("-", "_").
      downcase
  end
end