require 'active_record'
require './models/account.rb'
require './models/folder.rb'

ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: 'god.db'
)
ActiveRecord::Base.logger = Logger.new(STDOUT)

all_accounts_with_folders = Account.all.includes(:folders)

all_accounts_with_folders.each {|account|
  folders_count = account.folders.size
  p [account.kmcid, folders_count]

  account.folders_count = folders_count
  account.save
}
