class CreateMeshEntryTerms < ActiveRecord::Migration
  def self.up
    create_table :mesh_entry_terms do |t|
      t.integer :subject_id
      t.string :term
    end
    add_index :mesh_entry_terms, :subject_id
    add_index :mesh_entry_terms, :term
  end

  def self.down
    drop_table :mesh_entry_terms
  end
end
