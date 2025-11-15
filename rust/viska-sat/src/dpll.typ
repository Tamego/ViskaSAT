== DPLL <sec_dpll>
=== 概要
全探索は確実に問題を解くことができる反面、
$O(2^n)$ の計算量では $n$ が大きくなったときに実行が現実的な時間で終わらない。
全探索の探索空間を削減することで、多少の改善を試みる。

たとえば以下のCNFについて考える：
$
(x_1 or x_2 or x_3) and (not x_1 or not x_2) and (x_1 or not x_2 or not x_3)
$
ここで、${x_1 mapsto "true"}$ と割り当てると、節 $x_1 or x_2 or x_3$ は充足し、
節 $x_1 or not x_2 or not x_3$ は同様に充足する。
したがって、問題の式は $not x_1 or not x_2$ に簡約される。

ここで、${x_1 mapsto "true", x_2 mapsto "true"}$ と割り当てを追加したとしよう。
すると、$not x_1 or not x_2$ は*矛盾*（conflict）となってしまい、$x_3$ をどのように割り当てても充足不能のままとなる。

実際には、$not x_1 or not x_2$ において、節内に登場するリテラルが1つ（$not x_2$）を除いて全て割り当てられていて、
その全てが割り当てによって充足していないという条件から、
自動的に $x_2$ は $not x_2$ を充足するような割り当て、つまり ${x_2 mapsto "false"}$ を追加することができる。
この条件をみたす節を*単位節*と言い、その単位節における未割り当てのリテラルを充足するように割り当てを追加することができる。
これを*単位伝播*という。

全探索と単位伝播を組み合わせることで、明らかに充足不能な枝の探索を削減できる。
新たな割り当てを追加するたびに、単位節がなくなるまで単位伝播をすることでこれを実現した。
また、完全な割り当てでなくとも1つの節が充足不能になってしまえば全体として充足不能となるので、
この場合もすぐに探索を終了するようにした。
今回は純リテラル除去については触れないことにする。

=== 実装
全探索ソルバでは `idx` を使ってどこまで割り当てたかを管理していた。
しかし、単位伝播を採用したことでidが小さい順に割り当てられていく保証がなくなったので、
割り当ての中で未割り当てである変数の最も小さいidを取得する関数 `pick_unassigned_var()` を用意することで一旦対処する。

```rust
//| id: dpll_pick-unassigned-var
fn pick_unassigned_var(&self, assign: &Assignment) -> Option<usize> {
    for i in 0..assign.values.len() {
        if assign.values[i].is_none() {
            return Some(i);
        }
    }
    return None;
}
```

ソルバの構造は以下のようになっている：
1. 単位伝播を進展が生まれなくなるまで実行する。
  このとき伝播した変数のidをスタックに入れておく。
  充足不能となるとすぐに中断する。
2. 割り当てが完全なとき、式を割り当てで評価してその結果を返す。
3. 未割り当ての変数を選んで真か偽にそれぞれ割り当てて再帰する。

```rust
//| id: dpll_dpll
fn dpll(&mut self, assign: &mut Assignment) -> Result<SatResult, H::Error> {
    let mut ret = SatResult::Unsat;
    <<dpll_unit-propagation-and-conflict>>
    <<dpll_eval-with-assignment>>
    <<dpll_decide>>
    <<dpll_return>>
}
```

単位伝播を単位節がなくなるもしくは矛盾が発生するまで繰り返す関数を用意する。
もし矛盾したならその節のidを返す。
```rust
//| id: dpll_repeat-unit-propagation
fn repeat_unit_propagate(
    &mut self,
    assign: &mut Assignment,
    propagated_vars: &mut Vec<usize>
) -> Result<Option<usize>, H::Error> {
    'outer: loop {
        for (clause_id, clause) in self.cnf.clauses.iter().enumerate() {
            match clause.eval(assign) {
                ClauseState::Unit(lit) => {
                    let idx = lit.var_id;
                    let val = !lit.negated;
                    self.handler.handle_event(
                        DpllSolverEvent::Propagate { idx, assign: val, reason: clause_id }
                    )?;
                    assign.values[idx] = Some(val);
                    propagated_vars.push(idx);
                    continue 'outer;
                }
                ClauseState::Unsatisfied => return Ok(Some(clause_id)),
                _ => {}
            }
        }
        break;
    }
    Ok(None)
}
```

