module Gistto
# Messages used in the application


# Message used when a configuration file already exists
MSG_CONFIG_EXISTS= <<-EOS
Gistto is already configured on your MAC :) !!

but

if you want to overwrite the configuration run:
gistto config -n 

enjoy Gistto!! <3
EOS


MSG_GITHUB_USER_NOT_CONFIGURED = <<-EOS
git config --global user.name is not configured, do you want to type user name instead ? (y/n)
EOS
	
end


