rapid
=====
![Travis build status](https://travis-ci.org/UniversityRadioYork/rapid.svg)

* For more extensive narrative documentation, see https://github.com/UniversityRadioYork/ury-rapid/wiki.
* For auto-generated YARD documentation, see http://rubydoc.info/github/UniversityRadioYork/rapid.

__rapid__ (formerly _bra_) is (will be) a Web-ready abstraction layer for radio playout systems, based on a REST-like API and push-based message pipeline.

It basically sits on top of a playout system, keeping an internal model of what's going on based on information from that playout system's native API, and using that model to satisfy requests (for data and commands) via an HTTP-based interface.

This is still in development and is constantly changing, so don't depend on it just yet!


Why are we doing this?
----------------------

Currently URY use an in-house, proprietary playout system called __BAPS__ to assemble and play out shows.  It has a binary protocol that's somewhat messy, hard to debug and hard to extend.

We want to make a __text protocol__ based system to replace it, so future URYers can understand how the playout system works a bit better.  In order to do that, we need to start small, by building a new API on top of the old server.  This is what __rapid__ will do.

Eventually the rapid API may form the top end of a new, open-source server stack (but who knows?  only time will tell).


Requirements
------------

* Ruby 2.0+ (only tested with stock interpreter)
* For out-of-the-box usage, a BAPS server (sadly not found outside of URY, really)
* This also depends on some RubyGems; see `Gemfile`.


Usage
-----

`bundle exec bin/rapid`

rapid is configured via a ruby file called `config.rb`.  An example file is provided, but may be out of date.  Check the code if in doubt.


Licence
-------

rapid is licenced under the 2-clause BSD licence.
