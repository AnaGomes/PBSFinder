require 'drb'
require 'thread'
require 'yaml'

SERVER_URL = 'druby://localhost:5555'
CONFIG_DIR = File.join(__dir__, './configs')
WORKER_DIR = File.join(__dir__, './workers')

# Require all workers.
Dir["#{WORKER_DIR}/*.rb"].each { |file| require file }

################################################################################
#
# Worker classes must be created in WORKER_DIR. If a class needs an YAML config
# file it should be stored in CONFIG_DIR.
#
# Every worker class should the following methods:
#   * def initialize()
#   * def setup(id, config_loader, notifier, *args)
#   * def work()
#
################################################################################

# Worker global controller.
class MasterWorker

  def initialize
    @current_id = 0
    @process_mutex = Mutex.new
    @process_by_id = {}
    @config_loader = ConfigLoader.new(CONFIG_DIR)
    @notifier = Notifier.new
  end

  # Launches new worker.
  def start_new_worker(worker, *args)
    wkr = _instantiate_worker(worker)
    if wkr
      id = nil
      @process_mutex.synchronize do
        while @process_by_id.has_key?(@current_id)
          @current_id = @current_id + 1
          if(@current_id >= 30000)
            @current_id = 0
          end
        end
        id = @current_id
        @process_by_id[id] = wkr
      end
      wkr.setup(id, @config_loader, Notifier.new, *args)
      puts "Starting worker (#{worker})"
      _start_new_worker(wkr)
      return id
    else
      return nil
    end
  end

  # Frees worker resources.
  def notify_finish(id, msg = nil)
    @process_mutex.synchronize do
      @process_by_id.delete(id)
    end
    if msg
      puts "Worker #{id} finished: #{msg}"
    else
      puts "Worker #{id} finished"
    end
  end

  private

  # Launches the worker in a new thread.
  def _start_new_worker(worker)
    Thread.new do
      worker.work
    end
  end

  def _instantiate_worker(worker)
    begin
      wkr = Object.const_get(worker).new
      if wkr.respond_to?('work') && wkr.respond_to?('setup')
        return wkr
      else
        return nil
      end
    rescue
      return nil
    end
  end

end

# Helper class for YAML configuration loading.
class ConfigLoader

  def initialize(dir)
    @dir = dir
  end

  def load_config(file)
    YAML::load_file(File.join(CONFIG_DIR, file))
  end

end

# Enables workers to notify the master that they have finished.
class Notifier

  def notify_finish(id, msg = nil)
    service = DRbObject.new_with_uri(SERVER_URL)
    service.notify_finish(id, msg)
  end

end

# Starts the service.
master = MasterWorker.new
DRb.start_service(SERVER_URL, master)
DRb.thread.join
