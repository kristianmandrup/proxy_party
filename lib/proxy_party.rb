require 'sugar-high/array'
require 'sugar-high/kind_of'
require 'sugar-high/arguments'

module Party
  module Proxy  

    class Factory
      
      def initialize klass
        @klass = klass
      end
      
      def create
        @klass.new
      end
    end

    def self.included(base)
      base.extend ClassMethods
      base.send :include, InstanceMethods
    end

    module InstanceMethods
      attr_accessor :proxy_factories

      def proxy_factory
        proxy_factories
      end

      def add_proxy_factories hash
        hash.each_pair do |name, factory| 
          factory = if factory.kind_of?(Class) 
            Party::Proxy::Factory.new(factory) 
          else
            raise ArgumentError, "Factory must be a Class or have a #create method: #{factory}" if !factory.respond_to? create
            factory
          end
          self.proxy_factories ||= {}
          self.proxy_factories.merge!(name.to_sym => factory) if name.kind_of_label? 
        end
      end
      alias_method :add_proxy_factory, :add_proxy_factories
      
      def proxy_for obj, *methods
        check = last_arg_value({:check => false}, methods)
        methods.to_symbols.flat_uniq.each do |meth|       
          if check
            raise ArgumentError, "No such object to proxy #{obj}" if !self.respond_to?(obj)
            raise ArgumentError, "No such method to proxy for #{obj}" if !self.send(obj).respond_to?(meth)
          end
          instance_eval %{
          class << self
            define_method :#{meth} do
              #{obj}.send(:#{meth}) if #{obj}
            end
          end
          }
        end
      end
      
      def proxy_accessors_for obj, *methods
        proxy_for obj, methods
        check = last_arg_value({:check => false}, methods)
        methods.to_symbols.flat_uniq.each do |meth|
          if check
            raise ArgumentError, "No such object to proxy #{obj}" if !self.respond_to?(obj)
            raise ArgumentError, "No such method #{meth} to proxy for #{obj}" if !self.send(obj).respond_to?(:"#{meth}=")
          end
          instance_eval %{
          class << self
            define_method :#{meth}= do |arg|
              self.#{obj} ||= proxy_factory[:#{obj}].create if !#{obj} && proxy_factory
              #{obj}.send(:#{meth}=, arg) if #{obj}
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
            send(obj).send(name) if send(obj)
          end
        end
      end

      def proxy_accessors_for obj, *methods
        proxy_for obj, methods
        methods.flat_uniq.each do |meth|
          name = meth.to_sym
          define_method name do |arg|
            obj.send("#{name}=", arg) if send(obj)
          end
        end
      end
    end

    # proxy to state
    def method_missing(name, *args, &block) 
      self.class.proxies.each do |proxi|
        proxy_obj = self.send proxi
        return proxy_obj.send(name, *args, &block) if proxy_obj.respond_to? :"#{name}"
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