== ソルバのテスト
=== 共通部
これから様々なソルバを作っていくことになるので、
共通してテストできるようにする。
以下のテストを用意した：
/ `solve_with_logging()`: CNFを1つだけ解く。このときはログを出すようにする。
/ `solve_many_small()`: 小さなCNFをたくさん解く。
/ `solve_many_large()`: 大きなCNFをたくさん解く。

そのために、CNF・ハンドラ・ソルバ・クロージャを引数に取って問題を解く関数 `run_solver()` を定義する。
```rust
//| id: vst_run-solver
fn run_solver<S, H, F>(cnf: Cnf, handler: H, make_solver: F) -> (Result<SatResult, S::Error>, Duration)
where
    S: Solver,
    H: EventHandler,
    F: FnOnce(Cnf, H) -> S
{
    let mut solver = make_solver(cnf, handler);
    let start = Instant::now();
    let result = solver.solve();
    let elapsed = start.elapsed();
    (result, elapsed)
}
```

`solve_with_logging()` で解くCNFは次の通り：
$
(x_1 or x_2 or x_3) and (not x_1 or not x_2) and (x_1 or not x_2 or not x_3)
$
これをCNFで表すと次のようになる：
```rust
//| id: vst_sample-cnf
let sample_cnf = Cnf {
    num_vars: 3,
    clauses: vec![
        Clause { lits: vec![
            Lit { var_id: 0, negated: false },
            Lit { var_id: 1, negated: false },
            Lit { var_id: 2, negated: false },
        ], meta: () },
        Clause { lits: vec![
            Lit { var_id: 0, negated: true },
            Lit { var_id: 1, negated: true },
        ], meta: () },
        Clause { lits: vec![
            Lit { var_id: 0, negated: false },
            Lit { var_id: 1, negated: true },
            Lit { var_id: 2, negated: true },
        ], meta: () },
    ],
};
```

これを解かせるときに、ログを出すようにしたいので、ログを出すハンドラを定義する。
```rust
//| id: vst_logger-handler
pub struct LoggerHandler<E: Debug> {
    _marker: PhantomData<E>
}

impl<E: Debug> LoggerHandler<E> {
    fn new() -> Self {
        Self {
            _marker: PhantomData
        }
    }
}

impl<E: Debug> EventHandler for LoggerHandler<E> 
{
    type Event = E;
    type Error = ();

    fn handle_event(&mut self, event: Self::Event) -> Result<(), Self::Error> {
        println!("{:?}", event);
        Ok(())
    }
}
```

そして、このハンドラを渡してソルバのインスタンスを作り、走らせる。

```rust
//| id: vst_solve-with-logging
pub fn solve_with_logging<S, F>(make_solver: F)
where
    S: Solver,
    S::Event: Debug,
    F: FnOnce(Cnf, LoggerHandler<S::Event>) -> S
{
    <<vst_sample-cnf>>
    let handler = LoggerHandler::<S::Event>::new();
    let (_result, elapsed) = run_solver(sample_cnf, handler, make_solver);
    println!("time: {:?}", elapsed);
}
```

```rust
//| id: vst_solve-many-small
```

```rust
//| id: vst_solve-many-large
```

```rust
//| file: rust/viska-sat/tests/common.rs
use viska_sat::{clause::Clause, cnf::Cnf, event_handler::EventHandler, lit::Lit, solver::{SatResult, Solver}};
use std::fmt::Debug;
use std::marker::PhantomData;
use std::time::{Duration, Instant};
<<vst_run-solver>>
<<vst_logger-handler>>
<<vst_solve-with-logging>>
<<vst_solve-many-small>>
<<vst_solve-many-large>>
```

=== `BruteForceSolver`
```rust
//| file: rust/viska-sat/tests/brute_force_solver.rs
mod common;
use common::solve_with_logging;
use viska_sat::brute_force::BruteForceSolver;

#[test]
fn brute_force_solver_with_logging() {
    solve_with_logging(|cnf, handler| BruteForceSolver{ cnf, handler });
}
```
=== `DpllSolver`
```rust
//| file: rust/viska-sat/tests/dpll_solver.rs
mod common;
use common::solve_with_logging;
use viska_sat::dpll::DpllSolver;

#[test]
fn dpll_with_logging() {
    solve_with_logging(|cnf, handler| DpllSolver{ cnf, handler });
}
```
