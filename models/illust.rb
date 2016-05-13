class Illust < ActiveRecord::Base
  belongs_to :account
  has_many :illust_tags
  has_many :tags, :through => :illust_tags
  has_many :comments
  has_many :likes
end
