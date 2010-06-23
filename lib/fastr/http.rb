module Fastr
  module HTTP
    
    # Parses the query string.
    #
    # @param [String]
    # @return [Hash]
    def self.parse_query_string(qs)
      params = {}
      CGI::parse(qs).each do |k,v|
        if v.length == 1
          params[k] = v[0]
        else
          params[k] = v
        end
      end
      return params
    end
    
    def self.method?(env, method)
      return env['REQUEST_METHOD'].downcase.to_sym == method
    end
  end
end