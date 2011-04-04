class CreateSynonyms < ActiveRecord::Migration
  def self.up
    create_table :synonyms do |t|
      t.integer :subject_id
      t.string :term
    end
    add_index :synonyms, :subject_id
    add_index :synonyms, :term
  end

  def self.down
    drop_table :synonyms
  end
end
