class Product < ApplicationRecord
  validates :name, :url, presence: true
  validates :url, uniqueness: true

  has_many :connections, dependent: :destroy
  has_many :categories, through: :connections
end
