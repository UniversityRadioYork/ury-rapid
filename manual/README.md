# URY Rapid

This is the user manual for *URY Rapid*, a playout services platform designed
for use in the *BAPS3* playout system.

URY Rapid is a Ruby-based system that allows you to:

* Plug in playout systems ([BAPS2] and [BAPS3]);
* Add other services, such as tracklisting and track resolving, that work with
  playout systems to add functionality;
* Serve a view of the resulting system via HTTP/WebSockets, for external
  clients to consume.

Rapid, by virtue of being very general and plugin-based, is also a fairly
complex system to understand.  This user manual intends to assist with:

* Explaining exactly [what Rapid is];
* [Installing], [configuring], and [launching] Rapid;
* [Talking to Rapid], as a [human] or as an [external client];
* [Creating new services] to interface Rapid to other systems or extend its
  functionality;
* [Hacking] on the Rapid system itself.

[BAPS2]:                 using/services/baps2.md
[BAPS3]:                 using/services/baps3.md

[what Rapid is]:         intro/README.md
[Installing]:            using/installing/README.md
[configuring]:           using/config/README.md
[launching]:             using/launching/README.md
[Talking to Rapid]:      controlling/README.md
[human]:                 controlling/inspector/README.md
[external client]:       controlling/json/README.md
[Creating new services]: extending/services/README.md
[Hacking]:               hacking/README.md
