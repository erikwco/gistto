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
	VALID_METHODS					= ['config','add','update','list','delete','sync','type','get']

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
			#
			# options definitions and parsing
			# 
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
							gist_data =  post_new_gist "LINUX:: #{file_name} - sed tips", "#{file_name}", file_content.chomp
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

				#creating new gist
				#d_c = Time.now
				#gist_data =  post_new_gist "LINUX::Sed tip 03 - print only paragraphs", "gistto-#{d_c.year}.#{d_c.month}.#{d_c.day}.#{d_c.hour}.#{d_c.min}.#{d_c.sec}.txt", "sed -e '/./{H;$!d;}' -e 'x;/Administration/!d' file"
				#puts "Gist created => %s succesfull" % "#{gist_data['id']}".green
				
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
				gist_data =  post_new_gist description, filename, content.gsub("\\","\\\\\\\\").gsub("\n","\\n").gsub("\t","\\t").gsub("\"","\\#{34.chr}")
				if gist_data.has_key? 'id'
					puts "\n#{filename} [%s] [#{gist_data['id']}]\n" % "created".green 
				else
					puts "\n#{filename} [%s] [#{gist_data['message']}]\n" % "fail".red
				end
				
			end # type

			#
			# get a gist by id
			#
			def get id
				gist_response =  get_gists id[0]
				if gist_response.status == 200
					puts gist_response.body
					exit
					gist_data = JSON.parse gist_response.body
					puts "%s\t\t#{gist_data['description']}" % "#{gist_data['id']}".cyan
					#puts gist_data['files']

					gist_data['files'].each do |file|
						#pp JSON.unparse file[1]['content']
						pp ::JSON.parse file[1]['content']
					end

				else
					puts "\nOcurred an error getting gist #{id} [%s]\n" % "fail".red
				end
			end

			#
			# 
			#
			def list
				gist_response =  get_gists
				if gist_response.status == 200
					puts gist_response.body
					gist_data = JSON.parse gist_response.body
					gist_data.each do |data|
						puts "%s\t\t#{data['description']}" % "#{data['id']}".cyan
					end
				else
					puts "\nOcurred an error getting list of gist[%s]\n" % "fail".red
				end
			end 	# list


			def delete
				p "delete"
			end 	# delete

			def update
				# puts "{\"description\": 'description', \"public\": true, \"files\": { \"filename.txt\": {\"content\": \"content\" } } }".to_json
				objectt =  JSON.parse '{"url":"https://api.github.com/gists/5240328","forks_url":"https://api.github.com/gists/5240328/forks","commits_url":"https://api.github.com/gists/5240328/commits","id":"5240328","git_pull_url":"https://gist.github.com/5240328.git","git_push_url":"https://gist.github.com/5240328.git","html_url":"https://gist.github.com/5240328","files":{"test-09.txt":{"filename":"test-09.txt","type":"text/plain","language":null,"raw_url":"https://gist.github.com/raw/5240328/0cebc55615ebe9804d2ddee849eef4ad9a141601/test-09.txt","size":43,"content":"class HE\n\tdef msg\n\t\thello world\n\tend\nend\n"}},"public":true,"created_at":"2013-03-25T20:17:56Z","updated_at":"2013-03-25T20:17:56Z","description":"test-09.txt","comments":0,"user":{"login":"erikwco","id":2466329,"avatar_url":"https://secure.gravatar.com/avatar/7913c3c8b91075d63b7f14ed0973b116?d=https://a248.e.akamai.net/assets.github.com%2Fimages%2Fgravatars%2Fgravatar-user-420.png","gravatar_id":"7913c3c8b91075d63b7f14ed0973b116","url":"https://api.github.com/users/erikwco","html_url":"https://github.com/erikwco","followers_url":"https://api.github.com/users/erikwco/followers","following_url":"https://api.github.com/users/erikwco/following","gists_url":"https://api.github.com/users/erikwco/gists{/gist_id}","starred_url":"https://api.github.com/users/erikwco/starred{/owner}{/repo}","subscriptions_url":"https://api.github.com/users/erikwco/subscriptions","organizations_url":"https://api.github.com/users/erikwco/orgs","repos_url":"https://api.github.com/users/erikwco/repos","events_url":"https://api.github.com/users/erikwco/events{/privacy}","received_events_url":"https://api.github.com/users/erikwco/received_events","type":"User"},"comments_url":"https://api.github.com/gists/5240328/comments","forks":[],"history":[{"user":{"login":"erikwco","id":2466329,"avatar_url":"https://secure.gravatar.com/avatar/7913c3c8b91075d63b7f14ed0973b116?d=https://a248.e.akamai.net/assets.github.com%2Fimages%2Fgravatars%2Fgravatar-user-420.png","gravatar_id":"7913c3c8b91075d63b7f14ed0973b116","url":"https://api.github.com/users/erikwco","html_url":"https://github.com/erikwco","followers_url":"https://api.github.com/users/erikwco/followers","following_url":"https://api.github.com/users/erikwco/following","gists_url":"https://api.github.com/users/erikwco/gists{/gist_id}","starred_url":"https://api.github.com/users/erikwco/starred{/owner}{/repo}","subscriptions_url":"https://api.github.com/users/erikwco/subscriptions","organizations_url":"https://api.github.com/users/erikwco/orgs","repos_url":"https://api.github.com/users/erikwco/repos","events_url":"https://api.github.com/users/erikwco/events{/privacy}","received_events_url":"https://api.github.com/users/erikwco/received_events","type":"User"},"version":"6784a637c21ab721bc419b5ac2fa257f199ecf13","committed_at":"2013-03-25T20:17:56Z","change_status":{"total":5,"additions":5,"deletions":0},"url":"https://api.github.com/gists/5240328/6784a637c21ab721bc419b5ac2fa257f199ecf13"}]}'
				#pp objectt['files']
				objectt['files'].each do |file|
					#pp JSON.unparse file[1]['content']
					pp JSON.parse file[1]['content']
				end
			end 	# update


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
			end # get_token_for

			#
			# create a new public gist
			#
			# todo: dont DRY on Faraday connection
			# todo: check cert
			# todo: read token from file
			# todo: generate data for body
			#
			def post_new_gist(description, filename, content, ispublic=true)
				check_cert
				conn = Faraday.new(GITHUB_API	, :ssl => { :ca_file => "/tmp/gistto.crt"})
				response = conn.post do |req|
					req.url GITHUB_API_GIST_LINK + "?access_token=811033a7319a682b2ab0df6f97cd42b49ed37dd4"
					req.headers['Content-Type'] = 'application/json'
					req.body = '{"description": "' + description + '", "public": true, "files": { "' + filename + '": {"content": "' + content + '" } } }'
				end
 				JSON.parse response.body
			end # post_new_gist


			#
			#
			#
			#
			def get_gists id=nil
				check_cert
				conn = Faraday.new(GITHUB_API	, :ssl => { :ca_file => "/tmp/gistto.crt"})
				response = conn.get do |req|
					req.url GITHUB_API_GIST_LINK + ( id.nil? ? "" : "/#{id}") +"?access_token=811033a7319a682b2ab0df6f97cd42b49ed37dd4"
					req.headers['Content-Type'] = 'application/json'
				end
 				response
			end


			#
			#
			#
			#
			def get_raw url
				check_cert
				conn = Faraday.new(GITHUB_API	, :ssl => { :ca_file => "/tmp/gistto.crt"})
				response = conn.get do |req|
					req.url GITHUB_API_GIST_LINK + ( id.nil? ? "" : "/#{id}") +"?access_token=811033a7319a682b2ab0df6f97cd42b49ed37dd4"
					req.headers['Content-Type'] = 'application/json'
				end
 				response
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
			def generate_data
				
			end # generate_data


			# 
			# check if cert exist otherwise create
			# todo: refactoring for DRY
			# 
			def check_cert
				unless File.exists?(File.join('/tmp','gistto.cert'))
					FileUtils.cp File.join(File.expand_path('../../../extras', __FILE__),'gistto.crt'), '/tmp'
					abort "Cert File can't be copied to temp dir" unless File.exists?(File.join('/tmp', 'gistto.crt'))
				end
			end


	end # Module Client

end # Module Gistto


