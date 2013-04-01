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
	VALID_METHODS					= ['config','add','list','delete','type','get','sync','pull']
	# 
	# Clien todo list
	# todo: sync, pull and inline update methods 
	#          
	module Client
		extend self

		#
		# instance module variables
		#
		@temporal_token = nil
		@options = {}

		def run(*args)
			#
			# options definitions and parsing
			# 
			oparser = OptionParser.new do |option|
				option.banner = "Usage  : gistto [action] [options] [arguments] ... \n" +
												"* action : \n" +
												"* config [-n|--new]\n" +
												"* add    [-p|--private] file-path1 file-path2 ...  file-pathN\n" +
												"* get    [-o|--open] [-c|--clipboard] [-l|--local] [-s|--show] gist-ID\n" +
												"* delete gist-ID\n" +
												"* list \n\n" +
												"warn: [-l|--local] will overwrite local files without mercy :) \n\n".red
				# new configuration
				option.on('-n', '--new', 			'Makes a new user configuration') { |n| @options[:new_config] = n }
				# private gist
				option.on('-p', '--private', 	'Save Gist as private') { |n| @options[:private] = n }
				# open gist in raw view
				option.on('-o', '--open', 		'Open Gist in browser in raw format') { |n| @options[:open] = n }
				# copy gist to the clipboard
				option.on('-c', '--clipboard','Copy Gist to clipboard') { |n| @options[:clipboard] = n }
				# copy gist file(s) to gistto folder
				option.on('-l', '--local',		'Copy Gist file(s) to gissto folder') { |n| @options[:local] = n }
				# show input into screen
				option.on('-s', '--show',			'Show Gist file(s) in the screen') { |n| @options[:show] = n }
				# version
				option.on('-v', '--version', 'Display Gistto current version') do
					puts Gistto::VERSION
					exit
				end
				# help
				option.on('-h','--help','Display help screen') do
					puts oparser
					exit
				end

			end

			#
			# parsing options
			#
			begin
				oparser.parse!(args) 	
			rescue
				puts oparser
				exit
			end 

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
				puts "Please wait while we configure gistto in your Mac :)\n".cyan
				#
				# verify if configuration file exists : unless if only for degub purpose
				#
				overwrite = (@options.empty?) ? false : @options.has_key?(:new_config)
				abort Gistto::MSG_CONFIG_EXISTS if File.exists?(File.join(Dir.home,'.gistto')) && !overwrite
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
				home_path = File.join(Dir.home, 'gistto')
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
			rescue 
				exit
			end 	# config

			#
			# add method
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
							is_public = (@options.empty?) ? true : !@options.has_key?(:private)
							gist_data =  post_new_gist generate_data "#{file_name}", "#{file_name}", file_content.chomp, is_public
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
				is_public = (@options.empty?) ? true : !@options.has_key?(:private)
				gist_data =  post_new_gist generate_data "#{filename}", "#{description}", content.chomp, is_public
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
			#
			def get *id
				if id.empty?
					puts "gist-ID is required parameter for get method"
					exit 
				end
				#options
				copy_to_clipboard =  (@options.empty?) ? false : @options.has_key?(:clipboard)
				open_in_browser = (@options.empty?) ? false : @options.has_key?(:open)
				save_local = (@options.empty?) ? false : @options.has_key?(:local)
				show_in_screen =(@options.empty?) ? false : @options.has_key?(:show)

				if !copy_to_clipboard && !open_in_browser && !save_local && !show_in_screen
					puts "Gets without options[-c|-s|-l|-o] don't produce any output we will activate copy to clipboard".yellow
					copy_to_clipboard = true
				end

				gistto_home = read_from_config_file "Gistto-Home"
				#
				str_code = ""
				id[0].each do |item|

					gist_response =  get_gists ({id: item}) 
					if gist_response.status == 200
						# 
						gist_data = JSON.load(gist_response.body)
						#screen
						puts "\n\n%s\t\t#{gist_data['description']}" % "#{gist_data['id']}".cyan if show_in_screen
						# recorring files
						str_code << "\n\nGIST ID :#{item}\n"
						gist_data['files'].map do |name, content|
							# screen
							puts "\n%s\n" % name.yellow if show_in_screen
							puts "#{content['content']}\n\n" if show_in_screen
							# clipboard
							str_code << "\n\n****** #{name} *******\n\n"
							str_code << "#{content['content']} \n"
							# open in browser
							navigate_to "#{content['raw_url']}" if open_in_browser
							# create files
							if save_local
								# creating folders
								local_path = File.join gistto_home, gist_data['id']
								local_file = File.join local_path, name
								FileUtils.mkdir_p local_path
								# creating files
								File.open(local_file, 'w') {|f| f.write(content['content']) } 
								#
								puts "%s successfull created in %s" % ["#{name}".green, "#{local_path}".green]
							end
						end # map
						# clipboard
						if copy_to_clipboard && item.equal?(id[0].last)
							pbcopy str_code
							puts "\nCode copied to clipboard!" 
						end
					else
						puts "\nOcurred an error getting gist #{id} [%s]\n" % "fail".red
					end

				end # each id
			rescue Exception => e
				puts e
			end # get

			#
			# list
			#
			def list *page
				page = [[1]] if page.empty?
				gist_response =  get_gists({page: page[0][0]})
				if gist_response.status == 200
					gist_data = JSON.load gist_response.body

					# getting pages
					total_moves = get_total_moves gist_response[:link]
					# printing
					gist_data.map do |items|
						puts "%s%s#{items['description']}" % ["#{items['id']}".cyan, "#{items['public'] ? "\t\t\tPublic\t\t" : "\tPrivate\t\t"}".magenta]
						puts "Files :" + items['files'].map {|name, content| "\t#{name}".green }.join(",")
						puts "\n"
					end
					# moves?
					unless total_moves.empty?
						puts "There are more gist pending to show, to load them run:"
						total_moves.each { |e| puts "gistto list #{e}".green }
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
				p "Not implemented yet"
			end 	# update


			def sync
				puts "Not implemented yet"
			end

			def pull
				pust "Not implemented yet"
				
			end

			#
			#
			# https_open_for
			#
			#
			def https_open_for  ops={}
				ops={:url=> nil, :mthd=> nil,:content => nil, :username => nil, :password => nil, :page=> nil}.merge(ops)
				conn = Faraday.new(GITHUB_API	, :ssl => { :ca_file => check_cert})
				conn.basic_auth ops[:username], ops[:password] unless ops[:username].nil? && ops[:password].nil?
				response= conn.method(ops[:mthd]).call do |req|
					req.url ops[:url] + ((ops[:username].nil? && ops[:password].nil?) ? "?access_token=%s" % read_token : "" ) + ((ops[:page].nil?) ? "" : "&page=#{ops[:page]}")
					req.headers['Content-Type'] = 'application/json'
					req.body = JSON.generate(ops[:content]) unless ops[:content].nil?
				end
				response
			#rescue Exception => e
				#raise "An error ocurred trying to open connection with GitHub [%s]" % "#{e}".red
			end # https_open_for

			#
			# Make connection to Get Token
			#
			def get_token_for(username, password)
				url = GITHUB_API_AUTH_LINK 
				scopes = %w[repo gist]
				content = generate_scope "Gistto", scopes
				https_open_for ({url: url, mthd: "post", content: content, username: username, password: password})
			end # get_token_for

			#
			# create a new public gist
			#
			def post_new_gist content  
				url = GITHUB_API_GIST_LINK 
				response = https_open_for ({url: url, mthd:"post", content: content})
 				JSON.parse response.body
			end # post_new_gist

			#
			#
			#
			#
			def get_gists ops={}
				ops={:id=>nil, :page=>1}.merge(ops)
				url = GITHUB_API_GIST_LINK + ( ops[:id].nil? ? "" : "/#{ops[:id]}")
				https_open_for ({url: url, mthd:"get" , page: ops[:page]})
			end # get_gists

			#
			#
			#
			#
			def delete_gist id
				url = "#{GITHUB_API_GIST_LINK}/#{id}"
				https_open_for ({:url=> url, mthd:"delete"})
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
				@temporal_token = read_from_config_file "Token"
				@temporal_token
			end

			#
			#
			#
			#
			#
			def read_from_config_file param
				config_value = nil
				# configuration file
				configuration_file = File.join(Dir.home, '.gistto')
				File.open(configuration_file, 'r') do |handler|
					while line = handler.gets
						if /^#{param}:/ =~ line 
							config_value = line.split(":")[1].chomp!
							break
						end
					end
				end
				config_value				
			end

			#
			#
			#
			#
			def navigate_to url
				`open #{url}`
			end # navigate_to


			#
			#
			#
			#
			def get_total_moves links
				# validating for return 
				return [] if links.nil?
				# get all available moves in links
				total_moves = links.split(",").map do |link|
					link = link.gsub(/[<>]/,'').strip.split(";").first
					i_page = link.split("&").to_a.select { |v| v.match("page") }.map { |v| v.split("=")[1] }.first
					link = i_page
				end.uniq
				total_moves
			end # get_total_pages

	end # Module Client

end # Module Gistto






