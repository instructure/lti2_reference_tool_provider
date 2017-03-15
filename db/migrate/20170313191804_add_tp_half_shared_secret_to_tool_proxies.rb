class AddTpHalfSharedSecretToToolProxies < ActiveRecord::Migration[5.0]
  def up
    add_column :tool_proxies, :tp_half_shared_secret, :string
    change_column :tool_proxies, :tp_half_shared_secret, :string, null: false
  end

  def down
    remove_column :tool_proxies, :tp_half_shared_secret
  end
end
