# Run with: bundle exec ruby spec/security/ruby_security_test.rb
require 'bundler/setup'
require 'minitest/autorun'
require 'erb'
require 'pathname'
require 'tmpdir'
require 'rails'
require 'action_controller/railtie'
require 'active_record'
require 'rack/test'
require_relative '../../core/lib/refinery/extension_generation'

module Refinery
  module Core
    class << self
      attr_accessor :matomo_analytics_server, :matomo_analytics_site_id
    end
  end
end

class MatomoSecurityTest < Minitest::Test
  def render(server)
    Refinery::Core.matomo_analytics_server = server
    Refinery::Core.matomo_analytics_site_id = '1'
    ERB.new(File.read(File.expand_path('../../core/app/views/refinery/_matomo_analytics.html.erb', __dir__)), trim_mode: '-').result(binding)
  end
  def local_request?; false; end
  def admin?; false; end
  def test_only_exact_placeholder_is_suppressed
    assert_includes render('analyticsXexampleYorg'), 'setTrackerUrl'
    refute_includes render('analytics.example.org'), 'setTrackerUrl'
    refute_includes render(''), 'setTrackerUrl'
    assert_includes render('analytics.example.org.attacker.test'), 'setTrackerUrl'
    assert_includes render("analytics.example.org\n.attacker.test"), 'setTrackerUrl'
    assert_includes render('stats.example.org'), 'setTrackerUrl'
  end
end

class MigrationSecurityTest < Minitest::Test
  def test_only_migration_template_suffix_is_incremented
    Dir.mktmpdir do |dir|
      FileUtils.mkdir_p(File.join(dir, 'db/migrate'))
      File.write(File.join(dir, 'db/migrate/20260101000000_create_old.rb'), '')
      generator = Object.new.extend(Refinery::ExtensionGeneration)
      generator.define_singleton_method(:destination_pathname) { Pathname.new(dir) }
      path = Pathname.new('db/migrate/20250101000000_create_new.rb.erb')
      assert_equal 'db/migrate/20260101000001_create_new.rb.erb', generator.send(:increment_migration_timestamp, path).to_s
      invalid = Pathname.new('db/migrate/20250101000000_create_new.rbXerb')
      assert_equal invalid, generator.send(:increment_migration_timestamp, invalid)
      adversarial = Pathname.new('db/migrate/' + '1' * 100_000 + 'no_suffix')
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      assert_equal adversarial, generator.send(:increment_migration_timestamp, adversarial)
      assert_operator Process.clock_gettime(Process::CLOCK_MONOTONIC) - started, :<, 1
    end
  end
end

class SecurityTestApplication < Rails::Application
  config.eager_load = false
  config.secret_key_base = 'security-regression-isolated-test-only' * 3
  config.hosts.clear
  config.action_controller.allow_forgery_protection = true
  # A mountable CMS must protect requests even in a host opting out of Rails defaults.
  config.action_controller.default_protect_from_forgery = false
  config.logger = Logger.new(File::NULL)
end
SecurityTestApplication.initialize!
require_relative '../../core/app/controllers/application_controller'
require_relative '../../core/app/controllers/refinery/fast_controller'
class SecurityApplicationProbeController < ::ApplicationController
  def token; render plain: form_authenticity_token; end
  def write; self.class.writes += 1; render plain: 'saved'; end
  class_attribute :writes, default: 0
end
class SecurityFastProbeController < Refinery::FastController
  def token; render plain: form_authenticity_token; end
  def write; self.class.writes += 1; render plain: 'saved'; end
  class_attribute :writes, default: 0
end
Rails.application.routes.draw do
  get '/application', to: 'security_application_probe#token'
  post '/application', to: 'security_application_probe#write'
  get '/fast', to: 'security_fast_probe#token'
  post '/fast', to: 'security_fast_probe#write'
end
class ControllerSecurityTest < Minitest::Test
  include Rack::Test::Methods
  def app; Rails.application; end
  def test_application_rejects_forged_writes_and_accepts_valid_token
    check_csrf('/application', SecurityApplicationProbeController)
  end
  def test_fast_rejects_forged_writes_and_accepts_valid_token
    check_csrf('/fast', SecurityFastProbeController)
  end
  def check_csrf(path, controller)
    original = controller.writes
    post path
    assert_equal 422, last_response.status
    assert_equal original, controller.writes
    get path
    assert last_response.ok?, last_response.body
    token = last_response.body
    post path, {authenticity_token: token}
    assert last_response.ok?, last_response.body
    assert_equal original + 1, controller.writes
  end
end

module Mobility
  def self.locale; :en; end
end
module Refinery
  class Page < ActiveRecord::Base
    self.table_name = 'security_pages'
    has_many :translations, class_name: 'Refinery::Page::Translation', foreign_key: :page_id
    def self.mobility_attributes; ['title', 'slug']; end
    def self.i18n; all; end
    class Translation < ActiveRecord::Base
      self.table_name = 'security_translations'
    end
  end
end
require_relative '../../pages/lib/refinery/pages/finder'
class FinderSecurityTest < Minitest::Test
  def setup
    ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
    ActiveRecord::Schema.define do
      create_table(:security_pages) { |t| t.string :name }
      create_table(:security_translations) { |t| t.integer :page_id; t.string :title; t.string :slug; t.string :locale }
    end
    @page = Refinery::Page.create!(name: 'sample')
    @page.translations.create!(title: 'public', slug: 'public', locale: 'en')
  end
  def test_translation_conditions_are_bound_hash_values_not_sql
    finder = Refinery::Pages::Finder
    payload = "' OR 1=1 --"
    assert_empty finder.new(title: payload).find.to_a
    assert_equal [@page], finder.new(title: 'public').find.to_a
    assert_empty finder.new(locale: payload).find.to_a
    assert_empty finder.new(slug: payload).find.to_a
    assert_empty finder.new(name: payload).find.to_a
    assert_equal [@page], finder.new(locale: ['en', 'fr']).find.to_a
    @page.translations.create!(title: payload, slug: payload, locale: 'fr')
    assert_equal [@page], finder.new(title: payload, locale: 'fr').find.to_a
    assert_equal 1, Refinery::Page.count
  end
end
