# Connection.new takes host and port.

host = 'localhost'
port = 27017

database_name = case Padrino.env
  when :development then 'pbs_site_development'
  when :production  then 'pbs_site_production'
  when :test        then 'pbs_site_test'
end

# Use MONGO_URI if it's set as an environmental variable.
Mongoid::Config.sessions =
  if ENV['MONGO_URI']
    {default: {uri: ENV['MONGO_URI'] }}
  else
    {default: {hosts: ["#{host}:#{port}"], database: database_name}}
  end

Mongoid.raise_not_found_error = false
Mongoid.identity_map_enabled = true

# If you want to use a YML file for config, use this instead:
#
#   Mongoid.load!(File.join(Padrino.root, 'config', 'database.yml'), Padrino.env)
#
# And add a config/database.yml file like this:
#   development:
#     sessions:
#       default:
#         database: pbs_site_development
#         hosts:
#           - localhost:27017
#   production:
#     sessions:
#       default:
#         database: pbs_site_production
#         hosts:
#           - localhost:27017
#   test:
#     sessions:
#       default:
#         database: pbs_site_test
#         hosts:
#           - localhost:27017
#
#
# More installation and setup notes are on http://mongoid.org/en/mongoid/docs/installation.html#configuration
