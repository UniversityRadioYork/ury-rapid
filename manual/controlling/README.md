# Controlling Rapid

Rapid can be controlled by external clients via services that provide an
appropriate interface between clients and the Rapid model.  Rapid comes with a
[Server service] that sets up a HTTP-based interface for both human and machine
clients, but additional services can be created and started to provide other
interfaces, such as emulations of legacy playout systems.

Much of this chapter assumes that the [server service] is configured and
enabled in [config.rb].  This chapter covers:

* Using the [Rapid inspector] to view the Rapid model as a human;
* Using the [JSON API] to view and control Rapid from programs and scripts.

[Server service]:  ../using/services/server.md
[config.rb]:       ../using/config/README.md
[Rapid inspector]: inspector/README.md
[JSON API]:        json/README.md
