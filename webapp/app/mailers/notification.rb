##
# Mailer methods can be defined using the simple format:
#
# email :registration_email do |name, user|
#   from 'admin@site.com'
#   to   user.email
#   subject 'Welcome to the site!'
#   locals  :name => name
#   content_type 'text/html'       # optional, defaults to plain/text
#   via     :sendmail              # optional, to smtp if defined, otherwise sendmail
#   render  'registration_email'
# end
#
# You can set the default delivery settings from your app through:
#
#   set :delivery_method, :smtp => {
#     :address         => 'smtp.yourserver.com',
#     :port            => '25',
#     :user_name       => 'user',
#     :password        => 'pass',
#     :authentication  => :plain, # :plain, :login, :cram_md5, no auth by default
#     :domain          => "localhost.localdomain" # the HELO domain provided by the client to the server
#   }
#
# or sendmail (default):
#
#   set :delivery_method, :sendmail
#
# or for tests:
#
#   set :delivery_method, :test
#
# or storing emails locally:
#
#   set :delivery_method, :file => {
#     :location => "#{Padrino.root}/tmp/emails",
#   }
#
# and then all delivered mail will use these settings unless otherwise specified.
#

PbsSite::App.mailer :notification do

  email :job_notification_email do |name, email, id, url, description|
    from 'pbsfinder@gmail.com'
    to email
    subject "[PBS Finder] Your job is complete"
    locals :name => name, :id => id, :url => url, :description => description
    render 'notification/job_notification_email'
    content_type :plain
  end

  email :contact_email do |name, email, message, receiver|
    from email
    to receiver
    subject "[PBS Finder] User contact"
    locals :name => name, :email => email, :message => message
    render 'notification/contact_email'
    content_type :plain
  end

  email :job_problem_report_email do |name, email, message, url, receiver|
    from email
    to receiver
    subject "[PBS Finder] Error report"
    locals :name => name, :email => email, :message => message, :url => url
    render 'notification/job_problem_report_email'
    content_type :plain
  end

end
