require_relative 'version'
require 'rubygems'
require 'faraday'
require 'optparse'
require 'json'
require 'pp'


module Gistto
	# GITHUB AUTHORIZATIONS AND REFERAL LINKS
	GITHUB_API						= 'https://api.github.com/'
	GITHUB_API_AUTH_LINK 	= '/authorizations'
	VALID_METHODS					= ['config','install','add','update','list','delete']


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
			# options definitions and parsing
			options = {}
			oparser = OptionParser.new do |option|
				option.banner = "Usage: gistto [action] [options] [filename or stdin] [filename] .... \n" +
											"action : \n" +
											"\t config \n" +
											"\t add \n" +
											"\t get \n" +
											"\t update \n" +
											"\t list \n" +
											"\t delete \n \n \n" 

				option.on('-n', '--new config', 'Makes a new user configuration') do |n|
					options[:new_config] = n
				end

				option.on('-v', '--version', 'Display Gistto current version') do
					puts Gistto::VERSION
					exit
				end

				option.on('-h','--help','Display help screen') do
					pusts oparser
					exit
				end

			end

			# parsing options
			oparser.parse!(args)

			# validating args if empty exit 
			# todo: what could be a possible default action 
			if args.empty?
				puts oparser
				exit
			end

			# validates params
			if !VALID_METHODS.include?(args[0])
				puts oparser
				exit
			end

			# calling methods 
			method_to_call = Gistto::Client.method(args[0])
			if args.size > 1
				method_to_call.call args.last(args.size - 1) 
			else
				method_to_call.call
			end

			# if (args.size > 1)
			# 	method_to_call.call args.last(args.size - 1) 
			# else
			# 	method_to_call.call 
			# end

			#exit
			# choosing correct function to call
			# if options is not recognized then 
			# shows help
			# case args[0]
			# 	when 'config'
			# 		Gistto::Client::config
			# 	when 'init'
			# 		Gistto::Client::init
			# 	when 'list'
			# 		Gistto::Client::list
			# 	when 'add'
			# 		Gistto::Client::add
			# 	when 'delete'
			# 		Gistto::Client::delete
			# 	when 'update'
			# 		Gistto::Client::update
			# 	when 'install'
			# 		Gistto::Client::install
			# 	else
			# 		puts oparser
			# 		exit
			# end

		end

		# installing method
		def install
			p "install"
		end

		# configuration method
		def config
			# verify configuration file
			if File.exists?('/Users/erikchacon/.gistto')
				puts 	"Config file already exists, well done! \n" +
							"You can now move on and begin to Use Gistto \n" + 
							"please type gistto help to see what can you do !\n\n" 
				#exit
			end 

			# getting github user and password
    	str_user = get_user_from_global
    	if str_user.empty? 
    		puts "Please configure GitHub Account before continue, remember add git config --global user.name"
    		exit
    	end 
    	str_pass = ask_for_password

    	# generate token
    	github_data = get_token_for str_user, str_pass
    	pp github_data
    	# if message is present and error ocurred
    	if github_data.has_key? 'message'
    		puts "\nAn error ocurred connecting with GitHub API to generate access token please try again! \n GitHub Error = #{github_data['message']}"
    		exit 
    	end

    	if github_data.has_key? 'token'
				# creating configuration file 
				File.open('/Users/erikchacon/.gistto', 'w') do |f|
		      f.puts "#{str_user}:#{str_pass}"
		      f.puts "Token:#{github_data['token']}"
		      f.close
				end
				# p File.dirname(__FILE__)
				# p File.expand_path(File.dirname(__FILE__))
				puts "\nConfiguration done! gistto file was created with token #{github_data['token']} \nEnjoy Gistto"
			else

			end

		end

		def init
			p "init"
		end

		def add (*params)
			p "add #{params.length} / #{params[0].length}"
			puts params[0][0]
		end

		def delete
			p "delete"
		end

		def update
			p "update"
		end

		def list
			p "list"
		end


		private

			def get_token_for(username, password)
				conn = Faraday.new(GITHUB_API	, :ssl => { :ca_file => "/opt/local/share/curl/curl-ca-bundle.crt"})
				conn.basic_auth(username, password)
				response = conn.post do |req|
					req.url GITHUB_API_AUTH_LINK
					req.headers['Content-Type'] = 'application/json'
					req.body = '{"note": "gistto", "scopes": ["repo","gist"]}'
				end
				#puts "Connection Status => #{response.status}"
				#puts response.body
				JSON.parse response.body
			end


			def auth
				@proxy = proxy = Faraday.new(GITHUB_API, :ssl => { :ca_file => "/opt/local/share/curl/curl-ca-bundle.crt"})
				response = @proxy.get 
				JSON.parse(response.body)
			rescue Exception => e
				e.message
			end

			def ask_for_password
	    	`stty -echo`
	    	print "Please type your GitHub Account password : "
	    	pass = $stdin.gets.chomp 
	    	`stty echo`
	    	puts ""				
	    	pass
			end

			def get_user_from_global
				%x(git config --global user.name).strip
			end

	end
end