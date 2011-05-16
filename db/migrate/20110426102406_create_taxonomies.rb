class CreateTaxonomies < ActiveRecord::Migration
  def self.up
    create_table :taxonomies do |t|
      t.string :name
      t.integer :genes_count
    end
  end

  def self.down
    drop_table :taxonomies
  end
end
