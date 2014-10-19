require "gofer/extensions/hash"
require "gofer/version"
require "gofer/stdio"
require "gofer/remote"
require "gofer/cluster"
require "gofer/local"
require "shellwords"

Gofer::Host = Gofer::Remote
# ^ For now we wrap it out.
