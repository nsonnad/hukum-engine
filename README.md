# HukumEngine

An engine for Hukum, a 2v2 team card game invented in India. The engine provides a client API for all actions needed to play the game, such as starting a game, adding teams, playing cards, etc (docs tk). Internally, the engine maintians the full state of the game at every move, determines who won a given trick, keeps score, and manages transitions between stages of the game.

## Run a test game

```
mix run -e AutoTestGame.run --no-halt
```

TODO:

* [ ] Put each player in its own process?
* [x] Write some very basic way to automatically play the game, for testing
* [ ] Implement loner
* [ ] Figure out what exactly should be sent to the client, if not the entire game state
