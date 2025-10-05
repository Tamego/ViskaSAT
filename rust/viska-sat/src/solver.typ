== ソルバのトレイト
様々なアルゴリズムに共通するインターフェースを与えるために `Solver` トレイトを定める。
ソルバ側の主な関数は以下の通り：
/ `Solver::initialize()`: 問題（`Cnf`）を引数に取ってSATソルバを初期化する。
/ `Solver::solve()`: 問題を解き、充足可能（`SatResult::Sat`）か充足不能（`SatResult::Unsat`）かをを返す。
/ `Solver::model()`: 充足可能のときの割り当ての1つを返す。充足不能なら何も返さない。型は `Option<Assignment>`。

また、`SolverRunner` との連携に関わる関数は以下の通り：
/ `Solver::emit_event()`: イベントを発生させる。
  `SolverRunner` にイベントを通知し、そのタイミングで一時停止する必要があるなら通知があるまで停止する。

```rust
//| id: sol_solver-trait
```

ここで、`SolverRunner` との通信のために `SolverCommunicator` トレイトを定める。
これは以下の関数を持つ：
/ `SolverCommunicator::send_event()`: `SolverRunner` にソルバのイベントを伝える。
/ `SolverCommunicator::recv_latest_control()`: `SolverRunner` からの*最新の制御のみ*を受けとる。スレッドをブロックする。
/ `SolverCommunicator::try_recv_latest_control()`: `SolverRunner` からの*最新の制御のみ*を受けとる。スレッドをブロックしない。


```rust
//| file: rust/viska-sat/src/solver.rs
<<sol_solver-trait>>
```

