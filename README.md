bra
===

__bra__ (BAPS Ruby Abstraction) is a project for creating a system to translate the binary protocol calls of URY's internal Broadcast and Presenting Suite (BAPS) to and from a more sensible and accessible medium.

This is in very early development.  Expect it not to do a lot.

Requirements
------------

* Ruby 2.0+
* A BAPS server (sadly not found outside of URY, really)
* This also depends on some RubyGems; see `Gemfile`.

Usage
-----

The main server (main.rb) isn't yet fully operational, but information on how to use it will pop up here eventually.

### Test program (state dumper)

`ruby state_dumper.rb BAPS-HOSTNAME BAPS-PORT USERNAME PASSWORD` will invoke the state dumper testbed.  This will connect to the specified BAPS server, log in and dump some information to stdout.
