# Stages are kind of like environments.
set :stages, %w(production staging dev)
set :default_stage, "dev"
require "capistrano/ext/multistage"

require "tmpdir"
set :copy_dir, Dir.tmpdir

# Define configuration.
set :application, "mozart"
set :scm, :git
set :repository, "file://."

if `uname` =~ /Darwin/
  # Assumes OS X users have gnutar installed; it's present by default since Mountain Lion.
  set :copy_local_tar, "/usr/bin/gnutar"
end

# User and SSH options.
set :use_sudo, false
ssh_options[:forward_agent] = true

# checkout locally, then tar and gzip the copy
# and sftp it to the remote servers
set :deploy_via, :copy
set :copy_cache, false

# Here we use the build script to minify the javascript code
set :build_script, "./config/build.sh"

# Ignore the stuff we don't want
set :copy_exclude, [
    '.grunt',
    'config', 
    'node_modules',
    'src',
    'test',
    'Capfile',
    'Gemfile*',
    'vendor',
    'Gruntfile.js',
    'package.json'
]

task :set_mozart_version do
	set :mozart_version, File.read("#{copy_dir}/#{application}/src/mozart/mozart.coffee").scan(/.*version:.*/)[0].sub(/.*: \"([\d\.]+)\".*/, '\1')
	puts "Mozart Version: #{mozart_version}"
end

namespace :deploy do
    desc "Linking Mozart Version"
    task :symlink do
    	set_mozart_version
     	run "rm -f #{deploy_to}/#{mozart_version}; ln -s #{release_path} #{deploy_to}/#{mozart_version}"
    end
end
