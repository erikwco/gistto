require_relative "gistto/version"
require_relative "gistto/client"

pp Gistto::Client.connect "erikwco"


#proxy = Faraday.new("https://api.github.com/", :ssl => { :ca_file => "/opt/local/share/curl/curl-ca-bundle.crt"})
#proxy.basic_auth('erikwco', 'Elite$00')
#response = proxy.get 
#puts response.body


