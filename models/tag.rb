class Tag < ActiveRecord::Base
  has_many :illusts, through: :illusts_tags
end
