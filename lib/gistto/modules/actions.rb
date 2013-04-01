module Gistto
	module Client
		extend self

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
					puts "Get without options[-c|-s|-l|-o] don't produce any output we will activate copy to clipboard".yellow
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
			# => 
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

	end
end