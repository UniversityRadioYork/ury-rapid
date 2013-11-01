bra - lifts and separates playout systems
=========================================

__bra__ is (will be) a Web-ready abstraction layer for radio playout systems, based on a REST-like API and eventual push-based message pipeline.

It basically sits on top of a playout system, keeping an internal model of what's going on based on information from that playout system's native API, and using that model to satisfy requests (for data and commands) via an HTTP-based interface.

This is in very early development.  Expect it not to do a lot.


Why are we doing this?
----------------------

Currently URY use an in-house, proprietary playout system called __BAPS__ to assemble and play out shows.  It has a binary protocol that's somewhat messy, hard to debug and hard to extend.

We want to make a __text protocol__ based system to replace it, so future URYers can understand how the playout system works a bit better.  In order to do that, we need to start small, by building a new API on top of the old server.  This is what __bra__ will do.

Eventually the bra API may form the top end of a new, open-source server stack (but who knows?  only time will tell).


Requirements
------------

* Ruby 2.0+ (only tested with stock interpreter)
* For out-of-the-box usage, a BAPS server (sadly not found outside of URY, really)
* This also depends on some RubyGems; see `Gemfile`.


Usage
-----

`ruby main.rb` (for best results, consider using rerun).

bra is configured via a YAML file called `config.yml`.  An example file is provided, but may be out of date.  Check the code if in doubt.


Licence
-------

bra is licenced under the 2-clause BSD licence.


Why is it called bra?
---------------------

Originally, bra stood for "BAPS REST API"; then "BAPS Ruby Abstraction"; then, as bra started to generalise, it lost its expansion.  Make up your own!
