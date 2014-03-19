#require 'open-uri'
#require 'nokogiri'
#require 'yaml'

#doc = Nokogiri::HTML(open("http://www.ensembl.org/info/genome/stable_ids/index.html"))
#res = {}
#doc.css('.bg1, .bg2').each do |row|
  #res[row.children[0].text()] = row.children[1].text()
#end
#puts YAML.dump(res)



#require 'bio'
#require 'open-uri'

#ff = Bio::FlatFile.open_uri("http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id=399124807&rettype=gb")
#ff.each_entry do |gb|
  #puts gb.source['common_name']
  #gb.each_cds do |cds|
    #puts cds['db_xref'].inspect
    #loc = cds.locations.first
    #seq = gb.naseq
    #puts "5UTR"
    #puts seq.subseq(1, loc.from - 1).to_fasta('asda',80)
    #puts "3UTR"
    #puts seq.subseq(loc.to + 1, gb.length).to_fasta('asd',80)
  #end
  ##puts gb.entry_id
  ##gb.features.each do |feat|
    ##f = feat.assoc
    ##puts f.inspect
  ##end
#end
