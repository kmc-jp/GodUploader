class Account < ActiveRecord::Base
  has_many :illusts
  has_many :likes
end
