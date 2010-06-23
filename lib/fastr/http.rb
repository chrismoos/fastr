module Fastr
  module HTTP
    
    # Parses the query string.
    #
    # @param qs [String]
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
    
    # Parses the HTTP cookie.
    #
    # @param env [Hash]
    # @return [Hash]
    def self.parse_cookies(env)
      if env.has_key? "HTTP_COOKIE"
        cookies = env['HTTP_COOKIE'].split(';')
        c = {}
        cookies.each do |cookie|
          info = cookie.strip.split("=")
          if info.length == 2
            c[info[0].strip] = info[1].strip 
          end
        end
        c
      else
        {}
      end
    end
  end
end