# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20110329222526) do

  create_table "article_genes", :force => true do |t|
    t.integer "article_id"
    t.integer "gene_id"
  end

  add_index "article_genes", ["article_id", "gene_id"], :name => "index_article_genes_on_article_id_and_gene_id", :unique => true

  create_table "article_subjects", :force => true do |t|
    t.integer "article_id"
    t.integer "subject_id"
  end

  add_index "article_subjects", ["article_id"], :name => "index_article_subjects_on_article_id"
  add_index "article_subjects", ["subject_id", "article_id"], :name => "index_article_subjects_on_subject_id_and_article_id", :unique => true

  create_table "articles", :force => true do |t|
    t.text   "title"
    t.string "source"
    t.date   "pubdate"
  end

  create_table "gene_subjects", :force => true do |t|
    t.integer "gene_id"
    t.integer "subject_id"
    t.integer "articles_count", :default => 0
  end

  add_index "gene_subjects", ["gene_id", "articles_count"], :name => "index_gene_subjects_on_gene_id_and_articles_count"
  add_index "gene_subjects", ["subject_id", "articles_count"], :name => "index_gene_subjects_on_subject_id_and_articles_count"

  create_table "genes", :force => true do |t|
    t.integer "taxonomy_id"
    t.string  "symbol"
    t.string  "name"
    t.string  "chromosome"
    t.string  "map_location"
    t.integer "articles_count", :default => 0
    t.integer "start_position"
    t.integer "end_position"
  end

  add_index "genes", ["articles_count"], :name => "index_genes_on_articles_count"
  add_index "genes", ["symbol"], :name => "index_genes_on_symbol"
  add_index "genes", ["taxonomy_id", "articles_count"], :name => "index_genes_on_taxonomy_id_and_articles_count"

  create_table "mesh_entry_terms", :force => true do |t|
    t.integer "subject_id"
    t.string  "term"
  end

  add_index "mesh_entry_terms", ["subject_id"], :name => "index_mesh_entry_terms_on_subject_id"
  add_index "mesh_entry_terms", ["term"], :name => "index_mesh_entry_terms_on_term"

  create_table "subjects", :force => true do |t|
    t.string "term"
  end

  add_index "subjects", ["term"], :name => "index_subjects_on_term"

end
