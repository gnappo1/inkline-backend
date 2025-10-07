class CategorySerializer < ApplicationSerializer
  set_type :categories

  attributes :name, :created_at, :updated_at
  has_many :notes, if: Proc.new { |_cat, params| Array(params&.dig(:include)).include?("notes")}
end
