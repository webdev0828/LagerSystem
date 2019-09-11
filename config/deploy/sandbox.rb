set :port, 22
set :user, 'jnsandbox'
set :deploy_via, :remote_cache
set :use_sudo, false

server '213.5.36.77',
  roles: [:web, :app, :db],
  port: fetch(:port),
  user: fetch(:user),
  primary: true

set :deploy_to, "/home/#{fetch(:user)}/#{fetch(:application)}"

set :ssh_options, {
  forward_agent: true,
  auth_methods: %w(publickey),
  user: 'jnsandbox',
}

set :rails_env, :staging
set :conditionally_migrate, true 