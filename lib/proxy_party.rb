module Party
  module Proxy  

    def self.included(base)
      base.extend ClassMethods
    end

    # Define class methods here.
    module ClassMethods      
      attr_accessor :proxies      
    end

    # proxy to state
    def method_missing(name, *args, &block) 
      self.class.proxies.each do |proxi|
        proxy_obj = self.send proxi
        return proxy_obj.send name, *args, &block if proxy_obj.respond_to? :"#{name}"
      end
      super
    end      
  end
end

class Class
  def proxy *proxy_objs    
    include Party::Proxy    

    proxy_objs.each do |proxy_obj|
      attr_accessor proxy_obj
      @proxies ||= []
      @proxies << proxy_obj
    end
  end
end  