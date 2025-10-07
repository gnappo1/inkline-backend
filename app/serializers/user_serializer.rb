class UserSerializer < ApplicationSerializer
  set_type :users

  attributes :first_name, :last_name, :role, :created_at, :updated_at

  # show email by default; if you want to hide except for self:
  attribute :email, if: Proc.new { |user, params| params && params[:current_user]&.id == user.id}

  has_many :notes, if: Proc.new { |_user, params| Array(params&.dig(:include)).include?("notes")}
end
