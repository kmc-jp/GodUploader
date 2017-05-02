class Like < ActiveRecord::Base
  belongs_to :account
  belongs_to :illust
  belongs_to :folder
end
