module Fastr
  ROOT = File.expand_path(File.dirname(__FILE__))
  
  autoload :Application,        "#{ROOT}/fastr/application"
  autoload :Log,             "#{ROOT}/fastr/logger"
  autoload :Router,             "#{ROOT}/fastr/router"
  autoload :Error,          "#{ROOT}/fastr/exception"
end