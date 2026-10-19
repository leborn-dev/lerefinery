# frozen_string_literal: true
require 'minitest/autorun'
require 'rubygems'

class DependencyPolicyTest < Minitest::Test
  def test_packaged_core_rejects_known_unsafe_rails_releases
    spec = Gem::Specification.load(File.expand_path('../../core/refinerycms-core.gemspec', __dir__))
    %w[actionpack activerecord railties].each do |name|
      requirement = spec.dependencies.find { |dependency| dependency.name == name }.requirement
      %w[6.1.7.10 7.0.10 7.1.6 7.2.3.2 8.0.0 8.0.0.1 8.0.1 8.0.2 8.0.2.1 8.0.3 8.0.4 8.0.4.1 8.0.5 8.1.0 8.1.1 8.1.2 8.1.2.1 8.1.3].each do |version|
        refute requirement.satisfied_by?(Gem::Version.new(version)), "#{name} accepted #{version}"
      end
      %w[7.2.4 8.0.5.1 8.1.3.1 8.1.4].each do |version|
        assert requirement.satisfied_by?(Gem::Version.new(version)), "#{name} rejected #{version}"
      end
    end
  end
end
