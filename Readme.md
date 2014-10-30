# Gofer!

[![Code Climate](https://codeclimate.com/github/envygeeks/gofer.png)](https://codeclimate.com/github/envygeeks/gofer)
[![Dependency Status](https://gemnasium.com/envygeeks/gofer.png)](https://gemnasium.com/envygeeks/gofer)
[![Build Status](https://travis-ci.org/envygeeks/gofer.svg?branch=master)](https://travis-ci.org/envygeeks/gofer)
[![Coverage Status](https://img.shields.io/coveralls/envygeeks/gofer.svg)](https://coveralls.io/r/envygeeks/gofer)

## What is Gofer?

`Gofer` is a set of wrappers around the `Net::SSH` suite of tools to enable persistent access to remote systems. `Gofer` has been written to support the needs of system automation scripts. As such, `Gofer` will:

  * Print and capture `STDOUT` and `STDERR` automatically.
  * Automatically `raise` an error if a command returns a non-zero exit status.
  * Allow you to access captured `STDOUT` and `STDERR` individually or as a combined.
  * Persist the SSH connection so that multiple commands don't incur connection penalties.
  * Allow multiple simultaneous command executions on a cluster of hosts.
  * Override: return non-zero exit instead of raising, suppress output.

## Init

```ruby
local  = Gofer::Local.new
remote = Gofer::Remote.new("host.com", "ubuntu", :keys => [
  "~/.ssh/id_rsa"
])
```

*Please note you **do not** need the keys option.*

## Options (**opts**)

There are options that can be passed into initialize and options that can be passed into run. They are technically one in the same except that options passed into initialize are overridden by options passed into `#run` itself.

### Known Options

```ruby
:stdout # Custom STDOUT class (Stdio).
:stdio # Custom STDIO class (Stdio).
:output_prefix # Use an output Prefix (Stdio).
:timeout # Currently unused but also passed to `Net::SSH`
:stderr # Custom STDERR class (Stdio).
:env # Environment variables to set.
```

*Unknown options sent into `new` are decided based on `Gofer::Stdio`, if `Gofer::Stdio` does not know them then it is sent to `Net::SSH`... but unknown options sent into `run` are ignored for the most part because it's infeasible to sort them on the fly, reinitialize `Net::SSH` and cause overhead.*

## Commands

```ruby
ssh.run("echo $MY_VAR", :env => { :MY_VAR => "value" })
```

## Debug

Gofer returns a full debug class with lots of insight into what happens with your commands, such as the original command, the modified command (if we add `cd` for `PWD` and `VAR=val` for `env`.) The opts we used, the env (the original hash,) and lots of other stuff that would be helpful.  This isn't really to help you but to help me in the event something goes wrong, providing the output of the debug class will provide me great insight into exactly where things went wrong and quickly allow me to fix it and add a test for the edge.

```ruby
debug = ssh.run("echo $RAILS_ENV", :env => {
  :PWD => "/home/user",
  :RAILS_ENV => :production
})

debug.cmd # => "RAILS_ENV=production; cd /home/user && echo $RAILS_ENV"
debug.original_cmd # => "echo $RAILS_ENV"
debug.env # => { "RAILS_ENV" => "production" }
debug.opts # => { "YOUR OPTS HASH NORMALIED" => "Here" }
```

*The following methods forward to `@response`*

```ruby
debug.exit_status # 1
debug.stdout # => "production\n"
debug.lines # => ["production\n"]
debug.each_line # => <Enum ["production\n"]>
debug.to_enum # => <Enum ["production\n"]>
debug.combined # => "production\n"
debug.to_s # => "production\n"
debug.stderr # => ""
```

*The following methods forward to `@response#exit_status`*

```ruby
debug == 1
debug >= 1
debug <= 1
debug >  1
debug <  1
```

*Please note that `@response` is not public because I would like to enforce a consistent API, therefore there will not be a response method to access everything inside of the response, if something is missing please file a pull request and create a ticket for the `String#` you would like and I will be more than happy.  If you do create a pull request please make sure to also update the documentation!*

## Downloading, uploading and reading.

```ruby
ssh.download("file", "file")
ssh.upload("file", "remote_file")
output = ssh.read("file")
```

## Handling Errors

```ruby
ssh.run("false") # Raises Gofer::Error
debug = ssh.run("false", :capture_exit_status => true)
$stdout.puts debug.exit_status unless debug == 0
```

## Custom Output Handler

Gofer handles StdIO using a custom wrapper that has a base set of options, and a normalizer that allows you to accept options via each method directly, so that you can have a per-case option set, if you wish to add in your own cond. you can use this example:

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

### Change where `:stdout` and `:stderr` goes without `Stdio` wrappers

On top of using an StdIO wrapper, `Gofer::Stdio` also accepts that you sometimes just want to override where the output goes, so you can also pass `Gofer::Remote` and `Gofer::Local` and `:stdout` and `:stderr` and it will make sure that `Gofer::Stdio` gets it.

```ruby
ssh = Gofer::Remote.new({
  :stdout => stdout = StringIO.new,
  :stderr => stderr = StringIO.new
})

ssh.run("echo hello")
stdout.string.strip == "hello" # => true
```

## Stdin

Want to pass data into `:stdin` of a command? Then `Gofer` has you covered.

```ruby
debug = ssh.run("sed 's/foo/bar/'", :stdin => "hello foo\n")
$stdout.puts debug.combined
```

## Output Prefixes

```ruby
ssh.output_prefix = "apollo"
ssh.run("echo hello; echo goodbye")
# => apollo: hello\napollo: goodbye
```

## Suppress

```ruby
ssh.run "echo noisy", :quiet_stdout => true
ssh.run "echo noisier 1>&2", :quiet_stderr => true
```

## Async (Clustered) Hosts

```ruby
cluster = Gofer::Cluster.new
cluster << Gofer::Host.new("host.com", "ubuntu", :output_prefix => "host1")
cluster << Gofer::Host.new("host.com", "ubuntu", :output_prefix => "host2")
cluster.run "hostname"
```

### Concurrency

```ruby
cluster.max_concurrency = 1
result = cluster.run("sudo /etc/init.d/apache2 restart")
$stdout.puts results.values.join(", ")
```

## Exceptions

```ruby
begin; cluster.run "rake deploy"; rescue Gofer::ClusterError => e
  e.errors.each do |h, e|
    $stderr.puts "Failed on #{h} with #{e}, rolling back ..."
    host.run "rake rollback"
  end

  raise e
end
```

## Environment Variables

```ruby
host1 = Gofer::Remote.new("user", "host", :env => { :VAR1 => :val })
host2 = Gofer::Local.new(:env => { :VAR1 => :val })
host1.run("echo $VAR1; echo $VAR2", :env => { :VAR2 => :val })
host2.run("echo $VAR1; echo $VAR2", :env => { :VAR2 => :val })
```

## Testing `Gofer`

If you are looking for the true quick and dirty of how to get it up without much trouble... take a look at travis.yml in the repo root and it will show you how we quickly generate a key and run the tests since Net::SSH does work with ~/.ssh/config and the default id_rsa file if you have one installed.

  * Setup ~/.ssh/config for 127.0.0.* to prefer your key.
  * Ensure that you support dynamic localhost (127.0.0.1, 127.0.0.2)
  * OR: You can just authorize id_rsa on localhost without ~/.ssh/config.
  * Run bundle install && rake spec`

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
