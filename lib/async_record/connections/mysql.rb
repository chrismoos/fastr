require 'em/mysql'

module AsyncRecord
  module Connection    
    class MySQL < AsyncRecord::Connection::Base
      include Fastr::Log
      
      attr_accessor :host
      attr_accessor :port
      attr_accessor :user
      attr_accessor :password
      attr_accessor :database
      attr_accessor :connections
      
      attr_accessor :mysql
      
      # Initializes a MySQL connection
      def initialize(*args)
        args.each do |arg|
          if arg.kind_of? Hash
            arg.each do |k,v|
              self.send("#{k}=", v)
            end
          end
        end
      end
      
      def connect
        settings = {:logging => false, :connections => 4}
        
        settings[:host] = self.host if not self.host.nil?
        settings[:port] = self.port if not self.port.nil?
        settings[:user] = self.user if not self.user.nil?
        settings[:password] = self.password if not self.password.nil?
        settings[:database] = self.database if not self.database.nil?
        settings[:connections] = self.connections if not self.connections.nil?

        EventedMysql.settings.update(settings)
      end
      
      def query(queryStr, &blk)
        EventedMysql.select(queryStr, &blk)
      end
    end
  end
end