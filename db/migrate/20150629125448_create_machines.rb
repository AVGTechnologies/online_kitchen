class CreateMachines < ActiveRecord::Migration
  def change
    create_table :machines do |t|
      t.string :name
      t.string :template
      t.text :environment
      t.references :configuration

      t.timestamps null: false
    end
  end
end
