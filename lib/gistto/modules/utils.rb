module Gistto
	module Client
		extend self
		
		private
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

	end
end