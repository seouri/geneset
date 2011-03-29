class Subject < ActiveRecord::Base
  has_many :article_subjects
  has_many :gene_subjects
  has_many :mesh_entry_terms
end
