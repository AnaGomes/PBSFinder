# Helper methods defined here can be accessed in any controller or view in the application

require 'drb'
PbsSite::App.helpers do

  def long_job(job, url, data)
    remote = DRbObject.new_with_uri('druby://localhost:5555')
    json = { :url => url, :data => data }.to_json
    remote.start_new_worker(job, json)
  end

  def server_running?
    begin
      remote = DRbObject.new_with_uri('druby://localhost:5555')
      remote.working?
    rescue
      return false
    end
    return true
  end

end
