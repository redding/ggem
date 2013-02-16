# GGem

Consistantly generate a ruby gem project ready to test, build, and deploy.  Uses and emulates most of Bundler's gem building features.

## Usage

```
$ ggem --help
$ ggem my-gem
$ git commit -m "Gem created with ggem"
```

GGem creates a folder and files for developing, testing, and releasing a gem.  It is safe to run on existing gem folders, adding/overwriting where necessary.

## Features

* creates `lib` and gem files similar to `bundle gem` (as of Bundler 1.2.4)
* creates `test` files
* source control using Git
* test using Assert
* release using Bundler
* adds `TODO` entries in files where user input is needed

## Installation

```
$ gem install ggem
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
