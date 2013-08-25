require 'database_cleaner'
require 'yaml'


class SpecManager
  attr_reader :env

  # @param [String, Symbol] env
  def initialize(env = 'default')
    @env = env.to_s
  end

  # @param [Rspec::Config] config
  # @param [String, Symbol] env
  def self.manage(config, env)
    env ||= 'default'

    config.order = "random"

    config.include FactoryGirl::Syntax::Methods

    config.before(:each) do
      DatabaseCleaner.start
    end

    config.after(:each) do
      DatabaseCleaner.clean
    end

    spec_manager = self.new(env)

    config.before(:suite) do
      spec_manager.init!
    end

    config.after(:suite) do
      spec_manager.drop_database
    end
  end

  # @return [String]
  def db_adapter
    database_config['adapter']
  end

  def init!
    database_config or raise 'Wrong database configuration, please specify spec/support/config/database.yml'
    puts "Running specs with #{db_adapter}."
    create_database
    establish_db_connection
    migrate_database
    apply_cleaner_strategy
  end

  def db_connection
    ActiveRecord::Base.connection
  end

  def create_database
    establish_service_connection
    db_connection.create_database(database_config['database']) if db_connection.respond_to?(:create_database)
  end

  def drop_database
    establish_service_connection
    db_connection.drop_database(database_config['database']) if db_connection.respond_to?(:drop_database)
  end

  # @return [Hash]
  def database_config
    @database_config ||= YAML.load_file('spec/support/config/database.yml')[env]
  end


  private

  def apply_cleaner_strategy
    case db_adapter
      when 'postgresql', 'mysql', 'mysql2'
        DatabaseCleaner.strategy = :transaction
        DatabaseCleaner.clean_with(:truncation)
    end
  end

  def establish_db_connection
    ActiveRecord::Base.establish_connection(database_config)
  end

  # @param [Integer, nil] version
  def migrate_database version = nil
    ActiveRecord::Migrator.migrate "spec/support/migrations", version.try(:to_i)
  end

  def establish_service_connection
    case db_adapter
      when 'mysql', 'mysql2'
        ActiveRecord::Base.establish_connection(database_config.merge('database' => nil))
      when 'postgresql'
        ActiveRecord::Base.establish_connection(database_config.merge('database' => 'postgres',
                                                                      'schema_search_path' => 'public'))
      when 'sqlite3'
        ActiveRecord::Base.establish_connection(database_config)
    end
  end
end
