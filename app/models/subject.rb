require Meshcomplete::Engine.root.join('app', 'models', 'subject')
class Subject < ActiveRecord::Base
  has_many :article_subjects
  has_many :gene_subjects
end
