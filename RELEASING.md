Releasing Grape
===============

There're no particular rules about when to release Grape. Release bug fixes frequently, features not so frequently and breaking API changes rarely.

### Release

Run tests, check that all tests succeed locally.

```
bundle install
rake
```

Check that the last build succeeded in [Travis CI](https://travis-ci.org/ruby-grape/grape) for all supported platforms.

Those with r/w permissions to the [master Grape repository](https://github.com/ruby-grape/grape) generally have large Grape-based projects. Point one to Grape HEAD and run all your API tests to catch any obvious regressions.

```
gem grape, github: 'ruby-grape/grape'
```

Increment the version, modify [lib/grape/version.rb](lib/grape/version.rb).

*  Increment the third number if the release has bug fixes and/or very minor features, only (eg. change `0.5.1` to `0.5.2`).
*  Increment the second number if the release contains major features or breaking API changes (eg. change `0.5.1` to `0.6.0`).

Modify the "Stable Release" section in [README.md](README.md). Change the text to reflect that this is going to be the documentation for a stable release. Remove references to the previous release of Grape. Keep the file open, you'll have to undo this change after the release.

```
## Stable Release

You're reading the documentation for the stable release of Grape, 0.6.0.
```

Change "Next Release" in [CHANGELOG.md](CHANGELOG.md) to the new version.

```
#### 0.6.0 (9/16/2013)
```

Remove the line with "Your contribution here.", since there will be no more contributions to this release.

Commit your changes.

```
git add README.md CHANGELOG.md lib/grape/version.rb
git commit -m "Preparing for release, 0.6.0."
git push origin master
```

Release.

```
$ rake release

grape 0.6.0 built to pkg/grape-0.6.0.gem.
Tagged v0.6.0.
Pushed git commits and tags.
Pushed grape 0.6.0 to rubygems.org.
```

### Prepare for the Next Version

Modify the "Stable Release" section in [README.md](README.md). Change the text to reflect that this is going to be the next release.

```
## Stable Release

You're reading the documentation for the next release of Grape, which should be 0.6.1.
The current stable release is [0.6.0](https://github.com/ruby-grape/grape/blob/v0.6.0/README.md).
```

Add the next release to [CHANGELOG.md](CHANGELOG.md).

```
#### 0.6.1 (Next)

* Your contribution here.
```

Bump the minor version in lib/grape/version.rb.

```ruby
module Grape
  VERSION = '0.6.1'
end
```

Commit your changes.

```
git add CHANGELOG.md README.md lib/grape/version.rb
git commit -m "Preparing for next development iteration, 0.6.1."
git push origin master
```

### Make an Announcement

Make an announcement on the [ruby-grape@googlegroups.com](mailto:ruby-grape@googlegroups.com) mailing list. The general format is as follows.

```
Grape 0.6.0 has been released.

There were 8 contributors to this release, not counting documentation.

Please note the breaking API change in ...

[copy/paste CHANGELOG here]

```
