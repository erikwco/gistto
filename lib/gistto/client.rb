require 'rubygems'
require 'faraday'
require 'json'
require 'pp'


module Gistto
	# GITHUB AUTHORIZATIONS AND REFERAL LINKS
	GITHUB_API			= 'https://api.github.com/'
	GITHUB_API_AUTH	= 'https://api.github.com/authorizations'


	module Client
		extend self

		# Execute commands from command line pretends to be used adding gist 
		# and uploading to a github/gist account like public or private 
		# depending the command 
		#
		# Author::    Erik Chacon (erikchacon@me.com)
		# Copyright:: Copyright (c) 2013 castivo networks
		# License::   Distributes under the same terms as Ruby
		def run(*args)
			# options vars
			new_config = nil

			# options definitions
			options = {}
			OptionParser.new do |option|
				option.banner = "Usage: gistto [options] [filename or stdin] [filename] .... \n" +
											"-i makes gistto able to read from stdin"

				option.on('-n', '--new config', 'Makes a new user configuration') do |n|
					new_config = n
				end

				option.on('-h','--help','Display help screen') do |h|
					pusts option
					exit
				end

			end



		end


		def install
			
		end

		def config
			
		end


		private

			def connect(username)
				@proxy = proxy = Faraday.new(GITHUB_API, :ssl => { :ca_file => "/opt/local/share/curl/curl-ca-bundle.crt"})
				response = @proxy.get 
				JSON.parse(response.body)
			rescue Exception => e
				e.message
			end


			def auth
				
			end


	end
end