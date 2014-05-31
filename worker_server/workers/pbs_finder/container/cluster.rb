module Pbs
  module Container
    # Contains basic information about a clustering attempt.
    class Cluster
      attr_accessor(
        :silhouette,
        :gene_silhouette,
        :n_clusters,
        :gene_n_clusters,
        :algorithm,
        :clusters,
        :gene_clusters,
        :attrs,
        :df_type,
        :protein_sims,
        :gene_sims
      )

      def initialize(params = {})
        @df_type = params.fetch(:df_type, nil)
        @attrs = params.fetch(:attrs, [])
        @silhouette = params.fetch(:silhouette, 0.0)
        @gene_silhouette = params.fetch(:gene_silhouette, 0.0)
        @n_clusters = params.fetch(:n_clusters, {})
        @gene_n_clusters = params.fetch(:gene_n_clusters, {})
        @algorithm = params.fetch(:algorithm, nil)
        @clusters = params.fetch(:clusters, {})
        @gene_clusters = params.fetch(:gene_clusters, {})
        @gene_sims = params.fetch(:gene_sims, {})
        @protein_sims = params.fetch(:protein_sims, {})
      end
    end
  end
end
