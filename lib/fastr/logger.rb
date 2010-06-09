require 'logger'

module Fastr
  module Log   
    def self.included(kls)
      kls.instance_eval do
        @logger = Logger.new(STDOUT)
        @logger.level = Logger::DEBUG
        @logger.formatter = Fastr::Log::Formatter.new(kls)
        
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