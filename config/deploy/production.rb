# CDN Servers
role :app, "cache1.dal1sl.bigcommerce.net"
role :app, "cache1.dal5sl.bigcommerce.net"

# Configuration options.
set :deploy_to, "/opt/bigcommerce_mozart"

# SSH Key configuration
set :user, "deploy_mozart"
set :group, "www-data"
ssh_options[:forward_agent] = true
ssh_options[:keys] = '/etc/deploy_keys/deploy-mozart-production'


