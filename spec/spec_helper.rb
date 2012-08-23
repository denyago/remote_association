require 'rspec'
require "database_cleaner"
require 'fake_web'

require 'remote_association'

require 'yaml'
require 'active_resource'

RSpec.configure do |config|
  config.color_enabled = true

  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    FakeWeb.allow_net_connect = false
  end

  config.after(:suite) do
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.clean
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end

root      = File.dirname(__FILE__)
db_config = YAML.load_file("#{root}/config/database.yml")
ActiveRecord::Base.establish_connection(db_config)

def add_user(id, name)
  ActiveRecord::Base.connection.execute("insert into \"public\".\"users\" (\"id\", \"name\") values ( #{id}, '#{name}');")
end
