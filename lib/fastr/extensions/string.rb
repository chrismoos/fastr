class String
  def camelcase
    split = self.split('_')
    newStr = []
    
    split.each { |s| newStr << s.capitalize }
    
    newStr.join('')
  end
end