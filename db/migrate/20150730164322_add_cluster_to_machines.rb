# Migration class to add cluster field to machines
class AddClusterToMachines < ActiveRecord::Migration
  def change
    add_column :machines, :cluster, :string
  end
end
