class AddClusterToMachines < ActiveRecord::Migration
  def change
    add_column :machines, :cluster, :string
  end
end
