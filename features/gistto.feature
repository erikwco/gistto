Feature: greeter says hello

	In Order to start learning Rspec and Cucumber
	As a reader of the Rspec Book
	I want a greeter to say Hello

	Scenario: greeter says hello
	Given a greeter
	When I send it the greet message
	Then I should see "Hello Cucumber!"