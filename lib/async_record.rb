module AsyncRecord
  ROOT = File.expand_path(File.dirname(__FILE__))
  
  autoload :Base,               "#{ROOT}/async_record/base"
  autoload :Connection,         "#{ROOT}/async_record/connection"
end