require 'rubygems'
require 'faraday'
require 'optparse'
require 'fileutils'
require 'tmpdir'
require 'json'
require 'pp'


module Gistto
	#
	# GITHUB AUTHORIZATIONS, REFERAL LINKS
	# AND VALID METHODS
	# 
	GITHUB_API						= 'https://api.github.com/'
	GITHUB_API_AUTH_LINK 	= '/authorizations'
	GITHUB_API_GIST_LINK	= '/gists'
	VALID_METHODS					= ['config','install','add','update','list','delete','sync']

	# 
	# Clien todo list
	# todo: create new Gist
	# todo: list Gists
	# todo: Delete Gist
	# todo: Sync Gists
	# todo: check certicate on connection    
	#          
	module Client
		extend self

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
		end

		# installing method
		def install
			p File.join(Dir.home,'.gistto')
			p Dir.home
			p "install"
		end

		#
		# configuration method
		# TODO: refactoring config method to separate responsabilities
		#       
		def config
			puts "Please wait while we configure gistto in your Mac :)".cyan
			#
			# verify if configuration file exists : unless if only for degub purpose
			#
			abort Gistto::MSG_CONFIG_EXISTS unless File.exists?(File.join(Dir.home,'.gistto'))

			#
			# validates cert and copy to temp
			#
			unless File.exists?(File.join('/tmp','gistto.cert'))
				FileUtils.cp File.join(File.expand_path('../../../extras', __FILE__),'gistto.crt'), '/tmp'
				abort "Cert File can't be copied to temp dir" unless File.exists?(File.join('/tmp', 'gistto.crt'))
			end
			puts "Security Cert \t\t[%s]" % "Configured".green
			#
			# creating home file 
			#
			FileUtils.mkdir File.join(Dir.home, 'Gistto') unless File.exists?(File.join(Dir.home, 'Gistto'))
			puts "Gistto directory \t[%s]" % "Configured".green

			#
			# getting github user and ask for password if github --global user.name is not configured
			# the password will be asked for typing otherwise aborted
			# 
    	str_user = get_user_from_global
    	if str_user.empty? 
    		# set user name manually?
    		print "git config --global user.name is not configured, do you want to type user name instead ? (y/n)"
    		answer = $stdin.gets.chomp
    		# ask for user
    		str_user = ask_for 'user name' if answer.downcase == 'y'
    		# user still empty?
    		abort "Please configure GitHub Account before continue, remember add git config --global user.name" if str_user.empty?
    	end 
    	#
    	# ask for password
    	# 
    	str_pass = ask_for 'password', true
    	if str_pass.empty? 
    		puts "Password can't be blank, please try again".yellow
    		str_pass = ask_for 'password', true
    		abort "Password can't be blank".red if str_pass.empty?
    	end
    	#
    	# generate token
    	# 
    	github_data = get_token_for str_user, str_pass
    	#
    	# if message is present and error ocurred
    	# 
  		abort "\nAn error ocurred connecting with GitHub API to generate access token please try again! \nGitHub Error = #{github_data['message']}" if github_data.has_key? 'message'
  		puts "Token \t\t\t[%s]" % "Configured".green
  		#
    	# validate if token key exists
    	# 
    	if github_data.has_key? 'token'
				# creating configuration file 
				File.open('/Users/erikchacon/.gistto', 'w') do |f|
		      f.puts "Token:#{github_data['token']}"
		      f.puts "Cert:/temp/gistto.cert"
		      f.puts "Gistto-Home:%s" % File.join(Dir.home, 'Gistto')
		      f.close
				end
				puts "Configuration done! gistto file was created with token : %s \nEnjoy Gistto" % "#{github_data['token']}".cyan
			else
				puts "\nToken could not be generated and stored in gistto configuration file, please try again".yellow
			end
		end 	# config

		def init
			p "init"
		end 	# init

		def add (*params)
			if params.empty?
				puts "add options need files to add if you wanna type directly use option type" 
				exit
			end
			#puts params[0][0]
		end 	# add

		def delete
			p "delete"
		end 	# delete

		def update
			p "update"
		end 	# update

		def list
			p "list"
		end 	# list


		private

			#
			# Make connection to Get Token
			# todo: refactoring to use generic link
			#
			def get_token_for(username, password)
				conn = Faraday.new(GITHUB_API	, :ssl => { :ca_file => "/tmp/gistto.crt"})
				conn.basic_auth(username, password)
				response = conn.post do |req|
					req.url GITHUB_API_AUTH_LINK
					req.headers['Content-Type'] = 'application/json'
					req.body = '{"note": "gistto", "scopes": ["repo","gist"]}'
				end
 				JSON.parse response.body
			end

			#
			# Ask for data that must be introduced by user
			# todo: refactoring for generic questions
			#
			def ask_for(what, hidden= false)
	    	`stty -echo` if hidden
	    	print "Please type your GitHub Account #{what} : "
	    	data = $stdin.gets.chomp 
	    	if hidden
	    		`stty echo` 	
	    		puts ""				
	    	end
	    	data
			end

			def get_user_from_global
				%x(git config --global user.name).strip
			end

	end
end