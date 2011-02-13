require 'spec_helper'

class State
  attr_accessor :name
  
  def initialize(name)
    @name = name    
  end  
end  

class Info
  attr_accessor :text
  
  def initialize(text)
    @text = text    
  end  
end  

class Mic
  attr_accessor :speak
  
  def initialize(text)
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
    
    def initialize(name)
      @state = State.new name
      @info = Info.new 'hello'      
    end
  end
end

describe Party::Proxy do
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
  end

  describe '#proxy_accessor_for' do  
    it "proxies speak accessor methods on mic" do
      subject = Party::Subject.new 'kristian'
      subject.mic = Mic.new 'hello'
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


