PbsSite::App.helpers do

  def contact(c)
    deliver(
      :notification,
      :contact_email,
      c.name,
      c.email,
      c.message,
      settings.main_conf['contact']['email']
    )
  end

end
