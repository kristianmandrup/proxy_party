require 'spec_helper'

class State
  attr_accessor :name
  
  def initialize name = nil
    @name = name    
  end  
end  

class Info
  attr_accessor :text
  
  def initialize text = nil
    @text = text    
  end  
end  

class Mic
  attr_accessor :speak
  
  def initialize text = nil
    @speak = text    
  end  
  
  def speak_it!
    speak
  end
end  



module Party 
  class Subject
    attr_accessor :mic
    
    proxy :state, :info
    
    def initialize name = nil
      @state = State.new name
      @info = Info.new 'hello'      
    end
  end
end

module PartyModule
  party_proxy
end

class PartyClass
  proxy_party
end



describe Party::Proxy do
  describe '#party_proxy' do
    it "Should add party proxy to Module" do
      PartyModule.methods.grep(/proxy_for/).should_not be_empty
    end

    it "Should add party proxy to Class" do
      PartyClass.methods.grep(/proxy_for/).should_not be_empty
    end
  end
  
  describe '#proxy' do
    it "proxies state and info so it can call name directly on subject" do
      subject = Party::Subject.new 'kristian'
      subject.name.should == 'kristian'
    end
  end

  describe '#proxy_for' do
    it "proxies speak_it! on mic" do
      subject = Party::Subject.new 'kristian'
      subject.mic = Mic.new 'hello'
      Party::Subject.proxy_for :mic, :speak_it! 

      subject.proxy_for :mic, :speak_it!
      
      subject.speak_it!.should == 'hello'
    end

    it "handles proxy when the proxied object (mic) is nil" do
      subject = Party::Subject.new 'kristian'
      subject.proxy_for :mic, :speak_it!
      subject.speak_it!.should == nil
    end

    it "handles proxy when the proxied object (mic) is set to nil later" do
      subject = Party::Subject.new 'kristian'
      subject.mic = Mic.new 'hello'
      subject.proxy_for :mic, :speak_it!, :check => true
      subject.mic = nil      
      subject.speak_it!.should == nil
    end

    it "errors when proxy when the proxied object (mic) is nil and nil check is on" do
      subject = Party::Subject.new 'kristian'
      subject.mic = nil
      lambda {subject.proxy_for :mic, :speak_it!, :check => true}.should raise_error
    end
  end

  describe '#proxy_accessor_for' do  
    it "proxies speak accessor methods on mic bu can't set accessor since proxy not initialized and no proxy factory defined" do
      subject = Party::Subject.new 'kristian'
      subject.proxy_accessors_for :mic, :speak
      subject.speak = 'do it!'
      subject.speak.should == nil
    end

    it "proxies speak accessor methods on mic and uses factory to create proxy obj if nil on setting value" do
      subject = Party::Subject.new 'kristian'
      subject.add_proxy_factory :mic => Mic 
      subject.proxy_accessors_for :mic, :speak
      subject.speak = 'do it!' 
      subject.speak.should == 'do it!'
    end 
  end

  describe '#named_proxies' do  
    it "proxies select :mic and :state methods" do
      subject = Party::Subject.new 'kristian'
      subject.mic = Mic.new 'hello'
      subject.named_proxies :mic => :speak, :state => :name
      subject.speak = 'do it!'
      subject.speak.should == 'do it!'

      subject.name = 'kris'
      subject.name.should == 'kris'
    end 
  end
end


