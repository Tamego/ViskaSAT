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

`solve_with_logging()` では用意されたいくつかのCNFを選んで解くことができる。
1. @sec_dpll 節で出てきたCNF。
  $
  (x_1 or x_2 or x_3) and (not x_1 or not x_2) and (x_1 or not x_2 or not x_3)
  $
```rust
//| id: vst_sample-cnf
let sample_cnfs = vec![
    Cnf {
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
    },
    Cnf {
        num_vars: 7,
        clauses: vec![
            Clause { lits: vec![
                Lit { var_id: 0, negated: true },
                Lit { var_id: 1, negated: false },
            ], meta: () },
            Clause { lits: vec![
                Lit { var_id: 2, negated: true },
                Lit { var_id: 4, negated: false },
            ], meta: () },
            Clause { lits: vec![
                Lit { var_id: 3, negated: true },
                Lit { var_id: 4, negated: false },
            ], meta: () },
            Clause { lits: vec![
                Lit { var_id: 5, negated: true },
                Lit { var_id: 6, negated: true },
            ], meta: () },
            Clause { lits: vec![
                Lit { var_id: 0, negated: true },
                Lit { var_id: 4, negated: true },
                Lit { var_id: 5, negated: false },
            ], meta: () },
            Clause { lits: vec![
                Lit { var_id: 1, negated: true },
                Lit { var_id: 4, negated: true },
                Lit { var_id: 6, negated: false },
            ], meta: () },
        ],
    }
];
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
pub fn solve_with_logging<S, F>(make_solver: F, test_num: usize)
where
    S: Solver,
    S::Event: Debug,
    F: FnOnce(Cnf, LoggerHandler<S::Event>) -> S
{
    <<vst_sample-cnf>>
    let cnf = sample_cnfs[test_num].clone();
    println!("problem: {:?}", test_num);
    let handler = LoggerHandler::<S::Event>::new();
    let (_result, elapsed) = run_solver(cnf, handler, make_solver);
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
use viska_sat::{brute_force::BruteForceSolver, solver::Solver};

#[test]
fn brute_force_solver_with_logging() {
    for i in 0..=1 {
        solve_with_logging(BruteForceSolver::make_solver, i);
    }
}
```
=== `DpllSolver`
```rust
//| file: rust/viska-sat/tests/dpll_solver.rs
mod common;
use common::solve_with_logging;
use viska_sat::{dpll::DpllSolver, solver::Solver};

#[test]
fn dpll_with_logging() {
    for i in 0..=1 {
        solve_with_logging(DpllSolver::make_solver, i);
    }
}
```

=== `SimpleCdclSolver`
```rust
//| file: rust/viska-sat/tests/simple_cdcl_solver.rs
mod common;
use common::solve_with_logging;
use viska_sat::{simple_cdcl::SimpleCdclSolver, solver::Solver};

#[test]
fn simple_cdcl_with_logging() {
    for i in 0..=1 {
        solve_with_logging(SimpleCdclSolver::make_solver, i);
    }
}
```
