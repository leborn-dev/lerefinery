# frozen_string_literal: true
require 'logger'
require 'minitest/autorun'
require 'active_record'
require 'sqlite3'

class SqliteAdapterCompatibilityTest < Minitest::Test
  def test_normal_model_types_crud_and_transactions
    ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
    connection = ActiveRecord::Base.connection
    connection.create_table(:security_records) do |t|
      t.string :title
      t.integer :count
      t.decimal :price, precision: 10, scale: 2
      t.boolean :enabled
      t.binary :payload
      t.datetime :created_at
    end
    model = Class.new(ActiveRecord::Base) { self.table_name = 'security_records' }
    record = model.create!(title: '<literal>', count: 7, price: '12.34', enabled: true, payload: "a\x00b".b, created_at: Time.utc(2026, 10, 19))
    record.reload
    assert_equal ['<literal>', 7, BigDecimal('12.34'), true, "a\x00b".b], [record.title, record.count, record.price, record.enabled, record.payload]
    assert_equal Time.utc(2026, 10, 19), record.created_at
    record.update!(count: 8)
    assert_equal 8, model.find(record.id).count
    model.transaction do
      record.update!(title: 'rolled back')
      raise ActiveRecord::Rollback
    end
    assert_equal '<literal>', record.reload.title
    record.destroy!
    assert_equal 0, model.count
  ensure
    ActiveRecord::Base.connection_pool.disconnect! if ActiveRecord::Base.connected?
  end

  def test_standard_custom_function_and_aggregate
    db = SQLite3::Database.new(':memory:')
    db.define_function('add_two') { |a, b| a + b }
    assert_equal [[5]], db.execute('select add_two(?, ?)', [2, 3])
    db.execute('create table pairs(a integer, b integer)')
    db.execute('insert into pairs values (?, ?)', [2, 3])
    db.execute('insert into pairs values (?, ?)', [4, 5])
    db.create_aggregate('pair_sum', 2) do
      step { |context, a, b| context[:sum] = (context[:sum] || 0) + a + b }
      finalize { |context| context.result = context[:sum] }
    end
    assert_equal [[14]], db.execute('select pair_sum(a, b) from pairs')
    assert_operator Gem.loaded_specs.fetch('sqlite3').version, :>=, Gem::Version.new('2.9.6')
  ensure
    db&.close
  end
end
