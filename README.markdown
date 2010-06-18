# Proxy Party

Greatly facilitates adding proxies through the proxy method_missing pattern

## Install ##

<code>$ gem install party_proxy</code>

## Usage Configuration ##

<code>require 'party_proxy'</code>

## Usage ##

<pre><code>
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
      # proxy state and info objects to make their methods 
      # directly accessible from subject objects
      proxy :state, :info

      def initialize(name)
        @state = State.new name
        @info = Info.new 'hello'      
      end
    end
  end 
  
  subject = Party::Subject.new 'kristian'
  # access 'name' directly through 'state' proxy
  puts subject.name 
  # access 'text' directly through 'info' proxy
  puts subject.text 
  
=> 'kristian'
=> 'hello'  
</code></pre>

## Note on Patches/Pull Requests ##
 
* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a
  future version unintentionally.
* Commit, do not mess with rakefile, version, or history.
  (if you want to have your own version, that is fine but bump version in a commit by itself I can ignore when I pull)
* Send me a pull request. Bonus points for topic branches.

## Copyright ##

Copyright (c) 2010 Kristian Mandrup. See LICENSE for details.
