require 'spec_helper'

class Module
  include Party::Proxy
end 

class Address
  attr_accessor :street
end

module Proxies      
  # def self.included(base)
  #   base.class_eval do
  #     make_proxy_for :address, :street
  #   end
  # end

  proxy_accessors_for :address, :street
  # make_proxy_accessors_for :address, :street  
end

class Place
  attr_accessor :address
  # include Proxies
  
  def self.inherited(base)    
    puts "Inherited: #{base}"
    base.class_eval do      
      send :include, Proxies
    end
    # puts base.methods.sort
  end  
end

class OtherPlace        
  attr_accessor :address
  
  proxy_accessors_for :address, :street
end

class Pickup
  attr_accessor :address
  
  include Proxies  
end

class Dropoff < Place
end

describe Party::Proxy do
  context 'Dropoff inherits from Place' do
    before do
      @dropoff  = Dropoff.new
      @pickup   = Pickup.new 
      @other    = OtherPlace.new
    end
    
    it 'should add proxies for address' do
      @dropoff.should respond_to :street
      @pickup.should respond_to :street
      @other.should respond_to :street

      @dropoff.should respond_to :street=
      @pickup.should respond_to :street=
      @other.should respond_to :street=
    end
  end
end