# <%= extension_plural_name.titleize %> extension for Refinery CMS.

## How to build this extension as a gem (not required)

    cd vendor/extensions/<%= extension_plural_name %>
    gem build refinerycms-<%= extension_plural_name %>.gemspec
    gem install refinerycms-<%= extension_plural_name %>.gem

    # Sign up for a https://rubygems.org/ account and publish the gem
    gem push refinerycms-<%= extension_plural_name %>.gem

## Development and asset compilation

Install a supported Ruby version and a supported Node.js LTS runtime before
running `bundle install`. ExecJS/Uglifier uses Node.js for JavaScript compression;
the obsolete therubyracer/V8 3.11 dependency is no longer needed. The generated
Gemfile chooses a patched Rails version for development and testing. This
requires Rails 7.2.4 or a patched Rails 8 release (8.0.5.1+ / 8.1.3.1+).
The current Refinery release also raises its minimum supported Rails version for
security: older Rails series have unresolved upstream advisories.

The development Gemfile pins the security-reviewed Refinery source at
https://github.com/leborn-dev/lerefinery/commit/dcceb2f22ad01816d089064ae5872a795a7bbb6e.
The decorators dependency is likewise pinned to its upstream Zeitwerk-compatible
commit https://github.com/parndt/decorators/commit/8ba6dc68c30b5400ee97c642d57748ecaa94830c;
the published 2.0.6 gem otherwise caps Rails below the patched line.
The source retains Refinery's upstream MIT license and fixes input handling and
jQuery UI dependencies. It deliberately does not follow the old upstream master
branch. To update the pin, compare the candidate commit with this snapshot and
current upstream, generate a fresh extension, install into an empty bundle path,
and run `bundle exec bundler-audit check --update`. Run the generated extension's
tests and dummy application's `assets:precompile`, and exercise ExecJS/Uglifier
compression with Node.js. Commit the verified full source SHA and retain the
resolved lockfile and audit results. Do not replace the pin with a moving branch.
