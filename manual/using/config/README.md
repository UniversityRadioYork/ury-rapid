# The `config.rb` file

Rapid is usually configured by a Ruby file called `config.rb`.  This Ruby file
specifies, amongst other things:

* Which services are to be started;
* The configuration for each service;
* The users permitted to log into the Rapid server, and their permissions.

## Why a Ruby file?

There are several reasons why Rapid is configured using Ruby:

* A Ruby file is extremely easy for Rapid to parse, since Rapid can simply feed
  the configuration into the Ruby interpreter;
* Using a Ruby file gives a large amount of flexibility to the user, who may
  choose to use Ruby's control flow operations (`if`, `each`, etc.) to simplify
  their configuration;
* Using a Ruby file makes it very easy to include and use services defined in
  other gems.

## The example file

An example file is packed in with Rapid, as `config.rb.example`.  You can copy
this to `config.rb` and tweak it to suit your needs.

## Sections

A `config.rb` usually contains the following sections:

* Ruby code (eg `require`) to load in the services used in the rest of the
  configuration;
* A `services` block, which contains all of the configuration for the services
  that Rapid will host;
* Zero or more `user` blocks, which associate an external Rapid user's username
  with a password and privileges.
