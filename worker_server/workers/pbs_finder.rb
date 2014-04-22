require 'json'
require 'uri'
require 'net/http'
require_relative 'pbs_finder/pbs'

# Runs a protein binding sites finder job, saves it to the database and reports
# back to the requester.
class PbsFinder
  def initialize
    @id = nil
    @helper = nil
    @job_id = nil
    @data = nil
    @resp_url = nil
  end

  def setup(id, helper, args)
    @id, @helper = id, helper
    @config = @helper.load_config('pbs_finder.yml')
    json = JSON.parse(args)
    @job_id = json['id']
    @resp_url = json['url']
    @data = json['data']
  end

  def work
    # Process job and save results to database.
    pbs = Pbs::Workflow.new(@config, @data, @job_id)
    pbs.start_job_analysis
    pbs.save_job_analysis

    # Send completion notifications.
    notify_requester
    notify_master
  end

  private

  def notify_requester
    # Notify job completion.
    retries = 0
    uri = URI(@resp_url)
    Net::HTTP.post_form(uri, {})
  rescue StandardError => e
    puts e.message, e.backtrace

    # Retry a few times, server might be down.
    retries += 1
    if retries <= 3
      sleep 5
      retry
    end
  end

  def notify_master
    @helper.notify_finish(@id, 'PBSFinder')
  end
end
