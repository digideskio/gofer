# 2.0.0

* Added `:stdout` and `:stderr` to allow redirection.
* Removed the delete insanity, opts are non-destructive now.
* Implemented an STDIO class to simplify and consolidate output.
* Changed :quiet to :quiet_stdout 0692606609aae85b175457ac6e52b5f326f070b6
* Removed SSHWrapper in favor of `Gofer::Remote` and `Gofer::Base` for `Gofer::Local` and `Gofer::Remote`
* Modified exception handling.  Now it will throw syntax errors.
* Simplified the pooled threading for `Gofer::Cluster`
