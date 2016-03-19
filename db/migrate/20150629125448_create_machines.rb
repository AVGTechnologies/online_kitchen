# Migration class to create machines
class CreateMachines < ActiveRecord::Migration
  def change
    create_table :machines do |t|
      t.string :name
      t.string :image
      t.string :state, default: 'queued'

      t.string :ip # TODO: check inet type
      t.string :provider_id

      t.text :environment
      t.references :configuration

      t.timestamps null: false
    end
  end
end
