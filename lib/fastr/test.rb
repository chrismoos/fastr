module Fastr
  module Test
    ROOT = File.expand_path(File.dirname(__FILE__))
    
    autoload :Controller,      "#{ROOT}/test/controller"
  end
end