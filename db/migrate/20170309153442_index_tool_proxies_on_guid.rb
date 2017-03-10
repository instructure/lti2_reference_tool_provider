class IndexToolProxiesOnGuid < ActiveRecord::Migration[5.0]
  def change
    add_index :tool_proxies, :guid
  end
end
