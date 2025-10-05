== `Solver` トレイト<sec_solver>
様々なアルゴリズムに共通するインターフェースを与えるために `Solver` トレイトを定める。
ソルバ側の主な関数は以下の通り：
/ `Solver::initialize()`: 問題（`Cnf`）を引数に取ってSATソルバを初期化する。
  また、イベントを処理するためのハンドラも引数に取る。
/ `Solver::solve()`: 問題を解き、充足可能（`SatResult::Sat`）か充足不能（`SatResult::Unsat`）かをを返す。

`SolverReulst` は列挙型で定義する。
```rust
//| id: sol_solver-result
pub enum SatResult {
    Sat(Assignment),
    Unsat
}
```

`Solver` のイベントを処理する `EventHander` トレイトを定義する。
`handle_event()` でイベントを処理する。
```rust
//| id: evh_event-handler-trait
pub trait EventHandler {
    type Event;
    type Error;

    fn handle_event(&mut self, event: Self::Event) -> Result<(), Self::Error>;
}
```

`Solver` トレイトを定義する。
イベントの種類はソルバ依存なので、`Event` と関連型にして各ソルバが自由に決められるようにした。
```rust
//| id: sol_solver-trait
pub trait Solver {
    type Event;
    type Error;
    type Handler: EventHandler<Event = Self::Event, Error = Self::Error>;

    fn initialize(&mut self, problem: Cnf, handler: Self::Handler);
    fn solve(&mut self) -> Result<SatResult, Self::Error>;
}
```


```rust
//| file: rust/viska-sat/src/solver.rs
use crate::{assignment::Assignment, cnf::Cnf, event_handler::EventHandler};
<<sol_solver-result>>
<<sol_solver-trait>>
```

