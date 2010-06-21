require 'helper'

class TestCookie < Test::Unit::TestCase
  include Fastr::Cookie
  
  attr_accessor :headers
  
  context "set cookies from controller" do
    setup do
      self.headers = {}
    end
    
    should "add cookie to array if header exists" do
      self.headers["Set-Cookie"] = ['dummycookie']
      set_cookie("key", "value")
      
      assert_equal(2, self.headers['Set-Cookie'].length)
    end
    
    should "put cookie into array if no header exists" do
      set_cookie("key", "value")
      
      assert(self.headers['Set-Cookie'].kind_of? Array)
      assert_equal(1, self.headers['Set-Cookie'].length)
    end
    
    should "set cookie key and value" do
      set_cookie("key", "value")
      
      hdr = self.headers['Set-Cookie']
      
      assert_not_nil(hdr)
      cookie = hdr[0]
      assert_not_nil(cookie)
      assert_equal(1, hdr.length)
      
      assert_equal("key=value;", cookie)
    end
    
    should "add options into cookie" do
      set_cookie("key", "value", {:a => 'b', :c => 'd'})
      
      hdr = self.headers['Set-Cookie'][0]
      assert_equal("key=value; c=d; a=b;", hdr)
    end
    
    should "add expires to cookie with correct format" do
      time = Time.utc(2000, 1, 1, 0, 0, 0)
      
      set_cookie("key", "value", {:expires => time})
      
      hdr = self.headers['Set-Cookie'][0]
      assert_equal("key=value; expires=Sat, 01-Jan-2000 00:00:00 GMT;", hdr)
    end
    
    should "add expires to cookie in utc if time is local" do
      time = Time.utc(2000, 1, 1, 0, 0, 0).getlocal
      
      set_cookie("key", "value", {:expires => time})
      
      hdr = self.headers['Set-Cookie'][0]
      assert_equal("key=value; expires=Sat, 01-Jan-2000 00:00:00 GMT;", hdr)
    end
  end
end