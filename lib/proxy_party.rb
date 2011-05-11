require 'sugar-high/array'
require 'sugar-high/kind_of'
require 'sugar-high/arguments'

module Party
  module Proxy
    class Factory
      attr_reader :create_method, :klass
      
      def initialize klass, create_method = nil
        @klass = klass
        @create_method = create_method
      end
      
      def create
        create_method ? klass.send(create_method) : klass.new
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
            case factory
            when Array
              fac = factory.first
              meth = factory.last if factory.size == 2
              raise ArgumentError, "Factory must be a Class, was #{fac}" if !fac.kind_of?(Class) 
              raise ArgumentError, "Factory method be a label, was #{meth}" if meth && !meth.kind_of_label?
              Party::Proxy::Factory.new(fac, meth)
            else
              raise ArgumentError, "Factory must be a Class or have a #create method: #{factory}" if !factory.respond_to?(:create)
              factory
            end
          end
          self.proxy_factories ||= {}
          self.proxy_factories.merge!(name.to_sym => factory) if name.kind_of_label? 
        end
      end
      alias_method :add_proxy_factory, :add_proxy_factories

      # Add instance proxy methods      
      def proxy_for obj, *methods
        check   = last_arg_value({:check => false}, methods)
        rename_methods = last_arg_value({:rename => {}}, methods)
        methods.delete(:rename) if rename_methods

        methods.to_symbols.flat_uniq.each do |meth|
          if check
            raise ArgumentError, "No such object to proxy #{obj}" if !self.respond_to?(obj)
            raise ArgumentError, "No such method to proxy for #{obj}" if !self.send(obj).respond_to?(meth)
          end
          class_eval %{
            define_method :#{meth} do
              #{obj}.send(:#{meth}) if #{obj}
            end
          }
        end
        
        rename_methods.each_pair do |meth, new_meth|
          if check
            raise ArgumentError, "No such object to proxy #{obj}" if !self.respond_to?(obj)
            raise ArgumentError, "No such method to proxy for #{obj}" if !self.send(obj).respond_to?(meth)
          end
          class_eval %{
            define_method :#{new_meth} do
              #{obj}.send(:#{meth}) if #{obj}
            end
          }
        end
      end

      # Add instance proxy methods
      def proxy_accessors_for obj, *methods
        proxy_for obj, methods
        check = last_arg_value({:check => false}, methods)
        rename_methods = last_arg_value({:rename => {}}, methods)
        methods.delete(:rename) if rename_methods

        methods.to_symbols.flat_uniq.each do |meth|
          if check
            raise ArgumentError, "No such object to proxy #{obj}" if !self.respond_to?(obj)
            raise ArgumentError, "No such method #{meth} to proxy for #{obj}" if !self.send(obj).respond_to?(:"#{meth}=")
          end
          class_eval %{
            define_method :#{meth}= do |arg|
              self.#{obj} ||= create_in_factory(:#{obj})
              self.#{obj} ||= self.class.send(:create_in_factory, :#{obj})
              #{obj}.send(:#{meth}=, arg) if #{obj}
            end
          }
        end

        def proxy_accessor_for obj, method = nil
          method ||= obj[1] if obj.kind_of?(Hash)
          raise ArgumentError, "Takes only a single accessor to proxy" if method.kind_of? Array
          proxy_accessor_for obj, [method].flatten
        end

        rename_methods.each_pair do |meth, new_meth|
          if check
            raise ArgumentError, "No such object to proxy #{obj}" if !self.respond_to?(obj)
            raise ArgumentError, "No such method #{meth} to proxy for #{obj}" if !self.send(obj).respond_to?(:"#{meth}=")
          end
          class_eval %{
            define_method :#{new_meth}= do |arg|
              self.#{obj} ||= create_in_factory(:#{obj})
              self.#{obj} ||= self.class.send(:create_in_factory, :#{obj})
              #{obj}.send(:#{meth}=, arg) if #{obj}
            end
          }
        end
      end 

      # Add proxy methods only to the instance object
      def instance_proxy_for obj, *methods
        check = last_arg_value({:check => false}, methods) 
        rename_methods = last_arg_value({:rename => {}}, methods)
        methods.delete(:rename) if rename_methods
        
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
        
        rename_methods.each_pair do |meth, new_meth|
          if check
            raise ArgumentError, "No such object to proxy #{obj}" if !self.respond_to?(obj)
            raise ArgumentError, "No such method to proxy for #{obj}" if !self.send(obj).respond_to?(meth)
          end
          instance_eval %{
          class << self
            define_method :#{new_meth} do
              #{obj}.send(:#{meth}) if #{obj}
            end
          end
          }
        end        
      end

      # Add proxy methods only to the instance object      
      def instance_proxy_accessors_for obj, *methods
        instance_proxy_for obj, methods
        check = last_arg_value({:check => false}, methods)

        rename_methods = last_arg_value({:rename => {}}, methods)
        methods.delete(:rename) if rename_methods
        
        methods.to_symbols.flat_uniq.each do |meth|
          if check
            raise ArgumentError, "No such object to proxy #{obj}" if !self.respond_to?(obj)
            raise ArgumentError, "No such method #{meth} to proxy for #{obj}" if !self.send(obj).respond_to?(:"#{meth}=")
          end
          instance_eval %{
          class << self
            define_method :#{meth}= do |arg|
              self.#{obj} ||= create_in_factory(:#{obj})
              self.#{obj} ||= self.class.send(:create_in_factory, :#{obj})
              #{obj}.send(:#{meth}=, arg) if #{obj}
            end
          end
          }
        end 

        rename_methods.each_pair do |meth, new_meth|
          if check
            raise ArgumentError, "No such object to proxy #{obj}" if !self.respond_to?(obj)
            raise ArgumentError, "No such method to proxy for #{obj}" if !self.send(obj).respond_to?(meth)
          end
          instance_eval %{
            class << self
              define_method :#{new_meth}= do |arg|
                self.#{obj} ||= create_in_factory(:#{obj})
                self.#{obj} ||= self.class.send(:create_in_factory, :#{obj})
                #{obj}.send(:#{meth}=, arg) if #{obj}
              end
            end
          }
        end
      end 

      def instance_proxy_accessor_for obj, method = nil
        method ||= obj[1] if obj.kind_of?(Hash)
        raise ArgumentError, "Takes only a single accessor to proxy" if method.kind_of? Array
        instance_proxy_accessors_for obj, [method].flatten
      end

      def named_proxies hash
        raise ArgumentError, "Argument must be a hash" if !hash.kind_of? Hash
        self.class.send :include, Party::Proxy
        hash.each_pair do |proxy, methods|
          instance_proxy_accessors_for proxy, methods
        end
      end
      
      protected
      
      def create_in_factory name
        raise ArgumentError, "Factory name must be a label, was #{name}" if !name.kind_of_label? 
        proxy_factory[name].create if !send(name) && proxy_factory && proxy_factory[name]
      end      
    end

    # Define class methods here.
    module ClassMethods
      attr_accessor :proxies
      attr_accessor :proxy_factories

      def proxy_factory
        proxy_factories
      end

      def remove_proxy_factory name
        @proxy_factories[name] = nil
      end

      def remove_proxy_factories
        self.proxy_factories = nil
      end

      def add_proxy_factories hash
        hash.each_pair do |name, factory| 
          factory = if factory.kind_of?(Class) 
            Party::Proxy::Factory.new(factory) 
          else
            case factory
            when Array
              fac = factory.first
              meth = factory.last if factory.size == 2
              raise ArgumentError, "Factory must be a Class, was #{fac}" if !fac.kind_of?(Class) 
              raise ArgumentError, "Factory method be a label, was #{meth}" if meth && !meth.kind_of_label?
              Party::Proxy::Factory.new(fac, meth)
            else
              raise ArgumentError, "Factory must be a Class or have a #create method: #{factory}" if !factory.respond_to?(:create)
              factory
            end
          end
          self.proxy_factories ||= {}
          self.proxy_factories.merge!(name.to_sym => factory) if name.kind_of_label? 
        end
      end
      alias_method :add_proxy_factory, :add_proxy_factories


      def remove_proxy name
        proxies.delete(name)
      end
      
      def proxy_for obj, *methods
        rename_methods = last_arg_value({:rename => {}}, methods)
        methods.delete(:rename) if rename_methods
        
        methods.flat_uniq.each do |meth|
          name = meth.to_sym
          define_method name do
            send(obj).send(name) if send(obj)
          end
        end

        rename_methods.each_pair do |meth, new_meth|
          name = meth.to_sym
          define_method new_meth.to_sym do
            send(obj).send(name) if send(obj)
          end
        end
      end

      def proxy_accessors_for obj, *methods
        proxy_for obj, methods
        
        rename_methods = last_arg_value({:rename => {}}, methods)
        methods.delete(:rename) if rename_methods
        
        methods.flat_uniq.each do |meth|
          name = meth.to_sym
          obj_name = obj.to_sym
          define_method name do |arg|
            send(obj_name).send('||=', create_in_factory(obj_name))
            send(obj_name).send("#{name}=", arg) if send(obj)
          end
        end

        rename_methods.each_pair do |meth, new_meth|
          name = meth.to_sym
          obj_name = obj.to_sym
          define_method new_meth.to_sym do |arg|
            send(obj_name).send('||=', create_in_factory(obj_name))
            send(obj_name).send("#{name}=", arg) if send(obj)
          end
        end
      end

      def proxy_accessor_for obj, method = nil
        method ||= obj[1] if obj.kind_of?(Hash)
        raise ArgumentError, "Takes only a single accessor to proxy" if method.kind_of? Array
        proxy_accessors_for obj, [method].flatten
      end

      protected
      
      def create_in_factory name
        proxy_factory[name].create if proxy_factory && proxy_factory[name]
      end
    end

    # proxy to state
    def method_missing(name, *args, &block) 
      return if !self.class.proxies
      self.class.proxies.each do |proxi|
        proxy_obj = self.send proxi
        return proxy_obj.send(name, *args, &block) if proxy_obj.respond_to? :"#{name}"
      end
      super
    end      
  end
end

class Module
  def party_proxy
    include Party::Proxy    
  end
  alias_method :proxy_party, :party_proxy
  
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