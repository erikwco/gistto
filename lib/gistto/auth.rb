
module Gistto

	module Auth
		extend self
		# authorization
		CLIENT_ID, TOKEN = File.open(File.expand.path("~/.gistto-auth")).read.split('\n')
	end
	
end