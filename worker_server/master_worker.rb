require 'drb'
require 'thread'
require 'yaml'
require 'mongoid'

SERVER_URL = 'druby://localhost:5555'
CONFIG_DIR = File.expand_path('../configs', __FILE__)
WORKER_DIR = File.expand_path('../workers', __FILE__)
MODELS_DIR = File.readlink(File.expand_path('../db/models', __FILE__))
TEMP_F_DIR = File.expand_path('../temp', __FILE__)
TEMP_W_DIR = File.expand_path('../temp_work', __FILE__)
DB_ENV = ARGV.size == 1 ? ARGV[0] : 'development'
MAX_JOBS = 10

# Load database ODM.
Mongoid.load!(File.expand_path('../db/database.yml', __FILE__), DB_ENV)

# Require the worker helper.
require_relative 'worker_helper'

# Require all workers.
Dir["#{WORKER_DIR}/*.rb"].each { |file| require file }

# Require all models.
Dir["#{MODELS_DIR}/*.rb"].each { |file| require file }


################################################################################
#
# Worker classes must be created in WORKER_DIR. If a class needs an YAML config
# file it should be stored in CONFIG_DIR.
#
# Every worker class should the following methods:
#   * def initialize()
#   * def setup(id, helper, *args)
#   * def work()
#
################################################################################

# Worker global controller.
class MasterWorker

  def initialize
    @current_id = 0
    @process_mutex = Mutex.new
    @process_by_id = {}
  end

  def resume_workers
    Dir["#{TEMP_W_DIR}/*.yml"].each do |f|
      yaml = YAML.load(File.read(f))
      worker, args = yaml.first
      File.delete(f)
      start_new_worker(worker, *args)
    end
  end

  # Launches new worker.
  def start_new_worker(worker, *args)
    wkr = _instantiate_worker(worker)
    if wkr
      id = _place_worker(wkr)
      _save_worker(id, worker, args)
      wkr.setup(id, WorkerHelper.new(CONFIG_DIR, TEMP_F_DIR, SERVER_URL), *args)
      puts "Starting worker #{id} (#{worker})"
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
      File.delete(File.join(TEMP_W_DIR, "#{id}.yml"))
    end
    if msg
      puts "Worker #{id} finished: #{msg}"
    else
      puts "Worker #{id} finished"
    end
  end

  def working?
    true
  end

  def available?
    result = false
    @process_mutex.synchronize { result = @process_by_id.size < MAX_JOBS }
    result
  end

  private

  # Saves a copy of the worker arguments.
  def _save_worker(id, worker, args)
    File.open(File.join(TEMP_W_DIR, "#{id}.yml"), 'w') do |f|
      f.write(YAML.dump({ worker => args }))
    end
  end

  # Launches the worker in a new thread.
  def _start_new_worker(worker)
    Thread.new do
      worker.work
    end
  end

  def _place_worker(wkr)
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
    return id
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

# Starts the service.
Dir.mkdir(TEMP_F_DIR) unless File.exists?(TEMP_F_DIR)
Dir.mkdir(TEMP_W_DIR) unless File.exists?(TEMP_W_DIR)
master = MasterWorker.new
DRb.start_service(SERVER_URL, master)
master.resume_workers
DRb.thread.join
