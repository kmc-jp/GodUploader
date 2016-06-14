class Folderstag < ActiveRecord::Base
  belongs_to :folder
  belongs_to :tag
end
