# Gofer!

[![Code Climate](https://codeclimate.com/github/envygeeks/gofer.png)](https://codeclimate.com/github/envygeeks/gofer)
[![Dependency Status](https://gemnasium.com/envygeeks/gofer.png)](https://gemnasium.com/envygeeks/gofer)

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
ssh = Gofer::Host.new("host.com", "ubuntu", keys: ["~/.ssh/id_rsa"])
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
$stdout.puts ssh.ls("a_remote_dir").join(", ")
```

### Handle Errors

```ruby
ssh.run("false")
response = ssh.run("false", :capture_exit_status => true)
$stdout.puts response.exit_status unless response.exit_status == 0
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
ssh.run "echo noisy", :quiet => true
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
