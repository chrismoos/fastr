module Fastr
  module Deferrable
    def defer_response(code, headers, &block)
      response = DeferrableResponse.new
      
      EM.next_tick do
        env['async.callback'].call([code, headers, response])
        block.call(response)
      end
      
      [-1, {}, []].freeze
    end
  end
  
  class DeferrableResponse
    include EventMachine::Deferrable
    
    def send_data(data)
      @callback.call(data)
    end
    
    def task(operation, callback)
      EM.defer(operation, callback)
    end
    
    def closed(&cb)
      self.errback(&cb)
    end
    
    def finish
      self.succeed
    end
    
    def each(&cb)
      @callback = cb
    end
  end
end