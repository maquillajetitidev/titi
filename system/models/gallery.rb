require 'sequel'

class Gallery < Sequel::Model(:gallery)
  ATTRIBUTES = [:e_id, :e_photo, :e_title, :e_description, :e_url, :e_is_active]
  # same as ATTRIBUTES but with the neccesary table references for get_ functions
  COLUMNS = [:e_id, :e_photo, :e_title, :e_description, :e_url, :e_is_active]


end
