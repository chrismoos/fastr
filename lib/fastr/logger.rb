require 'logger'

module Fastr
  module Log   
    @log_level = Logger::DEBUG
    @log_location = STDOUT
    @log_classes = []
    
    def self.included(kls)
      level = @log_level
      log_classes = @log_classes
      log_location = @log_location
      
      kls.instance_eval do
        @logger = Fastr::Log.create_logger(log_location, level, kls)
        
        log_classes << @logger
        
        def logger
          @logger
        end
      end
      
      kls.class_eval do
        def log
          self.class.logger
        end
      end
    end
    
    def self.create_logger(location, level, kls)
      logger = Logger.new(location)
      logger.level = level
      logger.formatter = Fastr::Log::Formatter.new(kls)
      logger
    end
    
    def self.level=(level)      
      @log_level = level
      @log_classes.each do |log|
        log.level = level
      end
    end

    class Formatter < Logger::Formatter
      attr_accessor :progname
      
      def initialize(name)
        self.progname = name
      end
      
      
      def call(severity, time, progname, msg)
        puts "[#{severity}] [#{self.progname}]: #{msg}"
      end
    end
  end
end