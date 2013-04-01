module Gistto
	module Client
		extend self

		private
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


	end
end