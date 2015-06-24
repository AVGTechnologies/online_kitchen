class CreateConfigurations < ActiveRecord::Migration
  def change
    create_table :configurations do |t|
      t.string :name

      t.timestamps null: false
    end
  end
end
