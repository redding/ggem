# GGem

Quickly, easily, consistantly generate a ruby gem project ready to build, test, and deploy.  Uses and emulates most of Bundler's gem building features.

## Installation

```
$ gem install ggem
```

## Usage

```
$ ggem my-gem
```

This creates a folder and some files for developing, testing, and building a gem.  The command is pretty forgiving with the name you supply, it will automatically transform anything that is CamelCased into something more rubyish.  If you have existing folders/files it will just add/overwrite where necessary and not remove anything.

GGem assumes you are using git for version control.  It uses information in you git config and git commands to generate some default information and to build the gem.  When creating new gems, GGem will also initialize a git repo and add the newly created files for committing.

The gem will generate with bundler (http://github.com/carlhuda/bundler/) and assert (http://github.com/teaminsight/assert) gems as development dependencies.  They are brought in automatically to make unit testing and releasing your new gem easy.  Remove their calls from the generated Rakefile and test helper if you don't want to use them.

After generating your gem, add information about your gem to both the gemspec and README files.  The default version number is "0.0.1", but if you want to change that, take a look at `lib/my_gem/version.rb` to make the change - this will automatically be picked up when you rebuild your gem.

Your new gem provides some Rake tasks for convenience:

* all the bundler gem rake tasks (http://github.com/carlhuda/bundler/)
* all the testing rake task stuff from assert (http://github.com/teaminsight/assert)

That's it. Enjoy.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
