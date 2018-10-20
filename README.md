# GGem

A gem utility CLI.

```
$ cd /my/projects
$ ggem -h
Usage: ggem [COMMAND] [options]

Options:
        --version
        --help

Commands:
  generate (g) # Create a gem given a GEM-NAME
$ ggem generate mygem
created gem in /my/projects/mygem
initialized gem git repo
$ cd mygem/
$ ggem -h
Usage: ggem [COMMAND] [options]

Options:
        --version
        --help

Commands:
  generate (g) # Create a gem given a GEM-NAME
  build    (b) # Build mygem-0.0.1.gem into the pkg directory
  install  (i) # Build and install mygem-0.0.1.gem into system gems
  push     (p) # Push built mygem-0.0.1.gem to https://rubygems.org
  tag      (t) # Tag v0.0.1 and push git commits/tags
  release  (r) # Tag v0.0.1 and push built mygem-0.0.1.gem to https://rubygems.org
```

## Usage

### Generate

```
$ ggem generate -h
Usage: ggem generate [options] GEM-NAME

Options:
        --version
        --help

Description:
  Create a gem given a GEM-NAME
$ ggem generate mygem
$ git commit -m "Gem created with ggem"
```

The `generate` command creates a folder and files for developing, testing, and releasing a gem.  It is safe to run on existing gem folders, adding/overwriting where necessary.

* creates `lib` and gem files similar to `bundle gem` (as of Bundler 1.2.4)
* creates `test` files
* adds `TODO` entries in files where user input is needed
* source control using [Git](https://git-scm.com/)
* test using [Assert](https://github.com/redding/assert)
* CI with CircleCI
  * see `.circleci/config.yml`
  * need to replace `/todo_org_name` with the gem's org name (ie `/redding`)

You can also call this command using the `g` alias: `ggem g -h`.

### Build

```
$ ggem build -h
Usage: ggem build [options]

Options:
        --version
        --help

Description:
  Build mygem-0.0.1.gem into the pkg directory
```

The `build` command creates a .gem file and copies it into the `pkg/` directory.  You can also call this command using the `b` alias: `ggem b -h`.

### Install

```
$ ggem install -h
Usage: ggem install [options]

Options:
        --version
        --help

Description:
  Build and install mygem-0.0.1.gem into system gems
```

The `install` command first builds a .gem file and then installs it.  The command is the equivalent of running `ggem build && gem install pkg/mygem-0.0.1.gem`.  You can also call this command using the `i` alias: `ggem i -h`.

### Push

```
Usage: ggem push [options]

Options:
        --version
        --help

Description:
  Push built mygem-0.0.1.gem to https://rubygems.org
```

The `push` command first builds a .gem file and then pushes it to a gem host.  The command is the equivalent of running `ggem build && gem push pkg/mygem-0.0.1.gem --source https://rubygems.org`.  You can also call this command using the `p` alias: `ggem p -h`.

#### Using a custom gem host

To override the default `https://rubygems.org` push host, add a metadata entry to the .gemspec file:

```ruby
# ...
gem.metadata["allowed_push_host"] = "https://gems.example.com"
# ...
```

Now GGem will now use the allowed push host when pushing/releasing the gem.

```
$ ggem push -h
Usage: ggem push [options]

Options:
        --version
        --help

Description:
  Push built mygem-0.0.1.gem to https://gems.example.com
```

### Tag

```
$ ggem tag -h
Usage: ggem tag [options]

Options:
        --version
        --help

Description:
  Tag v0.0.1 and push git commits/tags
```

The `tag` command will tag the current git commit with the `version` data from the .gemspec file.  It then pushes any commits and tags.  The command is the equivalent of running `git tag -a -m "Version {version}" v{version} && git push && git push --tags`.  You can also call this command using the `t` alias: `ggem t -h`.

### Release

```
$ ggem release -h
Usage: ggem release [options]

Options:
        --version
        --help

Description:
  Tag v0.0.1 and push built mygem-0.0.1.gem to https://rubygems.org
  (macro for running `ggem tag && ggem push`)
```

As the help message says, this command is just a macro for running `ggem tag && ggem push`.  You can also call this command using the `r` alias: `ggem r -h`.

## Installation

```
$ gem install ggem
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am "Added some feature"`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
