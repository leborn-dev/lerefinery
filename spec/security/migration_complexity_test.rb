# This standalone regression also runs on Ruby 3.1, before regexp memoization.
require 'minitest/autorun'
require 'pathname'
require 'tmpdir'
require 'fileutils'
require_relative '../../core/lib/refinery/extension_generation'

class MigrationComplexityTest < Minitest::Test
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
