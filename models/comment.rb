class Comment < ActiveRecord::Base
  belongs_to :illust
  belongs_to :account
end
