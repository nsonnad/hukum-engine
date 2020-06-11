# HukumEngine

An engine for Hukum, a 2v2 team card game invented in India. The engine provides a client API for all actions needed to play the game, such as starting a game, adding teams, playing cards, etc (docs tk). Internally, the engine maintians the full state of the game at every move, determines who won a given trick, keeps score, and manages transitions between stages of the game.

For info on how to run the project, and on Hukum in general, see the
[master Hukum repo](https://github.com/nsonnad/hukum).

## Run a test game

```
mix run -e AutoTestGame.run --no-halt
```

See [test-game.log](test-game.log) for example output from a test game.
