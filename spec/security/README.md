# Security regressions

Use an isolated development installation and SQLite; these tests never need a
production database. The repository and public core gem now require Rails 7.2.4
or a patched Rails 8 release. See [the security upgrade guide](../../SECURITY_UPGRADE.md)
for the breaking dependency minimum, per-series floors and decorators pin.
`RAILS_VERSION` selects supported compatibility test versions.

```sh
bundle install
bundle exec bundler-audit check --update
ruby spec/security/dependency_policy_test.rb
bundle exec ruby spec/security/sqlite_adapter_compatibility_test.rb
bundle exec ruby spec/security/ruby_security_test.rb
ruby spec/security/migration_complexity_test.rb
npm ci --prefix spec/security --ignore-scripts
npm audit --prefix spec/security
npm test --prefix spec/security
JQUERY_UI_ROOT="$(bundle show jquery-ui-rails)/app/assets/javascripts/jquery-ui" node --test spec/security/jquery-ui.test.cjs
bundle exec rake refinery:testing:dummy_app
bundle exec rspec core/spec/lib core/spec/controllers pages/spec/models/refinery/page_finder_spec.rb
```

The DOM tests execute the actual plugin and jQuery UI source in jsdom; only text
measurement is replaced, because jsdom does not implement browser layout.
Untrusted body text must remain a text node. A caller-supplied HTML tail remains
supported. The jQuery UI regression checks the published CVE-2022-31160 label
refresh case against the actual gem asset, not a replacement widget.

The Ruby regression executes real Rails request handling, ActiveRecord/SQLite,
ERB, and the extension generator. It checks tokenless writes, valid CSRF tokens,
exact Matomo placeholder matching, and bounded migration filename checks. The
additional RSpec regressions use the actual CMS controller inheritance and the
actual Mobility-backed Page model. The standalone migration complexity test also
runs on Ruby 3.1, where regexp memoization does not mask the original quadratic
backtracking. Its 100,000-digit case exceeded ten seconds before the fix and
completed in milliseconds after it.

## CodeQL findings with existing protection

- `rb/sql-injection` in `pages/lib/refinery/pages/finder.rb`: the value passed to
  `where` is a Hash, built only for translated attribute names and `locale`.
  ActiveRecord binds/quotes the values; no user string becomes SQL structure.
  Both the isolated SQLite regression and the CMS/Mobility regression check SQL
  metacharacters in title, slug, and locale, plus normal title and locale-array
  searches. No suppression or alert dismissal is needed to establish this.
- `rb/csrf-protection-not-enabled` in `Refinery::AdminController`: including
  `Refinery::ApplicationController` calls `protect_from_forgery with: :exception`
  on the controller. The controller spec demonstrates that this inherited
  callback rejects tokenless POSTs before the action and accepts valid tokens.
  Authentication callbacks remain in the production controller.

ApplicationController and FastController now declare exception-based CSRF
protection explicitly, including for host applications that opt out of Rails'
default protection. FastController's existing message route remains GET-only.

`jquery-ui-rails` 8.0.1 ships jQuery UI 1.14.2 and fixes CVE-2022-31160. No vendored
fork, package renaming, ignored advisory, or scan suppression is involved.
