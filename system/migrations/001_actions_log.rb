Sequel.migration do
  up do
    create_table! (:actions_log) do
      primary_key :id
      column :at,  :datetime
      column :msg,  String, null: false, default: ""
      column :lvl, 'int(5) UNSIGNED', default: 0, index: true
      column :b_id, String, fixed: true, size: 17, null: true, index: true
      column :m_id, 'int(5) UNSIGNED', null: true, index: true
      column :i_id, String, fixed: true, size: 17, null: true, index: true
      column :p_id, 'int(5) UNSIGNED', null: true, index: true
      column :o_id, 'int(5) UNSIGNED', null: true, index: true
      column :u_id, 'int(5) UNSIGNED', null: true, index: true
      column :l_id, String, fixed: true, size: 12, null: true, index: true
    end
    alter_table(:actions_log) do
      add_foreign_key [:b_id], :bulks    , name: :bulk_id, on_delete: :restrict
      add_foreign_key [:m_id], :materials, name: :mate_id, on_delete: :restrict
      add_foreign_key [:i_id], :items    , name: :item_id, on_delete: :restrict
      add_foreign_key [:p_id], :products , name: :prod_id, on_delete: :restrict
      add_foreign_key [:o_id], :orders   , name: :ordr_id, on_delete: :restrict
      add_foreign_key [:u_id], :users    , name: :user_id, on_delete: :restrict
      # add_foreign_key [:l_id], :locations, name: :loca_id, on_delete: :restrict
    end

    run '
      CREATE TRIGGER al_init BEFORE INSERT ON `actions_log`
      FOR EACH ROW SET
      NEW.at = IFNULL(NEW.at, NOW());
    '
  end

  down do
    drop_table? (:actions_log)
  end
end
