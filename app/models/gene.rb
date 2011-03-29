class Gene < ActiveRecord::Base
  has_many :article_genes
  has_many :gene_subjects
end
