module Fastr
  class Controller
    include Fastr::Template
    
    def self.inherited(kls)
      kls.instance_eval('include Fastr::Log')
    end
  end
end