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
今回は純リテラル除去については触れないことにする。

=== 単位伝播
単位伝播を扱えるように、`Clause`, `Cnf` にメソッドを追加する。

単位節であるかどうかを確認し、もしそうなら単位節によって導出されるリテラルを返し、
そうでなければ何も返さない。
```rust
//| id: cla_unit-literal
pub fn unit_literal(&self, assign: &Assignment) -> Option<Lit> {
    let mut candidate: Option<Lit> = None;
    for lit in &self.lits {
        match assign.values[lit.var_id] {
            Some(val) if val ^ lit.negated => return None,
            Some(_) => continue,
            None => {
                if candidate.is_some() {
                    return None;
                }
                candidate = Some(lit.clone());
            }
        }
    }
    candidate
}
```

単位節を表す構造体を作る。
CNFにおける節IDと、その単位節から導出されるリテラルを保持する。

```rust
//| id: cnf_unit-clause
pub struct UnitClause {
    pub clause_id: usize,
    pub lit: Lit
}
```

あとは、各項について単位節かどうかを調べ、もしあるなら `UnitClause` を作る。
```rust
//| id: cnf_collect-unit-clauses
pub fn collect_unit_clauses(&self, assign: &Assignment) -> Vec<UnitClause> {
    let mut unit_clauses = vec![];
    for i in 0..self.clauses.len() {
        if let Some(lit) = self.clauses[i].unit_literal(assign) {
            unit_clauses.push(UnitClause{
                clause_id: i,
                lit
            });
        }
    }
    return unit_clauses;
}
```

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
2. 割り当てが完全なとき、式を割り当てで評価してその結果を返す。
3. 未割り当ての変数を選んで真か偽にそれぞれ割り当てて再帰する。

```rust
//| id: dpll_dpll
fn dpll(&mut self, assign: &mut Assignment) -> Result<SatResult, H::Error> {
    <<dpll_unit-propagation>>
    <<dpll_eval-with-assignment>>
    <<dpll_decide>>
}
```

`propagated_vars` に単位伝播された変数を保管する。
各単位節について、適切に割り当てる。

```rust
//| id: dpll_unit-propagation
let mut propagated_vars = vec![];
let mut unit_clauses = self.cnf.collect_unit_clauses(assign);
while let Some(unit_clause) = unit_clauses.pop() {
    let propagated_lit = unit_clause.lit;
    let propagated_var_id = propagated_lit.var_id;
    let val = !propagated_lit.negated;
    assign.values[propagated_var_id] = Some(val);
    self.handler.handle_event(DpllSolverEvent::Propagated { idx: propagated_var_id, assign: val, reason: unit_clause.clause_id })?;
    propagated_vars.push(propagated_var_id);
}
```

ベースケースはほとんど前回と同じ。
```rust
//| id: dpll_eval-with-assignment
if assign.is_full() {
    let is_sat = self.cnf.is_satisfied_by(assign);
    self.handler.handle_event(DpllSolverEvent::Eval { result: is_sat })?;
    if is_sat {
        return Ok(SatResult::Sat(assign.clone()));
    }
    else {
        return Ok(SatResult::Unsat)
    }
}
```

`idx` の扱いが全探索の場合とは異なっているが、だいたい同じことをしている。
```rust
//| id: dpll_decide
let mut ret = SatResult::Unsat;
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
while let Some(var_id) = propagated_vars.pop() {
    assign.values[var_id] = None;
}
assign.values[idx] = None;
return Ok(ret);
```

```rust
//| file: rust/viska-sat/src/dpll.rs
use crate::{assignment::Assignment, cnf::Cnf, event_handler::EventHandler, solver::{SatResult, Solver}};

#[derive(Debug)]
pub enum DpllSolverEvent {
    Decide {idx: usize, assign: bool},
    Propagated {idx: usize, assign: bool, reason: usize},
    Eval {result: bool},
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
        Ok(SatResult::Unsat)
    }
}
```
