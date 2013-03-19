require 'rspec'
require_relative '../lib/gistto'

class RSpecGreeter
	def greet
		'Hello RSpec!'
	end
end

describe "RSpec Greeter" do
	it "should say 'Hello Rspec!' when it receives the greet() message" do
	  greeter = RSpecGreeter.new
	  greeting = greeter.greet
	  greeting.should == 'Hello RSpec!'
	end
end
