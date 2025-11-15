== 全探索
=== 概要
「式を充足させる割り当てが存在するか？」という問いに確実に答えるためには、
ありえる割り当てを全て試せばよい。
完全な割り当ては各変数に対して真か偽のどちらかを対応付けたものなので、
$n$ 変数の完全な割り当ては $2^n$ 通りある。

=== 実装
今回は再帰関数を使って実装する。

```rust
//|  id: brf_brute-force
fn brute_force(&mut self, idx: usize, assign: &mut Assignment) -> Result<SatResult, H::Error> {
    <<brf_base-case>>
    <<brf_recursive-step>>
}
```

`assign` はこれまでの割り当てを表す。
`brute_force()` は `assign` を含む完全な割り当て#footnote[割り当て$A$, $B$ について、$B$ で割り当てらている変数全てについて、
$B$ で割り当てられていた値で $A$ に割り当てられていることを $A$ が $B$ を含むという。]
であって、式を充足するものはあるかどうかを返り値として返す。
簡略化のために、`idx` はまだ決定されていない変数の最小のidを保持して、
`assign` は `idx` より小さいのidの変数全てが割り当てられているようにする。

==== ベースケース
`assign` が完全なら、その割り当てで式を評価した結果を `SatResult` で返す。
```rust
//|id: brf_base-case
if assign.is_full() {
    let sat_state = self.cnf.eval(assign);
    self.handler.handle_event(BruteForceSolverEvent::Eval { result: sat_state.clone() })?;
    match sat_state {
        CnfState::Satisfied => return Ok(SatResult::Sat(assign.clone())),
        CnfState::Unsatisfied => return Ok(SatResult::Unsat),
        CnfState::Unresolved => panic!("full assignment cannot be unresolved")
    };
}
```

==== 再帰ステップ
`assign` に `idx` 番目の変数の割り当てを追加する。
真に割り当てた場合に充足すれば `Sat` を返す。
充足しなければ、偽に割り当てた場合を調べる。
充足すれ `Sat` を返し、そうでなければ `Unsat` を返す。

```rust
//| id: brf_recursive-step
let mut ret = SatResult::Unsat;
for choice in [true, false] {
    self.handler.handle_event(BruteForceSolverEvent::Decide { idx, assign: choice })?;
    assign.values[idx] = Some(choice);
    let result = self.brute_force(idx + 1, assign)?;
    self.handler.handle_event(BruteForceSolverEvent::Backtrack { idx })?;
    match result {
        sat @ SatResult::Sat(_) => {
            ret = sat;
            break;
        }
        SatResult::Unsat => {}
    }
}
assign.values[idx] = None;
return Ok(ret);
```

```rust
//| file: rust/viska-sat/src/brute_force.rs
use crate::{assignment::Assignment, cnf::{Cnf, CnfState}, event_handler::EventHandler, solver::{SatResult, Solver}};

#[derive(Debug)]
pub enum BruteForceSolverEvent {
    Decide {idx: usize, assign: bool},
    Eval {result: CnfState},
    Backtrack {idx: usize},
    Finish {result: SatResult}
}

pub struct BruteForceSolver<H> 
{
    pub cnf: Cnf,
    pub handler: H
}

impl<H> BruteForceSolver<H>
where
    H: EventHandler<Event = BruteForceSolverEvent>
{
    <<brf_brute-force>>
}

impl<H> Solver for BruteForceSolver<H>
where
    H: EventHandler<Event = BruteForceSolverEvent>
{
    type Event = BruteForceSolverEvent;
    type Handler = H;
    type Error = H::Error;

    fn solve(&mut self) -> Result<SatResult, Self::Error> {
        let result = self.brute_force(0, &mut Assignment { values: vec![None; self.cnf.num_vars]})?;
        self.handler.handle_event(BruteForceSolverEvent::Finish { result: result.clone() })?;
        Ok(result)
    }

    fn make_solver(cnf: Cnf, handler: H) -> Self {
        BruteForceSolver { cnf, handler }
    }
}
```
