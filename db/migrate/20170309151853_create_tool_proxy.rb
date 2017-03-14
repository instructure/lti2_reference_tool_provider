class CreateToolProxy < ActiveRecord::Migration[5.0]
  def change
    create_table :tool_proxies do |t|
      t.string :guid, null: false
      t.string :shared_secret, null: false
      t.string :tcp_url, null: false
      t.string :base_url, null: false
    end
  end
end
