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
    text += "# Mapper tool \nmapper=#{ irap.mapper }\n" if irap.mapper && !irap.mapper.empty?
    text += "#{irap.mapper}_map_options=#{ irap.mapper_override }\n\n" if irap.mapper && !irap.mapper.empty? && irap.mapper_override && !irap.mapper_override.empty?
    text += "# \n=#{}\n\n"
    text += "# \n=#{}\n\n"
    text += "# \n=#{}\n\n"
    text += "# \n=#{}\n\n"
    text += "# \n=#{}\n\n"

    text += "# Libraries\n####################################################\n\n"

    text += "# General\n####################################################\n\n"
    text += "# \n=#{}\n\n"
    text += "# \n=#{}\n\n"
    text += "# \n=#{}\n\n"
    text += "# \n=#{}\n\n"
    text += "# \n=#{}\n\n"
    text += "# \n=#{}\n\n"
    text += "# \n=#{}\n\n"
    text
  end
end
