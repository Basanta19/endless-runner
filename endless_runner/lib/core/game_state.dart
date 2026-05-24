enum RunnerGameState { menu, playing, paused, gameOver }

enum Lane { left, center, right }

extension LaneX on Lane {
  Lane get laneLeft {
    switch (this) {
      case Lane.left:
        return Lane.left;
      case Lane.center:
        return Lane.left;
      case Lane.right:
        return Lane.center;
    }
  }

  Lane get laneRight {
    switch (this) {
      case Lane.left:
        return Lane.center;
      case Lane.center:
        return Lane.right;
      case Lane.right:
        return Lane.right;
    }
  }
}
