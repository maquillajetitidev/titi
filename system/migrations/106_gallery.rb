Sequel.migration do
  up do
    run 'RENAME TABLE fotos to gallery;'
    rename_column :gallery, :id, :e_id;
    rename_column :gallery, :photo, :e_photo;
    rename_column :gallery, :title, :e_title;
    rename_column :gallery, :desc, :e_description;
    rename_column :gallery, :page, :e_url;
    rename_column :gallery, :active, :e_is_active;
  end

  down do
  end
end
