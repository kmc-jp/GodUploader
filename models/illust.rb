class Illust < ActiveRecord::Base
  belongs_to :account
  has_many :tags, through: :illuts_tags
  has_many :comments
end
