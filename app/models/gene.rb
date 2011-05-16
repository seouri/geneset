class Gene < ActiveRecord::Base
  belongs_to :taxonomy
  has_many :article_genes
  has_many :gene_subjects, :order => "articles_count desc", :include => :subject, :limit => 20
  has_many :subjects, :through => :gene_subjects, :order => "gene_subjects.articles_count desc", :limit => 20
  
  attr_accessor :matched_articles_count
end
