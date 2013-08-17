require 'database_cleaner'
require 'yaml'


class SpecManager
  attr_reader :env

  # @param [String] env
  def initialize(env = 'default')
    @env = env.to_s
  end

  def init!
    database_config or raise 'Wrong database configuration, please specify spec/support/config/database.yml'
    create_database
    establish_db_connection
    migrate_database
  end

  def create_database
    establish_postgres_connection
    ActiveRecord::Base.connection.create_database(database_config['database'])
  end

  def drop_database
    establish_postgres_connection
    ActiveRecord::Base.connection.drop_database(database_config['database'])
  end

  # @return [Hash]
  def database_config
    @database_config ||= YAML.load_file('spec/support/config/database.yml')[env]
  end


  private

  def establish_db_connection
    ActiveRecord::Base.establish_connection(database_config)
  end

  # @param [Integer, nil] version
  def migrate_database(version = nil)
    ActiveRecord::Migrator.migrate "spec/support/migrations", version.try(:to_i)
  end

  def establish_postgres_connection
    if database_config['adapter'] == 'postgresql'
      ActiveRecord::Base.establish_connection(database_config.merge('database' => 'postgres',
                                                                    'schema_search_path' => 'public'))
    end
  end
end