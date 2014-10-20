# Gofer!

[![Code Climate](https://codeclimate.com/github/envygeeks/gofer.png)](https://codeclimate.com/github/envygeeks/gofer)
[![Dependency Status](https://gemnasium.com/envygeeks/gofer.png)](https://gemnasium.com/envygeeks/gofer)
[![Build Status](https://travis-ci.org/envygeeks/gofer.svg?branch=master)](https://travis-ci.org/envygeeks/gofer)
[![Coverage Status](https://img.shields.io/coveralls/envygeeks/gofer.svg)](https://coveralls.io/r/envygeeks/gofer)

*The docs you are reading are for the future 2.0.0 version of envygeeks-gofer
which is still away off because it requires me to finish adding in my deploy
stuff and helpers.  Please note that a lot has changed.*

This is my personal fork of https://github.com/mipearson/gofer please see that
repo if you are looking for something that is aimed at the general public and
not me.  Though mine does fix some of the issues that were on the TODO I am
just waiting to see if he would like to collaborate on bringing my code with
his since we write code in drastically different ways.

## What is Gofer?

**Gofer** is a set of wrappers around the Net::SSH suite of tools to enable
consistent access to remote systems. **Gofer** has been written to support the
needs of system automation scripts. As such, **gofer** will:

  * Print and capture STDOUT and STDERR automatically
  * Automatically raise an error if a command returns a non-zero exit status
  * Allow you to access captured STDOUT and STDERR individually or as a combined string
  * Override the above: return non-zero exit status instead of raising an error, suppress output
  * Persist the SSH connection so that multiple commands don't incur connection penalties
  * Allow multiple simultaneous command execution on a cluster of hosts via `Gofer::Cluster`

## Examples

Below you will find several basic examples.

### Init

```ruby
local = Gofer::Local.new
```

```ruby
ssh = Gofer::Remote.new("host.com", "ubuntu", :keys => [
  "~/.ssh/id_rsa"
])
```

### Options

There are options that can be passed into initialize and options that can be
passed into run.  Both accept any number of extra options that even we don't
recognize but there is one big difference, extra options that are not known
on `#run` (both `Gofer::Local` and `Gofer::Remote`) are passed into
`Gofer::Stdio` and any options that are unknown on `Gofer::Remote` are
passed into `Net::SSH`

#### Known Options

```ruby
:stdout # Custom STDOUT
:stdio # Custom STDIO Class.
:output_prefix # Use an output Prefix.
:timtout # Currently unused but also passed to `Net::SSH`
:env # Environment variables to set.
:stderr # Custom STDERR
```

### Commands

```ruby
ssh.run("sudo stop mysqld")
```

### Copy

```ruby
ssh.upload("file", "remote_file")
ssh.download("remote_dir", "dir")
```

### Interact

```ruby
ssh.run("rm -rf 'remote_directory'") if ssh.exist?("remote_directory")
ssh.write("String", "a_remote_file")
$stdout.puts ssh.read("a_remote_file")
```

### Handle Errors

```ruby
ssh.run("false")
response = ssh.run("false", :capture_exit_status => true)
$stdout.puts response.exit_status unless response.exit_status == 0
```

### Custom Output Handler

Gofer handles StdIO using a custom wrapper that has a base set of options, and
a normalizer that allows you to accept options via each method directly, so
that you can have a per-case option set, if you wish to add in your own cond.
you can use this example:

```ruby
class MyStdio < Gofer::Stdio
  def initialize(opts)
    @output_level = opts.delete(:output_level)
    super(opts)
  end

  # @see lib/gofer/stdio.rb

  def stdout(line, opts)
    opts = normalize_opts(opts)
    unless output_level < 2 || opts[:quiet_stdout]
      $stdout.puts wrap_output(line)
    end
  end
end

Gofer::Remote.new(:stdio => MyStdio)
```

### Change where stdout and stderr goes without Stdio wrappers

```ruby
Gofer::Remote.new({
  :stdout => stdout = StringIO.new,
  :stderr => stderr = StringIO.new
})
```

### Capture

```ruby
response = ssh.run("echo hello; echo goodbye 1>&2\n")
$stdout.puts response
$stdout.puts response.stdout
$stdout.puts response.stderr
$stdout.puts response.output
```

### Stdin

```ruby
response = ssh.run("sed 's/foo/bar/'", :stdin => "hello foo\n")
$stdout.puts response.output
```

### Prefix

```ruby
ssh.output_prefix = "apollo"
ssh.run("echo hello; echo goodbye")
# => apollo: hello\napollo: goodbye
```

### Suppression

```ruby
ssh.run "echo noisy", :quiet_stdout => true
ssh.run "echo noisier 1>&2", :quiet_stderr => true
ssh.quiet = true
```

### Async (Clustered) Hosts

```ruby
cluster = Gofer::Cluster.new
cluster << Gofer::Host.new("host.com", "ubuntu", :output_prefix => "host1")
cluster << Gofer::Host.new("host.com", "ubuntu", :output_prefix => "host2")
cluster.run "hostname"
```

#### Async Concurrency

```ruby
cluster.max_concurrency = 1
result = cluster.run("sudo /etc/init.d/apache2 restart")
$stdout.puts results.values.join(", ")
```

#### Exceptions

```ruby
begin; cluster.run "rake deploy"; rescue Gofer::ClusterError => e
  e.errors.each do |h, e|
    $stderr.puts "Failed on #{h} with #{e}, rolling back ..."
    host.run "rake rollback"
  end

  raise e
end
```

#### Environment Variables

```ruby
host1 = Gofer::Remote.new("user", "host", :env => { :VAR1 => :val })
host2 = Gofer::Local.new(:env => { :VAR1 => :val })
host1.run("echo $VAR1; echo $VAR2", :env => { :VAR2 => :val })
host2.run("echo $VAR1; echo $VAR2", :env => { :VAR2 => :val })
```

### Gofer::Deploy

`Gofer::Deploy` is a helper that loads a deploy.yml, normalizes it and then
helps you output useful information to the terminal.

```ruby
Gofer::Deploy.new.run("echo hello", :server => :app, :argv => { :n => true })
# => "from none echo -n hello"
```

#### deploy.yml

```yml
default_server: app
default_pwd: deploy_folder
deploy_output_level: 2
app: "www"

deploy_env:
  RAILS_ENV: production

deploy_servers:
  root: host
  app:  host


# You can place anything else you would like in your deploy.yml here, and it
# won't affect the deployer, you can add anything, the above are just values
# that we expect by default.
```
#### Known Opts

```ruby
:env # Accepted on both #run and #new
:gofer # options for Gofer::{Remote,Local}
:server # The server from :deploy_servers (symbol key)
:argv # Any (--|-) arguments (only useful when they are config args)
:env # run :env > new :env > :deploy_env (merged into each)
:capture # Prevent exit.
:stdout # The stdout
:stderr # The stderr
```

## Testing

If you are looking for the true quick and dirty of how to get it up without
much trouble... take a look at travis.yml in the repo root and it will show
you how we quickly generate a key and run the tests since Net::SSH does work
with ~/.ssh/config and the default id_rsa file if you have one installed.

  * Setup ~/.ssh/config for 127.0.0.* to prefer your key.
  * Ensure that you support dynamic localhost (127.0.0.1, 127.0.0.2)
  * OR: You can just authorize id_rsa on localhost without ~/.ssh/config.
  * Run bundle install && rake spec`

## TODO

  * Deal with timeouts and disconnects on persistent connections.

## License

Copyright (c) 2011-13 Michael Pearson; Copyright (c) 2014 Jordon Bedwell

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the 'Software'), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
