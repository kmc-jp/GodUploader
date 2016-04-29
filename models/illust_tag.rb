class IllustTag < ActiveRecord::Base
  belongs_to :illust
  belongs_to :tag
end
