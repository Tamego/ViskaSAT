== `Solver` トレイト<sec_solver>
様々なアルゴリズムに共通するインターフェースを与えるために `Solver` トレイトを定める。
`solve()` は問題を解き、充足可能（`SatResult::Sat`）か充足不能（`SatResult::Unsat`）かをを返す。

`SolverReulst` は列挙型で定義する。
```rust
//| id: sol_solver-result
#[derive(Debug, Clone)]
pub enum SatResult {
    Sat(Assignment),
    Unsat
}
```

`Solver` トレイトを定義する。
イベントの種類はソルバ依存なので、`Event` と関連型にして各ソルバが自由に決められるようにした。
`EventHandler` については@sec_event-handler 節を参照のこと。
```rust
//| id: sol_solver-trait
pub trait Solver {
    type Event;
    type Error;
    type Handler: EventHandler<Event = Self::Event, Error = Self::Error>;

    fn solve(&mut self) -> Result<SatResult, Self::Error>;

    fn make_solver(cnf: Cnf, handler: Self::Handler) -> Self;
}
```


```rust
//| file: rust/viska-sat/src/solver.rs
use crate::{assignment::Assignment, cnf::Cnf, event_handler::EventHandler};
<<sol_solver-result>>
<<sol_solver-trait>>
```

