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
    FakeWeb.clean_registry
  end
end

root      = File.dirname(__FILE__)
db_config = YAML.load_file("#{root}/config/database.yml")
ActiveRecord::Base.establish_connection(db_config)

def add_user(id, name)
  ActiveRecord::Base.connection.execute("insert into \"public\".\"users\" (\"id\", \"name\") values ( #{id}, '#{name}');")
end

def add_profile(id, user_id, like)
  ActiveRecord::Base.connection.execute("insert into \"public\".\"profiles\" (\"id\", \"user_id\", \"like\") values ( #{id}, #{user_id}, '#{like}');")
end

REMOTE_HOST = "http://127.0.0.1:3000"

def unset_const(const_name)
  const_name = const_name.to_sym
  const_owner = Module.constants.select { |c| c.to_s.constantize.constants(false).include?(const_name) rescue false }.first.to_s.constantize
  !const_owner.send(:remove_const, const_name) rescue true
end
