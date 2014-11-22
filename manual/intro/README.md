# What is Rapid?

Rapid can be thought of as many things:

* A *Radio API daemon*, or a daemon that provides an API for radio playout
  (this is where the name *Rapid* originates);
* An implementation of the [BAPS3 Platform], part of the BAPS3 radio playout
  system;
* A general combination of a shared data model and plugin system that can be
  used for pretty much anything that involves several services that need to
  talk to each other;
* A tangled mass of over-engineered Ruby.

Rapid was, however, originally intended to be a compatibility layer for playout
systems.  In the transition from BAPS2 to BAPS3 at University Radio York, the
original goal for Rapid was to be a shim that sat on top of BAPS2, provided a
nice HTTP API for the new BAPS3 client, and held things together while the
BAPS3 system was constructed to take the same API.  Although Rapid's position
in the ecosystem has changed dramatically since, the idea of Rapid being an
abstraction layer for playout is still a large part of its design.

**Trivia:** Rapid was originally called the *BAPS REST API*, or *BRA*, as a pun
on its role: to *lift and separate* playout clients and servers.  The name
was dropped for obvious reasons.  **(End of trivia.)**

## The Components of Rapid

Rapid consists of several components:

* A [model], or shared data structure;
* A set of [services] that own parts of the model, and can perform actions on
  the rest of the model (thus allowing them to communicate);
* A [server service], which is simply a regular service that exports a view of
  the model on HTTP for external clients to use;
* An authentication system that governs model communications;
* Some glue and logic to hold the other components together.

[BAPS3 Platform]: https://universityradioyork.github.io/baps3-spec/services/platform.html
[model]:          ../using/model/README.md
[services]:       ../using/services/README.md
[server service]: ../using/services/server.md
