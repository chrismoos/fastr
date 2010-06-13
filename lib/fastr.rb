module Fastr
  ROOT = File.expand_path(File.dirname(__FILE__))
  
  autoload :Application,      "#{ROOT}/fastr/application"
  autoload :Log,              "#{ROOT}/fastr/logger"
  autoload :Router,           "#{ROOT}/fastr/router"
  autoload :Error,            "#{ROOT}/fastr/exception"
  autoload :Controller,       "#{ROOT}/fastr/controller"
  autoload :Template,         "#{ROOT}/fastr/template"
  autoload :Deferrable,       "#{ROOT}/fastr/deferrable"
  autoload :Settings,         "#{ROOT}/fastr/settings"
end