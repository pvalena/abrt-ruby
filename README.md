[![Build Status](https://travis-ci.org/voxik/abrt-ruby.svg?branch=master)](https://travis-ci.org/voxik/abrt-ruby)

# abrt

Provides ABRT reporting support for libraries/applications written using Ruby.

Please note that ABRT will be able to report errors only for applications which are already RPM packaged. Errors in other applications are ignored.

## Installation

```
$ gem install abrt
```

or if you're using Bundler, put

```
gem "abrt", :require => false
```

line into your *Gemfile*.

## Usage

There are several ways how to run any application with ABRT handler enabled.

1. Use `require 'abrt'` at the beginning of your application.
2. If you can't modify the application and you still want to use ABRT support, then you need to define `RUBYOPT="-rabrt"` environment variable. This will ensure that ABRT support gets loaded and the exception handler hooks are installed.
3. If you want to ensure, that ABRT handler is always used, add `RUBYOPT="-rabrt"` into your *.bashrc* file. This will ensure, that Ruby loads ABRT handler every time its starts.
4. In Fedora, since ruby-2.0.0.247-9.fc19, Ruby loads abrt gem automatically.

Now, everytime the unhandled exception is captured, ABRT handler prepares bugreport, which can be submitted into http://bugzilla.redhat.com component later using standard ABRT tools.

## Contributing to abrt
 
- Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet.
- Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it.
- Fork the project.
- Start a feature/bugfix branch.
- Commit and push until you are happy with your contribution.
- Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
- Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Copyright

Copyright (c) 2012-2017 Vít Ondruch. See LICENSE.txt for
further details.

