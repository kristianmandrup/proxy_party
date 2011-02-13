require 'sugar-high/array'
require 'sugar-high/kind_of'

module Party
  module Proxy  

    def self.included(base)
      base.extend ClassMethods
      base.send :include, InstanceMethods
    end

    module InstanceMethods
      def proxy_for obj, *methods
        methods.flat_uniq.each do |meth|       
          raise ArgumentError, "No such object to proxy #{obj}" if !self.respond_to?(obj)
          raise ArgumentError, "No such method to proxy for #{obj}" if !self.send(obj).respond_to?(meth)
          instance_eval %{
          class << self
            define_method :#{meth} do
              #{obj}.send :#{meth}
            end
          end
          }
        end
      end
      
      def proxy_accessors_for obj, *methods
        proxy_for obj, methods
        methods.flat_uniq.each do |meth|
          raise ArgumentError, "No such object to proxy #{obj}" if !self.respond_to?(obj)
          raise ArgumentError, "No such method #{meth} to proxy for #{obj}" if !self.send(obj).respond_to?(:"#{meth}=")
          instance_eval %{
          class << self
            define_method :#{meth}= do |arg|
              #{obj}.send :#{meth}=, arg
            end
          end
          }
        end
      end 
      
      def named_proxies hash
        raise ArgumentError, "Argument must be a hash" if !hash.kind_of? Hash
        self.class.send :include, Party::Proxy
        hash.each_pair do |proxy, methods|
          proxy_accessors_for proxy, methods
        end
      end                   
    end

    # Define class methods here.
    module ClassMethods
      attr_accessor :proxies

      def remove_proxy name
        proxies.delete(name)
      end
      
      def proxy_for obj, *methods
        methods.flat_uniq.each do |meth|
          name = meth.to_sym
          define_method name do
            send(obj).send name
          end
        end
      end

      def proxy_accessors_for obj, *methods
        proxy_for obj, methods
        methods.flat_uniq.each do |meth|
          name = meth.to_sym
          define_method name do |arg|
            obj.send "#{name}=", arg
          end
        end
      end
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
  def named_proxies hash
    raise ArgumentError, "Argument must be a hash" if !hash.kind_of? Hash
    include Party::Proxy
    hash.each_pair do |proxy, methods|
      proxy_accessors_for proxy, methods
    end
  end  
  
  def proxy *proxy_objs    
    include Party::Proxy    

    proxy_objs.flat_uniq.each do |proxy_obj|
      raise ArgumentError, "bad proxy object #{proxy_obj}" if !proxy_obj.kind_of_label?
      attr_accessor proxy_obj
      @proxies ||= []
      @proxies << proxy_obj if !@proxies.include? proxy_obj
    end
  end
end  