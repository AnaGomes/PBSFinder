##
# This file mounts each app in the Padrino project to a specified sub-uri.
# You can mount additional applications using any of these commands below:
#
#   Padrino.mount('blog').to('/blog')
#   Padrino.mount('blog', :app_class => 'BlogApp').to('/blog')
#   Padrino.mount('blog', :app_file =>  'path/to/blog/app.rb').to('/blog')
#
# You can also map apps to a specified host:
#
#   Padrino.mount('Admin').host('admin.example.org')
#   Padrino.mount('WebSite').host(/.*\.?example.org/)
#   Padrino.mount('Foo').to('/foo').host('bar.example.org')
#
# Note 1: Mounted apps (by default) should be placed into the project root at '/app_name'.
# Note 2: If you use the host matching remember to respect the order of the rules.
#
# By default, this file mounts the primary app which was generated with this project.
# However, the mounted app can be modified as needed:
#
#   Padrino.mount('AppName', :app_file => 'path/to/file', :app_class => 'BlogApp').to('/')
#

##
# Setup global project settings for your apps. These settings are inherited by every subapp. You can
# override these settings in the subapps as needed.
#
Padrino.configure_apps do
  enable :sessions
  set :session_secret, '8381a0d67e8178d9d84bfb96cfc8f7a311f8aef70b179d1281d35c038c13bfdc'
  set :protection, :except => :path_traversal
  set :protect_from_csrf, true
  set :allow_disabled_csrf, true

  # Load config files.
  begin
    logger.info "Opening: #{Padrino.root}/config/conf.yml"
    set :main_conf, YAML::load(File.open("#{Padrino.root}/config/conf.yml"))["config"]
  rescue
    logger.fatal "ERROR: Cannot open config files!"
    exit
  end
end

# Mounts the core application for this project

#Padrino.mount("PbsSite::Admin", :app_file => Padrino.root('admin/app.rb')).to("/pbsfinder/admin")
Padrino.mount('PbsSite::App', :app_file => Padrino.root('app/app.rb')).to('/pbsfinder')
