class Article < ActiveRecord::Base
  has_many :article_genes
  has_many :article_subjects
end
