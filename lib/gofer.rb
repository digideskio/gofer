require "gofer/version"

require "gofer/stdio"
require "gofer/remote"
require "gofer/cluster"
require "gofer/local"

Gofer::Host = Gofer::Remote
# ^ For now we wrap it out.
