class Folder < ActiveRecord::Base
  belongs_to :account
  has_many :illusts
  has_many :folderstags
  has_many :tags, :through => :folderstags
  has_many :comments
  has_many :likes
end
