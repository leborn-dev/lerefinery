# This standalone regression also runs on Ruby 3.1, before regexp memoization.
require 'minitest/autorun'
require 'pathname'
require 'tmpdir'
require 'fileutils'
require_relative '../../core/lib/refinery/extension_generation'

class MigrationComplexityTest < Minitest::Test
  def test_preserves_numeric_parent_directory_names
    Dir.mktmpdir do |dir|
      FileUtils.mkdir_p(File.join(dir, 'engine_2026_10/db/migrate'))
      File.write(File.join(dir, 'engine_2026_10/db/migrate/4_create_old.rb'), '')
      generator = Object.new.extend(Refinery::ExtensionGeneration)
      generator.define_singleton_method(:destination_pathname) { Pathname.new(dir) }
      path = Pathname.new('engine_2026_10/db/migrate/1_create_new.rb.erb')
      assert_equal Pathname.new('engine_2026_10/db/migrate/5_create_new.rb.erb'), generator.send(:increment_migration_timestamp, path)
    end
  end

  def test_uses_the_highest_migration_number_after_ten_generation_events
    Dir.mktmpdir do |dir|
      FileUtils.mkdir_p(File.join(dir, 'db/migrate'))
      (1..10).each { |number| File.write(File.join(dir, "db/migrate/#{number}_create_existing.rb"), '') }
      generator = Object.new.extend(Refinery::ExtensionGeneration)
      generator.define_singleton_method(:destination_pathname) { Pathname.new(dir) }
      path = Pathname.new('db/migrate/1_create_new.rb.erb')
      assert_equal Pathname.new('db/migrate/11_create_new.rb.erb'), generator.send(:increment_migration_timestamp, path)
    end
  end

  def test_ignores_non_migration_ruby_files
    Dir.mktmpdir do |dir|
      FileUtils.mkdir_p(File.join(dir, 'db/migrate'))
      File.write(File.join(dir, 'db/migrate/4_create_old.rb'), '')
      File.write(File.join(dir, 'db/migrate/zzz_notes.rb'), '')
      generator = Object.new.extend(Refinery::ExtensionGeneration)
      generator.define_singleton_method(:destination_pathname) { Pathname.new(dir) }
      path = Pathname.new('db/migrate/1_create_new.rb.erb')
      assert_equal Pathname.new('db/migrate/5_create_new.rb.erb'), generator.send(:increment_migration_timestamp, path)
    end
  end

  def test_long_digits_with_a_template_suffix_do_not_trigger_unanchored_replacement
    Dir.mktmpdir do |dir|
      FileUtils.mkdir_p(File.join(dir, 'db/migrate'))
      File.write(File.join(dir, 'db/migrate/20260101000000_create_old.rb'), '')
      generator = Object.new.extend(Refinery::ExtensionGeneration)
      generator.define_singleton_method(:destination_pathname) { Pathname.new(dir) }
      path = Pathname.new('db/migrate/' + '1' * 100_000 + '.rb.erb')
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      assert_equal path, generator.send(:increment_migration_timestamp, path)
      elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
      assert_operator elapsed, :<, 1, "timestamp replacement took #{elapsed}s"
    end
  end

  def test_long_non_migration_name_is_rejected_in_linear_time
    Dir.mktmpdir do |dir|
      FileUtils.mkdir_p(File.join(dir, 'db/migrate'))
      generator = Object.new.extend(Refinery::ExtensionGeneration)
      generator.define_singleton_method(:destination_pathname) { Pathname.new(dir) }
      path = Pathname.new('db/migrate/' + '1' * 100_000 + 'no_suffix')
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      assert_equal path, generator.send(:increment_migration_timestamp, path)
      elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
      assert_operator elapsed, :<, 1, "filename classification took #{elapsed}s"
    end
  end
end
