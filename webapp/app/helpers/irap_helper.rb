PbsSite::App.helpers do
  def download_format(irap)
    text = ''
    text += "# Description\n####################################################\n\n"
    text += "# Description\n# #{ irap.description }\n\n"
    text += "# Name\nname=#{ irap.name }\n\n"
    text += "# Species\nspecies=#{ irap.species }\n\n"

    text += "# Files\n####################################################\n\n"
    text += "# Reference genome\nreference=#{ irap.reference }\n\n"
    text += "# Annotation file (GTF)\ngtf_file=#{ irap.annotation }\n\n"
    text += "# Experiment path\ndata_dir=#{ irap.path }\n\n"
    text += "# Contamination index\ncont_index=#{ irap.cont_path && !irap.cont_path.empty? ? irap.cont_path : 'no'}\n\n"

    text += "# Toolset\n####################################################\n\n"
    text += "# Mapper tool\n"
    text += irap.mapper && !irap.mapper.empty? ? "mapper=#{ irap.mapper }\n" : "# mapper=<none>\n"
    text += irap.mapper && !irap.mapper.empty? && irap.mapper_override && !irap.mapper_override.empty? ? "#{irap.mapper}_map_options=#{ irap.mapper_override }\n\n" : "# <mapper>_map_options=<none>\n\n"
    text += "# Quantification tool\n"
    text += irap.quant_method && !irap.quant_method.empty? ? "quant_method=#{ irap.quant_method }\n" : "# quant_method=<none>\n"
    text += irap.quant_method && !irap.quant_method.empty? && irap.quant_override && !irap.quant_override.empty? ? "#{irap.quant_method}_params=#{ irap.quant_override }\n\n" : "# <quant_method>_params=<none>\n\n"
    text += "# Differential expression tool\n"
    text += irap.de_method && !irap.de_method.empty? ? "de_method=#{ irap.de_method }\n\n" : "# de_method=<none>\n\n"
    text += "# Gene set enrichment tool\n"
    text += irap.gse_tool && !irap.gse_tool.empty? ? "gse_tool=piano\ngse_method=#{ irap.gse_tool }\n\n" : "# gse_tool=piano\n# gse_method=<none>\n\n"

    text += "# General\n####################################################\n\n"
    text += "# Quality filtering\nqual_filter=#{irap.qual_filter ? 'on' : 'off'}\n\n"
    text += "# Trim reads\ntrim_reads=#{irap.qual_filter && irap.trim_reads ? 'y' : 'n'}\n\n"
    text += "# Minimum read quality\nmin_read_quality=#{irap.min_read_qual}\n\n"
    text += "# Exon level quantification\nexon_quant=#{irap.exon_quant ? 'y' : 'n'}\n\n"
    text += "# Transcript level quantification\ntranscript_quant=#{irap.transcript_quant ? 'y' : 'n'}\n\n"
    text += "# Max number of threads\nmax_threads=#{irap.max_threads}\n\n"
    text += "# GSE minimum number of genes per set\n"
    text += irap.gse_tool && !irap.gse_tool.empty? ? "gse_minsize=#{irap.gse_minsize}\n\n" : "# gse_minsize<undef>"
    text += "# GSE p-value cut-off\n"
    text += irap.gse_tool && !irap.gse_tool.empty? ? "gse_pvalue=#{irap.gse_pvalue}\n\n" : "# gse_pvalue<undef>\n\n"

    text += "# Libraries\n####################################################\n\n"
    text += "# Libraries\n#\n"
    text += "# <name>=<space separated list of FASTQ files>\n"
    text += "# <name>_rs=<read size>\n"
    text += "# <name>_qual=<read quality (33 or 64)>\n"
    text += "# <name>_ins=<insert size (optional, uncomment if needed)>\n"
    text += "# <name>_sd=<standard deviation (optional, uncomment if needed)>\n\n"
    libraries = irap.libraries.split(',')
    libraries.each do |lib|
      text += "#{ lib }=\n"
      text += "#{ lib }_rs=\n"
      text += "#{ lib }_qual=\n"
      text += "# #{ lib }_ins=\n"
      text += "# #{ lib }_sd=\n\n"
    end
    text += "# Library pairing\n"
    text += "se=<space separated list of all single ending libraries>\n"
    text += "pe=<space separated list of all paired ending libraries>\n\n"

    text += "# Groups\n#\n"
    text += "# <name>=<space separated list of library names>\n\n"
    groups = irap.groups.split(',')
    groups.each do |group|
      text += "#{ group }=\n"
    end

    text += "\n# Contrasts\n"
    text += irap.contrasts && !irap.contrasts.empty? ? "contrasts=#{ irap.contrasts.gsub(',', ' ') }\n\n" : "# contrasts=<none>\n\n"

    text += "# Contrast definitions\n#\n"
    text += "# <name>=<space separated list of group names>\n\n"
    contrasts = irap.contrasts.split(',')
    contrasts.each do |contrast|
      text += "#{ contrast }=\n"
    end

    text
  end
end
