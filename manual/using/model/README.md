# The Rapid Model

Rapid can be thought of as providing various disparate-yet-linked [services]
with a shared data structure, into which each service can insert information
about its current state as well as an interface for other services to request
actions.  This shared structure, called the *model*, is key to the way Rapid
works and how clients work with Rapid.

## What is the model?

The Rapid model is a tree of objects, called *model objects*, that each
represent either a Rapid service or something made available by a service for
viewing and acting upon.  For example, a playout service like [BAPS3] will add
to the model representations of the playlists, songs, players, and various
related variables: these are available for other services to look at, or
perform actions on.

**Note:** We refer only to services when talking about what can interact with
model objects.  But what about external clients?  Simple: the clients are
actually talking to a service, such as the [server service], that performs the
client's actions on their behalf.  The fact that interfaces with clients are
simply just services, and that any service can behave as an interface to
clients, is part of Rapid's approach to conceptual simplicity.  **(End of
note.)**

The details of how the model works are left to later chapters on development,
but, for now, it's enough to think of the model as being like a central
database for data shared between Rapid services.

## The Update Channel

Whenever a change occurs to the model, it is propagated to every service
running in Rapid via the *update channel*.  This allows services to react
immediately to what other services are doing.  Also, for services that talk to
clients, the update channel provides a convenient method of *pushing* updates
to those clients.

[services]:       ../services/README.md
[BAPS3]:          ../services/baps3.md
[server service]: ../services/server.md
