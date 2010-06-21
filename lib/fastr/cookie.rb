module Fastr
  # This module adds helpers for handling cookies.
  #
  # == Setting a cookie
  # 
  #   set_cookie("mycookie", "value", {:expires => Time.now + 3600})
  #
  # @author Chris Moos
  module Cookie
    # Adds a <em>Set-Cookie</em> header in the response.
    # 
    # @param key [String]
    # @param value [String]
    # @options options [Time] :expires The time when the cookie should expire.
    def set_cookie(key, value, options={})
      cookie = ["#{key}=#{value};"]
      
      
      if options.has_key? :expires and options[:expires].kind_of? Time
        options[:expires] = options[:expires].utc.strftime('%a, %d-%b-%Y %H:%M:%S GMT')
      end
      
      options.each do |k,v|
        cookie << "#{k}=#{v.to_s};"
      end

      cookie_val = cookie.join(' ')
      
      if self.headers['Set-Cookie'].nil?
        self.headers['Set-Cookie'] = [cookie_val]
      else
        self.headers['Set-Cookie'] << cookie_val
      end
    end
  end
end