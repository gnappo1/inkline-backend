class UserMiniSerializer < ApplicationSerializer
  set_type :users
  attributes :id, :first_name, :last_name
end