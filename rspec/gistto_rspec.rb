require 'rspec'
require_relative '../lib/gistto'


describe Gistto do
	context "Connecting whit gist" do
		it "json returned" do
		  data = Gistto::Client.connect "erikwco"
		  data.should be_empty
		end
	end
end


