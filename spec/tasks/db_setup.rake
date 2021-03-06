require 'active_record'
require 'yaml'

namespace :spec do
  namespace :db do
    desc "Setup DB for tests"
    task :setup do
      puts "Create database\n"
      Rake::Task["spec:db:create"].invoke
      puts "Migrate database\n"
      Rake::Task["spec:db:migrate"].invoke
    end

    desc "Add tables required for tests"
    task :migrate do
      ActiveRecord::Base.establish_connection(db_config)

      ActiveRecord::Base.connection.execute(<<SQL
DROP TABLE IF EXISTS "public"."users";

CREATE TABLE "public"."users" (
	"id" int4 NOT NULL,
	"name" varchar(255) NOT NULL,
	CONSTRAINT "users_pkey" PRIMARY KEY ("id") NOT DEFERRABLE INITIALLY IMMEDIATE
)
WITH (OIDS=FALSE);
ALTER TABLE "public"."users" OWNER TO "rails";

DROP TABLE IF EXISTS "public"."profiles";

CREATE TABLE "public"."profiles" (
	"id" int4 NOT NULL,
	"user_id" int4,
	"like" varchar(255) NOT NULL,
	CONSTRAINT "profiles_pkey" PRIMARY KEY ("id") NOT DEFERRABLE INITIALLY IMMEDIATE
)
WITH (OIDS=FALSE);
ALTER TABLE "public"."profiles" OWNER TO "rails";

DROP TABLE IF EXISTS "public"."polymorphic_profiles";

CREATE TABLE "public"."polymorphic_profiles" (
	"id" int4 NOT NULL,
	"owner_id" int4,
	"owner_type" varchar(255) NOT NULL,
	"like" varchar(255) NOT NULL,
	CONSTRAINT "polymorphic_profiles_pkey" PRIMARY KEY ("id") NOT DEFERRABLE INITIALLY IMMEDIATE
)
WITH (OIDS=FALSE);
ALTER TABLE "public"."polymorphic_profiles" OWNER TO "rails";
SQL
                                     )
    end

    desc "Create DB for tests"
    task :create do
      encoding = db_config[:encoding] || ENV['CHARSET'] || 'utf8'
      begin
        ActiveRecord::Base.establish_connection(db_config.merge('database' => 'postgres', 'schema_search_path' => 'public'))
        ActiveRecord::Base.connection.drop_database(db_config['database']) and puts "previously dropping DB..." if db_present?
        ActiveRecord::Base.connection.create_database(db_config['database'], db_config.merge('encoding' => encoding))
        ActiveRecord::Base.establish_connection(db_config)
      rescue
        $stderr.puts $!, *($!.backtrace)
        $stderr.puts "Couldn't create database for #{db_config.inspect}"
      end
    end

    def db_config
      root    = File.expand_path('../../', __FILE__)
      @db_conf ||= YAML.load_file("#{root}/config/database.yml")
    end

    def db_present?
      ActiveRecord::Base.connection.execute("SELECT count(*) FROM pg_database where datname = '#{db_config['database']}'").values.flatten.first.to_i == 1
    end
  end
end
