class Comment < ActiveRecord::Base
  belongs_to :illust
  belongs_to :account
  belongs_to :folder
end
