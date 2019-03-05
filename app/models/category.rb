class Category < ApplicationRecord
  acts_as_nested_set

  validates :url, presence: true
  validates :url, uniqueness: true

  has_many :connections, dependent: :destroy
  has_many :products, through: :connections
end
