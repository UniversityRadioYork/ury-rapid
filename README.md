bra
===

__bra__ (BAPS Ruby Abstraction) is a project for creating a system to translate the binary protocol calls of URY's internal Broadcast and Presenting Suite (BAPS) to and from a more sensible and accessible medium.

More generally, it's about creating a REST API for controlling a radio playback system, which so happens to come pre-plumbed into our own system.

This is in very early development.  Expect it not to do a lot.

What this will become
---------------------

Currently URY use an in-house, proprietary playout system called __BAPS__ to assemble and play out shows.  It has a binary protocol that's somewhat messy, hard to debug and hard to extend.

We want to make a __text protocol__ based system to replace it, so future URYers can understand how the playout system works a bit better.  In order to do that, we need to start small, by building a new API on top of the old server.  This is what __BRA__ will do.

Eventually the BRA API may form the top end of a new, open-source server stack (but who knows?  only time will tell).


Requirements
------------

* Ruby 2.0+
* For out-of-the-box usage, a BAPS server (sadly not found outside of URY, really)
* This also depends on some RubyGems; see `Gemfile`.

Usage
-----

`ruby main.rb` (for best results, consider using rerun).

The main server (main.rb) is configured via a YAML file called `config.yml`.  An example file will be put up eventually, but for now you can probably guess the structure from the code.
