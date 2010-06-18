require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

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


module Party 
  class Subject
    proxy :state, :info
    
    def initialize(name)
      @state = State.new name
      @info = Info.new 'hello'      
    end
  end
end

describe Party::Proxy do
  it "proxies state so it can call name directly on subject" do
    subject = Party::Subject.new 'kristian'
    subject.name.should == 'kristian'
    subject.text.should == 'hello'
  end
end
