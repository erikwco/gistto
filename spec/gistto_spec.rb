require 'rspec'
require 'gistto'

module Gistto
	describe Client do

			describe "methods verification" do

					it "version should return 0.0.1" do
						VERSION.should == "0.0.1"					  
					end

					it "update should return 'Not implemented yet'" do
						STDOUT.should_receive(:puts).with('Not implemented yet')
					  Client.run('update')
					end

					it "sync should return 'Not implemented yet'" do
						STDOUT.should_receive(:puts).with('Not implemented yet')
					  Client.run('sync')
					end

					it "pull should return 'Not implemented yet'" do
						STDOUT.should_receive(:puts).with('Not implemented yet')
					  Client.run('pull')
					end

					it "not valid method should return 'Not valid'" do
        		lambda {
							STDOUT.should_receive(:puts).with('Not valid method: please run gistto -h')
						  Client.run('myMethod')
			      }.should raise_error SystemExit
					end

			end

	end
end


