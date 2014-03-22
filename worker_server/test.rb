#require 'open-uri'
#require 'nokogiri'
#require 'yaml'

#doc = Nokogiri::HTML(open("http://www.ensembl.org/info/genome/stable_ids/index.html"))
#res = {}
#doc.css('.bg1, .bg2').each do |row|
  #res[row.children[0].text()] = row.children[1].text()
#end
#puts YAML.dump(res)



require 'bio'
require 'open-uri'

uri = URI::HTTP.build(
  :host => 'eutils.ncbi.nlm.nih.gov',
  :path => '/entrez/eutils/efetch.fcgi',
  :query => URI.encode_www_form(
    'db' => 'nuccore',
    'rettype' => 'gb',
    'id' => 'NM_001005560,XM_006221333'
  ))
ff = Bio::FlatFile.open_uri(uri)
ff.each_entry do |gb|

  # SPECIES
  puts gb.source['common_name']
  puts gb.locus.entry_id
  puts gb.locus.date
  gb.each_cds do |cds|

    # ENTREZ GENE ID
    puts cds['db_xref'].find { |id| id =~ /GeneID/ }.split(":")[-1]

    # GENE NAME
    puts cds['gene'].class

    # CDS REGION
    loc = cds.locations.first

    seq = gb.naseq.upcase
    puts seq.size, loc.from, loc.to
    puts "5UTR"
    puts seq[0...(loc.from - 1)]
    #puts seq.subseq(1, loc.from - 1).to_fasta('asda',80)
    puts "3UTR"
    puts seq[(loc.to)...seq.size]
    #puts seq.subseq(loc.to + 1, gb.length).to_fasta('asd',80)
  end
  #puts gb.entry_id
  #gb.features.each do |feat|
    #f = feat.assoc
     #puts f.inspect
  #end
 end
