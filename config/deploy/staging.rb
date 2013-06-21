# CDN Servers
role :app, "cache1.syd1bc.bigcommerce.net"

# Configuration options.
set :deploy_to, "/opt/bigcommerce_mozart"

# SSH Key configuration
set :user, "deploy_mozart"
set :group, "www-data"
ssh_options[:forward_agent] = true
ssh_options[:keys] = '/etc/deploy_keys/deploy-mozart-staging'


