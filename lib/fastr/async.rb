module Fastr
  module Async
    def async_resp(&blk)
      env['async.callback'].call(blk.call)
    end
  
    def render_async(resp=nil)
      [-1, {}, []].freeze
    end
  end
end