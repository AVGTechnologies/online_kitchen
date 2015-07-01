class CreateMachines < ActiveRecord::Migration
  def change
    create_table :machines do |t|
      t.string :name
      t.string :template
      t.string :state,     default: 'queued'

      t.string :ip #TODO check inet type
      t.string :provider_id

      t.text :environment
      t.references :configuration

      t.timestamps null: false
    end
  end
end
