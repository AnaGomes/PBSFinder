class WorkerHelper

  def initialize(config_dir, temp_dir, server_url)
    @config_dir = config_dir
    @temp_dir = temp_dir
    @server_url = server_url
  end

  def load_config(file)
    YAML::load_file(File.join(@config_dir, file))
  end

  def save_file(id, content)
    File.open(File.join(@temp_dir, "#{id}.temp"), 'w') do |f|
      f.write content
    end
  end

  def file_path(id)
    File.join(@temp_dir, "#{id}.temp")
  end

  def delete_file(id)
    File.delete(file_path(id))
  end

  def notify_finish(id, msg = nil)
    service = DRbObject.new_with_uri(@server_url)
    service.notify_finish(id, msg)
  end

end
