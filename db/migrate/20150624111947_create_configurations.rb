class CreateConfigurations < ActiveRecord::Migration
  def change
    create_table :configurations do |t|
      t.string      :name,        null: false, default: ""
      t.string      :folder_name

      t.references  :user
      t.boolean     :deleted,   null: false, default: false

      t.timestamps null: false
    end

    add_index :configurations, :name, unique: true
  end
end
