require 'rubygems'
require 'faraday'
require 'optparse'
require 'fileutils'
require 'tmpdir'
require 'json'
require 'pp'


module Gistto

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
					puts @oparser
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
				#puts oparser
				puts "Not valid method: please run gistto -h"
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

	end # Module Client

end # Module Gistto






