# Gistto

Gistto is a gist client for command interface in mac, it's born under the need to have quick access to gist
allowing to handle the basic operations and save thats pieces of code that it will be used later

## Installation

Install it yourself as:

    $ gem install gistto

## Usage

The first step is configure gistto to create the enviroment using:

	$ gistto config

this will create some configurations:
 1 - gistto home folder under your user home directory as: ~/gistto
 2 - gistto configuration file under your user home directory as : ~/.gistto
 3 - copy gistto.crt to /tmp folder for oAuth v3 Authentication under https
 4 - verify for git global configuration for username or ask him if git is not present
 5 - generate authentication token for oAuth v3 

Once your configuration is done and if you want to reconfigure on change user to save gists 
you can run the command config again but with option (-n) that allows you to overwrite configuration 
asking for username and password to generate token :

	$ gistto config -n

Now, to List all the gists that you already have generated you must run:

	$ gistto list

This list all the gist availables, showing 30 gist at time, to move an get the others (if you have more than 30),
gistto show you at the end of the list the available commands, for example if you have 45 gists 
the available commands are :

	$ gistto list 1 or gistto list 2

1 or 2 are references for page number.


If you want to add a new gist to your account you have some options:

	$ gistto add [-p] <file_path_1> <file_path_N>

Add action allow you to add any number of files, you only need to provide the path of every file
by default the gist to create is public but if you add -p option the gist will be created private
this return the gist-ID.

Also you can type the content of the gist instead of set file_path using:

	$ gistto type [-p] <filename> <file description (this must be quoted)>

After the command you will be asked for type the content of the gist directly in the command line when 
you are done and want to end to type you must to add a new line with enter and type ::eof

But if you want to get a gist that you already have get command if what you need:

	$ gistto get [-o|--open] [-c|--clipboard] [-l|--local] [-s|--show] gist-ID

Get have different options 
* -o : if you want to open in the browser in the raw format
* -c : if you want to copy the content of gist directly to the clipboard (don't worry if the gist contains
more than one file every file will be identified to ease handle)
* -l : if you want to make a local copy, this will be saved in the gistto folder under ~/gistto. A new folder
will be created with the gist-ID as name, to easyly identification
* -s : allows you to display the content of the gist in the screen to easy review.


One more option is allowed by the moment, delete a gist, using:

	$ gistto delete <gist-ID1> <gist-ID2> <gist-IDN>

This command allows you to delete one or many gist, this only delete from gist but not from your local copy if 
you created on with get command and -l option


## Todo

	1 - Implement sync method to sync local copy with online copy
	2 - Implement pull method to update all the local changes to online
	3 - Implement update method to update a gist from command line directly to online
	4 - Make some improvements to code 
	5 - Fix some typos 
	6 - Complete all rspec definitions 
	7 - Complete all rdoc documentation
	8 - Some new features to add in the future :)


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
