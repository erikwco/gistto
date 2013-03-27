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
	GITHUB_API						= 'https://api.github.com'
	GITHUB_API_AUTH_LINK 	= '/authorizations'
	GITHUB_API_GIST_LINK	= '/gists'
	VALID_METHODS					= ['config','add','list','delete','type','get']
	# 
	# Clien todo list
	# todo: Sync Gists
	# todo: create help options
	#          
	module Client
		extend self

		#
		# instance module variables
		#
		@temporal_token = nil

		def run(*args)
			#
			# options definitions and parsing
			# 
			options = {}
			oparser = OptionParser.new do |option|
				option.banner = "Usage: gistto [action] [options] [filename or stdin] [filename] .... \n" +
											"action : \n" +
											"\t config [-n|--new]\n" +
											"\t add [-p|--private]\n" +
											"\t get \n" +
											"\t list \n" +
											"\t delete \n \n \n" 

				option.on('-n', '--new', 'Makes a new user configuration') do |n|
					options[:new_config] = n
				end

				option.on('-p', '--private', 'Save Gist as private') do |n|
					options[:private] = n
				end

				option.on('-v', '--version', 'Display Gistto current version') do
					puts Gistto::VERSION
					exit
				end

				option.on('-h','--help','Display help screen') do
					puts oparser
					exit
				end

			end

			#
			# parsing options
			# 
			oparser.parse!(args)

			#
			# validating args if empty exit 
			#
			if args.empty?
				puts oparser
				exit
			end

			#
			# validates params
			# 
			#args << options unless options.empty?
			if !VALID_METHODS.include?(args[0])
				puts oparser
				exit
			end

			#
			# calling methods 
			# 
			method_to_call = Gistto::Client.method(args[0])
			if args.size > 1
				method_to_call.call args.last(args.size - 1) 
			else
				method_to_call.call
			end
		end


		#
		#
		# => PRIVATE METHODS
		#
		#
		private

			#
			# configuration method
			# TODO: refactoring config method to separate responsabilities
			# todo: make new configuration with -n parameter
			# todo: handle error
			#       
			def config 
				puts "Please wait while we configure gistto in your Mac :)\n".cyan
				#
				# verify if configuration file exists : unless if only for degub purpose
				#
				#overwrite = has_param params, :new_config
				abort Gistto::MSG_CONFIG_EXISTS if File.exists?(File.join(Dir.home,'.gistto'))
				config_file_path = File.join(Dir.home, '.gistto')
				puts "configuration file \t[%s]" % "#{config_file_path}".cyan
				#
				# validates cert and copy to temp
				#
				path_cert = File.join('/tmp','gistto.crt')
				unless File.exists? path_cert
					FileUtils.cp File.join(File.expand_path('../../../extras', __FILE__),'gistto.crt'), '/tmp'
					abort "Cert File can't be copied to temp dir" unless File.exists? path_cert
				end
				puts "Security Cert \t\t[%s] [%s]" % ["Configured".green, "#{path_cert}".cyan]
				#
				# creating home file 
				#
				home_path = File.join(Dir.home, 'Gistto')
				FileUtils.mkdir home_path unless File.exists? home_path
				puts "Gistto directory \t[%s] [%s]" % ["Configured".green, "#{home_path}".cyan]
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
	    	github_response = get_token_for str_user, str_pass
	    	#abort "\nAn error ocurred getting authorization token with GitHub API [status = %s]" % "#{github_response.status}".red unless github_response.status == 201
	    	#
	    	# if message is present and error ocurred
	    	# 
	    	github_data = JSON.load github_response.body
	  		abort "\nAn error ocurred generating GitHub Token, please try again!\nGitHub Error = %s" % "#{github_data['message']}".red if github_data.has_key? 'message'
	  		puts "Token \t\t\t[%s]" % "Configured".green
	  		#
	    	# validate if token key exists
	    	# 
	    	if github_data.has_key? 'token'
					# creating configuration file 
					File.open(config_file_path , 'w') do |f|
			      f.puts "Token:%s" % "#{github_data['token']}"
			      f.puts "Cert:%s" % "#{path_cert}"
			      f.puts "Gistto-Home:%s" % home_path
			      f.close
					end
					puts "Configuration done!".yellow
					puts "GitHub Token : \t\t[%s] \n\n%s" % ["#{github_data['token']}".green, "enjoy Gistto !!!".green]
				else
					puts "\nToken could not be generated and stored in gistto configuration file, please try again".yellow
				end
			end 	# config

			#
			# add method
			# responsabilities:
			# 	-	validate params if empty exit
			#  	-	validate files in params
			#   	-	file must exists
			#    	- must have content or valid content
			# considerations:
			# 	at this moment if params.size > 1 it will create one gist by param
			#  	maybe in refactoring it will create all the files in on gist
			#   
			# todo: make public or private gist
			#
			def add *params
				# validate params
				abort "add options need files to add if you wanna type directly use option type"  if params.empty?
				# process files
				params[0].each	do |file|
					# exists
					file_path = ((/\//.match(file).size) > 0) ? file : File.join(Dir.pwd, file)
					file_exist = File.exist? file_path
					if file_exist
						file_name =  File.basename file_path
						file_content =  File.read file_path						

						if file_content.empty?
							puts "#{file_path} [%s] [empty]\n" % "skip".red
						else
							#is_private = has_param params, :private
							gist_data =  post_new_gist generate_data "#{file_name}", "#{file_name}", file_content.chomp
							if gist_data.has_key? 'id'
								puts "#{file_path} [%s] [#{gist_data['id']}]\n" % "created".green 
							else
								puts "#{file_path} [%s] [#{gist_data['message']}]\n" % "skip".red
							end
						end

					else
						puts "#{file_path} [%s] [doesn't exists]\n" % "skip".red
					end
				end
			rescue Exception => e
				puts e
			end 	# add

			#
			# type method
			# read from stdin and creates a file
			# the parameter expected are the file-name and description 
			# todo: --save -> to save the typed text to gistto folder
			# todo: refactoring 
			#
			def type *params
				# verify params must be 2 
				abort "type needs two params filename and description [if descriptions contains spaces must be quoted]" unless params[0].length == 2
				filename = params[0][0]
				description = params[0][1]
				# reading from $stdin
				#content = $stdin.read
				
				content = ""
				if $stdin.tty?
					# headers and instructions
					# puts "Remember to finish the typing you must hit CTRL-D [in somecases twice :)]\n"
					puts "Remember to finish the edition please type ::eof"
					puts "please type the content of %s \n" % "#{params[0][0]}".green
					while line = $stdin.gets.chomp
						break if line == "::eof"
						content << line + "\n"
					end
				else
					$stdin.each_line do |line|
						content << line
					end
				end

				# validating content
				abort "the content of the file mustn't be blank" if content.empty?
				#creating file
				#is_private = has_param params, :private
				gist_data =  post_new_gist generate_data "#{filename}", "#{description}", content.chomp
				if gist_data.has_key? 'id'
					puts "\n#{filename} [%s] [#{gist_data['id']}]\n" % "created".green 
				else
					puts "\n#{filename} [%s] [#{gist_data['message']}]\n" % "fail".red\
				end
			rescue Exception => e
				puts e
			end # type

			#
			# get a gist by id
			# todo: open directly to the browser with -o option
			#
			def get id
				gist_response =  get_gists id[0]
				str_code = ""
				if gist_response.status == 200
					gist_data = JSON.load(gist_response.body)
					puts "%s\t\t#{gist_data['description']}" % "#{gist_data['id']}".cyan
					gist_data['files'].map do |name, content|
						puts "\n%s" % name.cyan
						puts content['content']
						str_code << "\n\n****** #{name} *******\n\n"
						str_code << "#{content['content']} \n"
					end
					pbcopy str_code
					puts "\nCode copied to clipboard!" 
				else
					puts "\nOcurred an error getting gist #{id} [%s]\n" % "fail".red
				end
			rescue Exception => e
				puts e
			end # get

			#
			# todo: handle large list of gists for multipage 
			#
			def list
				gist_response =  get_gists
				if gist_response.status == 200
					gist_data = JSON.load gist_response.body
					gist_data.map do |items|
						puts "%s \t\t #{items['description']}" % "#{items['id']}".cyan
						puts "Files :" + items['files'].map {|name, content| "\t#{name}".green }.join(",")
						puts "\n"
					end
				else
					puts "\nOcurred an error getting list of gist[%s]\n" % "fail".red
				end
			rescue Exception => e
				puts e
			end 	# list

			#
			#
			#
			#
			def delete id
				id.each do |gist|
					gist_response = delete_gist gist
					if gist_response.status == 204
						puts "Gist %s deleted ! " % "#{gist}".cyan
					else
						gist_data = JSON.parse gist_response.body
						puts "Gist %s couldn't be deleted [#{gist_data['message']}]" % "#{gist}".red
					end
				end
			rescue Exception => e
				puts e
			end 	# delete

			#
			#
			# uses PATCH method
			#
			#
			def update
				p "update"
			end 	# update

			#
			#
			# https_open_for
			#
			#
			def https_open_for url, mthd, content=nil, username=nil, password=nil
				conn = Faraday.new(GITHUB_API	, :ssl => { :ca_file => check_cert})
				conn.basic_auth username, password unless username.nil? && password.nil?
				response= conn.method(mthd).call do |req|
					req.url url + ((username.nil? && password.nil?) ? "?access_token=%s" % read_token : "" )
					req.headers['Content-Type'] = 'application/json'
					req.body = JSON.generate(content) unless content.nil?
				end
				response
			rescue Exception => e
				raise "An error ocurred trying to open connection with GitHub [%s]" % "#{e}".red
			end # https_open_for

			#
			# Make connection to Get Token
			#
			def get_token_for(username, password)
				url = GITHUB_API_AUTH_LINK 
				scopes = %w[repo gist]
				content = generate_scope "Gistto", scopes
				https_open_for url, :post, content, username, password
			end # get_token_for

			#
			# create a new public gist
			#
			# todo: read token from file
			# todo: generate data for body
			#
			def post_new_gist content  
				url = GITHUB_API_GIST_LINK 
				response = https_open_for url, :post, content
 				JSON.parse response.body
			end # post_new_gist

			#
			#
			#
			#
			def get_gists id=nil
				url = GITHUB_API_GIST_LINK + ( id.nil? ? "" : "/#{id}")
				https_open_for url, :get
			end # get_gists

			#
			#
			#
			#
			def delete_gist id
				url = "#{GITHUB_API_GIST_LINK}/#{id}"
				https_open_for url, :delete
			end # delete_gist

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
			end # ask_for

			#
			# get user from git global configuration
			#
			def get_user_from_global
				%x(git config --global user.name).strip
			end # get_user_from_global

			#
			# generates data JSON 
			# create gist
			# delete gist
			# update gist
			# list gist
			#
			def generate_data file_name, description, content, public=true
		    # filename and content
		    file_data = {}
		    file_data[file_name] = {:content => content}
		    # data
		    gist_data = {"files" => file_data}
		    gist_data.merge!({ 'description' => description })
		    gist_data.merge!({ 'public' => public })
		    gist_data				
			end # generate_data

			#
			#
			#
			#
			def generate_scope note, scope
				scopes = {:note => note, :scopes => scope}
				scopes
			end


			# 
			# check if cert exist otherwise create
			# todo: refactoring for DRY
			# todo: read route from configuration file
			# 
			def check_cert
				path = File.join('/tmp','gistto.crt')
				unless File.exists? path
					FileUtils.cp File.join(File.expand_path('../../../extras', __FILE__),'gistto.crt'), '/tmp'
					abort "Cert File can't be copied to temp dir" unless File.exists? path
				end
				path
			end # check_cert

			#
			# pbcopy
			# todo: modify pbcopy to support any OS
			#
			def pbcopy str
				IO.popen('pbcopy', 'w'){ |f| f << str.to_s }
			end # pbcopy

			#
			#
			# create a random file name en base a date of creation
			#
			#
			def gistto_file_name
				d_c = Time.now
				"gistto-#{d_c.year}.#{d_c.month}.#{d_c.day}.#{d_c.hour}.#{d_c.min}.#{d_c.sec}.txt"
			end # gistto file name

			#
			#
			#
			#
			def has_param params, key
				#return false unless#params.first.first.kind_of? Array
				params.first.first.has_key?(key) && params.first.first[key] unless params.empty?
			end # has_param

			#
			#
			#
			#
			def read_token
				return @temporal_token unless @temporal_token.nil?
				# configuration file
				configuration_file = File.join(Dir.home, '.gistto')
				File.open(configuration_file, 'r') do |handler|
					while line = handler.gets
						if /^Token:/ =~ line 
							@temporal_token = line.split(":")[1].chomp!
							break
						end
					end
				end
				@temporal_token
			end


	end # Module Client

end # Module Gistto






