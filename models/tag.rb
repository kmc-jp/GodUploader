class Tag < ActiveRecord::Base
  has_many :illust_tags
  has_many :illusts, :through => :illust_tags
  has_many :folderstags
  has_many :folders, :through => :folderstags
end
