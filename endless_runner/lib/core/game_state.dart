/// `crashed` = hit an obstacle, waiting on the respawn choice.
/// Kept last so existing index checks (playing == 1) stay valid.
enum RunnerGameState { menu, playing, paused, gameOver, crashed }
