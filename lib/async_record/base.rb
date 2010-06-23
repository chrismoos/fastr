module AsyncRecord
  class Base
    attr_accessor :attributes
    
    DEFAULT_PRIMARY_KEY = "id"
    
    def self.inherited(klass)
      klass.extend(ClassMethods)
      setup_class(klass)
    end
    
    def initialize
      self.attributes = {}
    end
    
    def self.set_connection(conn)
      @conn = conn
    end
    
    def method_missing(method, *args)
      # Try to lookup the property
      return self.attributes[method.to_s] if self.attributes.has_key? method.to_s
      
      super
    end
    
    # Execute a query
    def self.query(queryStr, &blk)
      connection.query(queryStr) do |results|
        blk.call(results)
      end
    end
    
    # Selects all records from the table
    def self.all(options={}, &blk)
      limit = ''
      
      limit = "limit #{options[:limit]}" if options.has_key? :limit
      
      connection.query("select * from #{@table_name} #{limit}") do |results|
        items = []
        
        results.each do |result|
          obj = self.new
          obj.attributes = result
          items << obj
        end
        
        blk.call(items)
      end
    end
    
    # Find by primary key
    def self.find(id, &blk)
      connection.query("select * from #{@table_name} where #{@primary_key} = #{id.to_i}") do |result|
        if result.length == 1
          obj = self.new
          obj.attributes = result[0]
          blk.call(obj)
        else
          blk.call(nil)
        end
      end
    end
    
    # Gets the count of records in the table.
    def self.count(&blk)
      connection.query("select count(*) from #{@table_name}") do |result|
        blk.call(result[0]["count(*)"])
      end
    end
    
    # Returns the current connection for AsyncRecord.
    def self.connection
      AsyncRecord::Base.instance_variable_get(:@conn)
    end
    
    private
    
    def self.setup_class(klass)
      # Set the table name to the lower case version of the class
      klass.send(:set_table_name, klass.to_s.downcase)
      
      # Set the default primary key
      klass.send(:set_primary_key, DEFAULT_PRIMARY_KEY)
    end
    
    module ClassMethods
      def set_table_name(name)
        self.instance_variable_set(:@table_name, name)
      end
      
      def set_primary_key(name)
        self.instance_variable_set(:@primary_key, name)
      end
    end
  end
end