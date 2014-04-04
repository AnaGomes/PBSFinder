require 'benchmark'
require 'json'
require 'yaml'
require 'uri'
require 'net/http'
require 'net/http/post/multipart'
require_relative 'pbs_finder/ensembl'
require_relative 'pbs_finder/ncbi'
require_relative 'pbs_finder/helper'

class PbsFinder

  # Builds a new PBSFinder instance, loading its configurations from the given
  # file.
  def initialize
    @id = nil
    @helper = nil
    @resp_url = nil
    @data = nil
  end

  def setup(id, helper, args)
    @id, @helper = id, helper
    @config = @helper.load_config('pbs_finder.yml')
    json = JSON.parse(args)
    @resp_url = json['url']
    @data = json['data']
  end

  def work
    # Finding protein binding sites.
    begin
      resp = {}
      helper = Pbs::Helper.new(@config)
      ensembl = Pbs::Ensembl.new(helper)
      ncbi = Pbs::Ncbi.new(helper)
      bench = Benchmark.measure do
        genes = helper.divide_ids(@data, ncbi.process_ids(@data) + ensembl.process_ids(@data))
        ensembl.find_protein_binding_sites(genes[:ensembl])
        ncbi.find_protein_binding_sites(genes[:ncbi])
        resp['genes'] = helper.consolidate_results(genes[:ensembl] + genes[:ncbi] + genes[:invalid])
      end
      resp['time'] = bench.real < 0 ? 1 : bench.real.to_i
      resp = resp.to_json

      # Respond to server.
      uri = URI(@resp_url)
      @helper.save_file(@id, resp)
      req = Net::HTTP::Post::Multipart.new uri.path,
        "result" => UploadIO.new(File.new(@helper.file_path(@id)), "application/json", "result.json")
      Net::HTTP.start(uri.host, uri.port) do |http|
        http.request(req)
      end
      @helper.delete_file(@id)

      # Notify master.
      @helper.notify_finish(@id, 'PBSFinder')
    rescue Exception => e
      puts e.message, e.backtrace
      @helper.notify_finish(@id, 'PBSFinder')
      return
    end
  end
end
