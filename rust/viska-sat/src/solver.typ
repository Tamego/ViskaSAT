== ソルバ
様々なアルゴリズムに共通するインターフェースを与えるために `Solver` トレイトを定める。
ソルバ側の主な関数は以下の通り：
/ `Solver::initialize()`: 問題（`Cnf`）を引数に取ってSATソルバを初期化する。
/ `Solver::solve()`: 問題を解き、充足可能（`SatResult::Sat`）か充足不能（`SatResult::Unsat`）かをを返す。

また、`SolverRunner` との連携に関わる関数は以下の通り：
/ `Solver::emit_event()`: イベントを発生させる。
  `SolverRunner` にイベントを通知し、そのタイミングで一時停止する必要があるなら通知があるまで停止する。

`SolverReulst` は列挙型で定義する。
```rust
//| id: sol_solver-result
pub enum SatResult {
    Sat(Assignment),
    Unsat
}
```

`Solver` トレイトを前述のように書く。
イベントの種類はソルバ依存なので、`Event` と関連型にして各ソルバが自由に決められるようにした。
また、この `Solver` そのものは `SolverCommunicator` と独立して動かせるようにしたかったので、
`emit_event()` の返り値は `SolverCommunicatorError` にしてしまうのではなく、
関連型 `Error` で表現した。
```rust
//| id: sol_solver-trait
pub trait Solver {
    type Event;
    type Error;

    fn initialize(&mut self, problem: Cnf);
    fn solve(&mut self) -> SatResult;
    fn emit_event(&mut self) -> Result<(), Self::Error>;
}
```

ここで、`SolverRunner` との通信のために `SolverCommunicator` トレイトを定める。
これは以下の関数を持つ：
/ `SolverCommunicator::send_event()`: `SolverRunner` にソルバのイベントを伝える。
/ `SolverCommunicator::recv_latest_control()`: `SolverRunner` からの*最新の制御のみ*（`SolverControl`）を受けとる。スレッドをブロックする。
/ `SolverCommunicator::try_recv_latest_control()`: `SolverRunner` からの*最新の制御のみ*を受けとる。スレッドをブロックしない。

`SolverControl` は全ソルバに共通するので、ここで列挙型で定義する。
停止と再開のみを想定しているが、今後増やすかもしれない。
```rust
//| id: sol_solver-control
pub enum SolverControl {
    Pause,
    Resume
}
```

また、`SolverCommunicator` に関連するエラーハンドリングのための列挙型を作る。
```rust
//| id: sol_solver-communicator-error
pub enum SolverCommunicatorError {
    SendFailed,
    ReceiveFailed,
}
```

イベントの種類はソルバ依存なので、`Solver` トレイトと同様に、
`Event` と関連型にして各ソルバが自由に決められるようにした。
```rust
//| id: sol_solver-communicator
pub trait SolverCommunicator {
    type Event;

    fn send_event(&mut self, event: Self::Event) -> Result<(), SolverCommunicatorError>;
    fn recv_latest_control(&mut self) -> Result<SolverControl, SolverCommunicatorError>;
    fn try_recv_latest_control(&mut self) -> Result<Option<SolverControl>, SolverCommunicatorError>;
}
```

```rust
//| file: rust/viska-sat/src/solver.rs
use crate::{assignment::Assignment, cnf::Cnf};
<<sol_solver-result>>
<<sol_solver-trait>>

<<sol_solver-control>>
<<sol_solver-communicator-error>>
<<sol_solver-communicator>>
```

