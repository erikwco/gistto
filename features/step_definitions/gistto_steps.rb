class CucumberGreeter
	def greet
		"Hello Cucumber!"
	end
end

Given /^a greeter$/ do
  @greeter = CucumberGreeter.new
end

When /^I send it the greet message$/ do
  @greeting = @greeter.greet 
end

Then /^I should see "(.*?)"$/ do |greeting|
  @greeting.should == greeting
end