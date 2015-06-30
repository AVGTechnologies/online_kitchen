class CreateConfigurations < ActiveRecord::Migration
  def change
    create_table :configurations do |t|
      t.string :name, null: false, default: ""
      t.string :folder_name
      t.string :user, null: false, default: ""

      t.timestamps null: false
    end

    add_index :configurations, :name, unique: true
  end
end
