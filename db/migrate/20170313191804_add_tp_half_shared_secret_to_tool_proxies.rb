class AddTpHalfSharedSecretToToolProxies < ActiveRecord::Migration[5.0]
  def change
    add_column :tool_proxies, :tp_half_shared_secret, :string, null:false
  end
end
