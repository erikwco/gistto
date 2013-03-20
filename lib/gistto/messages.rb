module Gistto
# Messages used in the application


# Message used when a configuration file already exists
MSG_CONFIG_EXISTS= <<-EOS
Yeah! Configuration file already exists in your home dir !!
You can now move on and begin to Use Gistto or if you want to reconfigure Gistto
please type: gistto config -n to make a new configuration otherwise
please type gistto help to see what can you do!
EOS


MSG_GITHUB_USER_NOT_CONFIGURED = <<-EOS
git config --global user.name is not configured, do you want to type user name instead ? (y/n)
EOS
	
end


