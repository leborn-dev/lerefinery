# Security dependency upgrade (2026-10-19)

This change raises Refinery's minimum Rails version from 6.1 to **7.2.4**.
Applications on Rails 6.1, 7.0 or 7.1 must upgrade Rails before installing this
revision. No release is published by this source change.

A clean resolution of the former compatibility configurations found 13 advisory
results on Rails 6.1.7.10, 12 on 7.0.10, and 10 on 7.1.6. These counts overlap;
they are not distinct vulnerability totals. Retaining those test configurations
would keep installing known vulnerable dependencies. The legacy CI workflow is
therefore retired as an explicit support-policy change. The complete existing
7.2 / 8.0 / 8.1 × Ruby × database × CMS component matrix remains in CI.

Current accepted Rails floors are 7.2.4, 8.0.5.1 and 8.1.3.1. The latest reviewed
[official Rails advisory](https://github.com/rails/rails/security/advisories/GHSA-xr9x-r78c-5hrm)
fixes its issue in 7.2.3.2, 8.0.5.1 and 8.1.3.1; 7.2.4 also includes that fix.
The Rails component gemspec requirements reject the published vulnerable Rails 8
stable versions explicitly because RubyGems requirements cannot express the union
of three disjoint supported ranges. Future unpublished versions and prereleases
have not been certified; continue to audit the complete resolved application
bundle. Existing lockfiles must be updated, not just the manifest.

SQLite development/test bundles and newly generated extensions require the
unmodified official `sqlite3 >= 2.9.6` gem. Its binding fixes
[GHSA-28hh-pr2h-2w89](https://github.com/sparklemotion/sqlite3-ruby/security/advisories/GHSA-28hh-pr2h-2w89)
and [GHSA-mwm8-39rw-8826](https://github.com/sparklemotion/sqlite3-ruby/security/advisories/GHSA-mwm8-39rw-8826).
Replacing the system SQLite library alone does not fix these Ruby binding issues.
The maintained gem requires Ruby 3.2+, already used throughout the supported CI
matrix. No C backport, adapter fork, version spoof or dependency suppression is
included.

The registry `decorators` 2.0.6 release caps Rails below 7.2. Consumers must use
the same official Zeitwerk-compatible commit used by the repository and generated
extensions until a compatible upstream release is available:

```ruby
gem 'decorators', git: 'https://github.com/parndt/decorators.git',
                  ref: '8ba6dc68c30b5400ee97c642d57748ecaa94830c'
```

Then run `bundle update`, `bundle exec bundler-audit check --update`, the normal
application tests, and asset compilation. The repository's ordinary SQLite
compatibility regression checks real CRUD, type round trips, prepared binds,
rollback, custom functions and aggregate functions. Generated extensions keep
JavaScript compression through the documented supported Node.js LTS runtime.
Product APIs and existing CMS content behavior are retained.

Generated extension Gemfiles pin the reviewed source snapshot
`dcceb2f22ad01816d089064ae5872a795a7bbb6e`, which includes these runtime
requirements and the migration helper fix. This is a two-stage source pin: the
implementation commit is created first, then the generator pin is updated in a
subsequent commit. It is not a self-referential revision or a moving upstream
branch. Re-run clean generation, full bundle audit, ordinary tests and asset
compilation before updating that pin.