`propagated_vars` に単位伝播された変数を保管する。
`unit_propagate()` で矛盾が発生したなら、充足不能と返す。

```rust
//| id: dpll_unit-propagation-and-conflict
let mut propagated_vars = vec![];
if let Some(clause_id) = self.repeat_unit_propagate(assign, &mut propagated_vars)? {
    self.handler.handle_event(DpllSolverEvent::Conflict { reason: clause_id })?;
    ret = SatResult::Unsat;
} 
```

割り当てが完全なとき、式を評価してその結果を返す。

```rust
//| id: dpll_eval-with-assignment
else if assign.is_full() {
    let sat_state = self.cnf.eval(assign);
    self.handler.handle_event(DpllSolverEvent::Eval { result: sat_state.clone() })?;
    match sat_state {
        CnfState::Satisfied => return Ok(SatResult::Sat(assign.clone())),
        CnfState::Unsatisfied => return Ok(SatResult::Unsat),
        CnfState::Unresolved => panic!("full assignment cannot be unresolved")
    };
}
```

式が未解決のときは、全探索のときと同じように変数を決定する。
`idx` の扱いが全探索の場合とは異なっているが、だいたい同じことをしている。
```rust
//| id: dpll_decide
else {
    let idx = self.pick_unassigned_var(assign).expect("branching called with fully assigned assignment");
    for choice in [true, false] {
        self.handler.handle_event(DpllSolverEvent::Decide { idx, assign: choice })?;
        assign.values[idx] = Some(choice);
        let result = self.dpll(assign)?;
        self.handler.handle_event(DpllSolverEvent::Backtrack { idx })?;
        match result {
            sat @ SatResult::Sat(_) => {
                ret = sat;
                break;
            }
            SatResult::Unsat => {}
        }
    }
    assign.values[idx] = None;
}
```

最後に結果を返す。
```rust
//| id: dpll_return
while let Some(var_id) = propagated_vars.pop() {
    assign.values[var_id] = None;
    self.handler.handle_event(DpllSolverEvent::Backtrack { idx: var_id })?;
}
return Ok(ret);
```

```rust
//| file: rust/viska-sat/src/dpll.rs
use crate::{assignment::Assignment, clause::ClauseState, cnf::{Cnf, CnfState}, event_handler::EventHandler, solver::{SatResult, Solver}};

#[derive(Debug)]
pub enum DpllSolverEvent {
    Decide {idx: usize, assign: bool},
    Propagate {idx: usize, assign: bool, reason: usize},
    Eval {result: CnfState},
    Conflict {reason: usize},
    Backtrack {idx: usize},
    Finish {result: SatResult}
}

pub struct DpllSolver<H> 
{
    pub cnf: Cnf,
    pub handler: H
}

impl<H> DpllSolver<H>
where
    H: EventHandler<Event = DpllSolverEvent>
{
    <<dpll_pick-unassigned-var>>

    <<dpll_repeat-unit-propagation>>

    <<dpll_dpll>>
}

impl<H> Solver for DpllSolver<H>
where
    H: EventHandler<Event = DpllSolverEvent>
{
    type Event = DpllSolverEvent;
    type Handler = H;
    type Error = H::Error;

    fn solve(&mut self) -> Result<SatResult, Self::Error> {
        let result = self.dpll(&mut Assignment { values: vec![None; self.cnf.num_vars]})?;
        self.handler.handle_event(DpllSolverEvent::Finish { result: result.clone() })?;
        Ok(result)
    }

    fn make_solver(cnf: Cnf, handler: H) -> Self {
        DpllSolver { cnf, handler }
    }
}
```
