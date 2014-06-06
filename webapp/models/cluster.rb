class Cluster
  include Mongoid::Document
  embedded_in :job

  field :gene_clusters,       type: Hash, default: {}
  field :protein_clusters,    type: Hash, default: {}
  field :gene_attrs,          type: Hash, default: {}
  field :protein_attrs,       type: Hash, default: {}
  field :type,                type: Symbol, default: :by_function
end
