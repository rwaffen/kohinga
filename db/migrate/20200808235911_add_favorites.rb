class AddFavorites < ActiveRecord::Migration[6.0]
  def change
    add_column :images, :favorite, :boolean
  end
end
