class Account < ActiveRecord::Base
  has_many :folders
  has_many :illusts
  has_many :likes
  has_many :comments
end
