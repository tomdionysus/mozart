#!/usr/bin/env ruby
require 'optparse'
require 'fileutils'

options = {}
option_parser = OptionParser.new do |opts|

  # Defaults
  options[:repo] = "git@github.com:bigcommerce/mozart.git"
  options[:webroot] = 'web'
  
  opts.on("-r", "--repository URL", "The repository/fork url (desfult '#{options[:repo]}')") do |url|
      options[:repo] = url
  end
  
  opts.on("-b", "--branch NAME", "The branch (or tag) to checkout on") do |branch|
    options[:branch] = branch
  end
  
  opts.on("-p", "--install-path PATH", "The install path  (default '#{options[:install_path]}')") do |path|
    options[:install_path] = path
  end
  
  opts.on("--web-root DIR", "The web root directory (default 'web')") do |dir|
    options[:webroot] = dir
  end
  
end

option_parser.parse!

# Tack on a trailing slash if required
options[:install_path] << '/' unless options[:install_path].end_with?('/')

# Validate the required fields
raise OptionParser::MissingArgument if options[:repo].nil?
raise OptionParser::MissingArgument if options[:branch].nil?

puts ""
puts "Installing Mozart"
puts ""
puts "Clone from:\t#{options[:repo]}"
puts "On branch/tag:\t#{options[:branch]}"
puts "Install dir:\t#{options[:install_path]}"
puts "Webroot:\t#{options[:webroot]}"
puts ""

## Clean/create the install directory
#if Dir[options[:install_path]] != nil
#  puts "Deleting existing dir"
#  FileUtils.rm_r options[:install_path]
#end

# Make the dir if it doesnt exist.
unless File.directory? options[:install_path]
  Dir.mkdir options[:install_path]
end

# Change into the install directory
Dir.chdir options[:install_path]

# Clean up
result = system("rm -rf #{options[:webroot]} #{options[:branch]}")

# Clone the repo
result = system("git clone #{options[:repo]} -b #{options[:branch]} #{options[:branch]}")

# Recreate the symlink
result = system("ln -s #{options[:branch]}/public #{options[:webroot]}")

puts Dir::pwd

# Change into the web root
Dir.chdir "#{options[:branch]}"

# Run NPM install
result = system("npm install");

# Run grunt builder
result = system("node_modules/grunt/bin/grunt build");

# Output the details to the user
puts ""
puts "Mozart has been installed and built in '#{options[:install_path]}#{options[:webroot]}'"
puts ""
