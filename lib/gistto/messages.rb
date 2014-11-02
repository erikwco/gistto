module Gistto
# Messages used in the application


# Message used when a configuration file already exists
MSG_CONFIG_EXISTS= <<-EOS
Gistto is already configured on your MAC :) !!

but

if you want to overwrite the configuration please follow the next steps:

1.- Delete the personal token access from your profile in Github associated to Gistto
2.- Run the next command : gistto config -n 

enjoy Gistto!! <3
EOS


MSG_GITHUB_USER_NOT_CONFIGURED = <<-EOS
git config --global user.name is not configured, do you want to type user name instead ? (y/n)
EOS



MSG_BANNER = <<-EOS 
Usage  : gistto [action] [options] [arguments] ...
* action : 
* config [-n|--new]
* add    [-p|--private] file-path1 file-path2 ...  file-pathN
* get    [-o|--open] [-c|--clipboard] [-l|--local] [-s|--show] gist-ID
* delete gist-ID
* list 

warn: [-l|--local] will overwrite local files without mercy :) 

	-n, --new                        Makes a new user configuration
	-p, --private                    Save Gist as private
	-o, --open                       Open Gist in browser in raw format
	-c, --clipboard                  Copy Gist to clipboard
	-l, --local                      Copy Gist file(s) to gissto folder
	-s, --show                       Show Gist file(s) in the screen
	-v, --version                    Display Gistto current version
	-h, --help                       Display help screen
EOS

	
end


