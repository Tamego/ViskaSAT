== CDCLの基礎
=== 概要
単位伝播によってDPLLでは探索空間を削減していたが、
ここではさらなる効率化を行う。

以下のCNFを考えてみよう：
$
(not x_1 or x_2) and (not x_3 or x_5) and (not x_4 or x_5) and (not x_6 or not x_7)
\ and (not x_1 or not x_5 or x_6) and (not x_2 or not x_5 or x_7)
$
これをDPLLで解いてみると次のようなステップになる：
1. ${x_1 mapsto "true"}$ と決定する。
2. 単位伝播により ${x_2 mapsto "true"}$。
3. ${x_3 mapsto "true"}$ と決定する。
4. 単位伝播により ${x_5 mapsto "true", x_6 mapsto "true", x_7 mapsto "true"}$。
5. $not x_6 or not x_7$ が非充足となり矛盾。
  $x_3, x_5, x_6, x_7$ の割り当てを削除する。
6. ${x_3 mapsto "false"}$ と決定する。
7. ${x_4 mapsto "true"}$ と決定する。
8. 単位伝播により ${x_5 mapsto "true", x_6 mapsto "true", x_7 mapsto "true"}$。
9. $not x_6 or not x_7$ が非充足となり矛盾。
  $x_4, x_5, x_6, x_7$ の割り当てを削除する。
10. （以下省略）
ここで4, 5と8, 9で行なっている作業はほとんど同じである。
4, 5の経験を活かして8, 9の探索を削減できることが望ましい。
矛盾の原因を学習して同じ間違いを繰り返さないようにする仕組みを備えたものがCDCLソルバである。

CDCLのコンセプトを説明する前に基本的な用語を定義する：
/ 決定レベル: 各変数における割り当てがどの決定に結び付いているかを表す。
  たとえば決定レベル1の変数は、1回目の決定に由来するということを表す。
/ バックトラック: 指定された決定レベルより大きい決定レベルの変数の割り当てを削除すること。

CDCLの*学習*の基本原理として*導出原理*という法則がある。
リテラル $a_1, a_2, dots, a_m$, $b_1, b_2, dots, b_n$, $alpha$ について、
$
(a_1 or a_2 or dots or a_m or alpha) and (b_1 or b_2 or dots or b_n or not alpha)
$
#h(-1em)から
$
a_1 or a_2 or dots or a_m or b_1 or b_2 or dots or b_n
$
#h(-1em)が導かれるという法則のことである。

ここで、矛盾の根本的な原因を考察してみる。
決定レベルが $d$ であるような決定をして、その後の単位伝播によって、節 $c$ が矛盾することが分かった。
ここで、決定レベルが $d - 1$ の時点では矛盾する節はないので、
節 $c$ には決定レベル $d$ で決定されたリテラルとそれに由来する伝播されたリテラルが含まれている。
節 $c$ に含まれる決定レベル $d$ で伝播されたリテラルを $alpha$ とおく。
すると、リテラル $a_1, a_2, dots, a_m$ を用いて節 $c$ は次のように書ける：
$
c = a_1 or a_2 or dots or a_m or not alpha
$
#h(-1em)ここで、決定レベル $d$ において $alpha$ が伝播されていることから、
その伝播の理由となる単位節が存在する。
その単位節を $u$ として、リテラル $b_1, b_2, dots, b_n$ を用いて節 $u$ は次のように書ける：
$
u = b_1 or b_2 or dots or b_n or alpha
$
#h(-1em)したがって、導出原理により以下の節 $l$ が導かれる：
$
l = a_1 or a_2 or dots or a_m or b_1 or b_2 or dots or b_n
$
#h(-1em)ここで、この節を式に加えても充足可能性は変化しないので、
この得られた節を*学習節*として加えても問題ない。
この一連の操作によって学習節を生成することを*学習*という。

この得られた学習節の意味を考えてみよう。
もともと、矛盾の原因はリテラル $a_1, a_2, dots, a_m$ と $not alpha$ が全て充足しないことであった。
そもそも $not alpha$ が充足しない原因は $alpha$ が充足することであって、
それは単位節 $u$ による伝播が原因であった。
それは節 $u$ が単位節になること、つまり $b_1, b_2, dots, b_n$ が全て充足しないことである。
だから結局 $a_1, a_2, dots, a_m$ と $b_1, b_2, dots, b_n$ が全て充足しないことが矛盾の原因である。
よって、学習節として、これらのリテラルのどれかが充足するという条件を表す節 $l$ が得られる。
こうして、$alpha$ を使わずに矛盾の原因を表現することができた。

ここで注目したいのは、節 $c$ に含まれる決定レベル $d$ で伝播されたリテラルであれば同じ操作ができて、
そのリテラルを使わない形で矛盾の原因を表現することができるということである。
この操作をできる限り繰り返すことで、
決定レベルが $d$ であるようなリテラルがただ1つのみ含まれるような学習節 $l'$ を必ず作ることができる。
そのリテラルを $beta$ とする。
すると、現在の割り当てでは $l'$ 内のリテラルは全て充足しないことを踏まえれば、
$l'$ のリテラルの決定レベルの中で2番目に大きい決定レベル、
つまり決定レベルが $d$ でないもののうち最も大きい決定レベルにバックトラックすると
節 $l'$ はただちに単位節となる。
したがって、すぐに $beta$ が伝播される。
矛盾の原因を解析することで大幅に探索空間が削減されることが分かる。
この解析を*矛盾の解析*などと呼んだりする。

この一連の操作は*含意グラフ*を用いることで視覚的に捉えることができる。
ただし、この部分はビジュアライザのドキュメントの方に譲ろうと思う。

経験的に、矛盾節に含まれる決定レベル $d$ のリテラルであって、
最も直近に割り当てられたものから順番に導出原理を適用させることで、
得られる学習節が短く効果的になることが知られているそう。
実装が簡便であることから、今回はこの方針を取る。

実際に具体例を通してどのようにCDCLの学習が効果的に働くかを見てみよう。
以下のように節に名前を付けて、その連言を考える。
$
c_1 = not x_1 or x_2,quad c_2 = not x_3 or x_5,\
c_3 = not x_4 or x_5,quad c_4 = not x_6 or not x_7,\
c_5 = not x_1 or not x_5 or x_6,quad c_6 = not x_2 or not x_5 or x_7\
$
- 決定（レベル1）
  - ${x_1 mapsto "true"}$ と決定する。
  - 単位伝播により ${x_2 mapsto "true"}$。
- 決定（レベル2）
  - ${x_3 mapsto "true"}$ と決定する。
  - 単位伝播により ${x_5 mapsto "true", x_6 mapsto "true", x_7 mapsto "true"}$。
  - $c_4$ が非充足となり矛盾。
- 矛盾の解析
  - 矛盾節は $not x_6 or not x_7$
  - $x_7$ の伝播理由は $c_6$。
    ここで導出原理により、$not x_2 or not x_5 or not x_6$。
  - $x_6$ の伝播理由は $c_5$。
    ここで導出原理により、$not x_1 or not x_2 or not x_5$
  - 決定レベルが2であるリテラルが $not x_5$ になったので終了。
    これを学習節 $c_7 = not x_1 or not x_2 or not x_5$ とする。
- バックトラック
  - $c_7$ において2番目に大きい決定レベルは1なので、決定レベル1にバックトラックする。
  - 割り当ては ${x_1 mapsto "true", x_2 mapsto "true"}$。
  - 単位伝播により、${x_5 mapsto "false", x_6 mapsto "false", x_7 mapsto "false"}$
- （以下省略）
これをDPLLと比較すれば、学習節によって、直ちに ${x_5 mapsto "false"}$ が結論付けらていて、
無駄な探索が減っていることが分かる。

=== 実装
DPLL では再帰関数によって実装したが、
CDCL ではバックトラックによって指定の決定レベルまで割り当てを戻すことが何度も発生するので、
柔軟なバックトラックのために非再帰の形で実装する。

アルゴリズムは以下のような流れになる：
- 進捗が生まれなくなるまで単位伝播する。
  - 決定レベル0で矛盾した場合、UNSAT。
  - 決定レベルが1以上で矛盾した場合、矛盾の解析をして学習節を追加しバックトラックする。
  - 矛盾しなかった場合、決定をする。
    これ以上決定できる変数がなければ SAT。
- 最初に戻る。

単位伝播の実装や次の変数を選ぶ処理はDPLLのものを流用する。
```rust
//| id: scdcl_cdcl
fn cdcl(&mut self) -> Result<SatResult, H::Error> {
    <<scdcl_setup>>
    loop {
        <<scdcl_bcp>>
        <<scdcl_conflict>>
        <<scdcl_decide>>
    }
}
```

特別なデータ構造*Trail*を定めることで、これまでの割り当てと決定レベルを保持できるようにする。
リテラルの割り当ての追加に対応する構造 `Step` を定める。
その割り当てが何に由来するかや決定レベルを表す。
```rust
//| id: scdcl_step
#[derive(Clone)]
enum AssignmentReason {
    Decision,
    UnitPropagation{clause_id: usize}
}

struct Step {
    lit: Lit,
    decision_level: usize,
    reason: AssignmentReason
}
```

そして `Step` をスタックとして持つ構造 `Trail` を考える。
また補助的に今の割り当てと決定レベルを保持する。
これらは `Step` のスタックを見ることによって計算できるが、
毎回計算するのは効率的でないので、これらを持つようにした。

```rust
//| id: scdcl_trail
<<scdcl_step>>

struct Trail {
    trail: Vec<Step>,
    assign: Assignment,
    decision_levels: Vec<Option<usize>>,
    current_decision_level: usize,
}

impl Trail {
    <<scdcl_push-step>>
    <<scdcl_trail-backtrack>>
}
```

Trail に割り当てを追加するメソッドを持たせる。
```rust
//| id: scdcl_push-step
fn push_step(&mut self, lit: Lit, reason: AssignmentReason) {
    if matches!(reason, AssignmentReason::Decision) {
        self.current_decision_level += 1;
    }
    let var_id = lit.var_id;
    self.assign.values[var_id] = Some(!lit.negated);
    self.decision_levels[var_id] = Some(self.current_decision_level);
    self.trail.push(Step {
        decision_level: self.current_decision_level,
        lit,
        reason
    });
}
```

また、バックトラックの処理も Trail が担当する。
トレイルの先頭がバックトラックしたい決定レベル以下になるまで削除を繰り返す。
```rust
//| id: scdcl_trail-backtrack
fn backtrack(&mut self, level: usize) {
    while let Some(step) = self.trail.last() {
        if step.decision_level <= level {
            break;
        }

        let var_id = step.lit.var_id;
        self.assign.values[var_id] = None;
        self.decision_levels[var_id] = None;
        self.trail.pop();
    }
    self.current_decision_level = level;
}
```

このように定義した Trail をループの外で初期化する。

```rust
//| id: scdcl_setup
let mut trail = Trail {
    trail: vec![],
    assign: Assignment {
        values: vec![None; self.cnf.num_vars]
    },
    decision_levels: vec![None; self.cnf.num_vars],
    current_decision_level: 0
};
```

矛盾に突き当たるかこれ以上単位節がなくなるまで単位伝播を繰り返す。

```rust
//| id: scdcl_bcp
let bcp_result = self.repeat_unit_propagate(&mut trail)?;
```

矛盾に突き当たった場合は、決定レベルが0でなければ矛盾の解析をする。
矛盾の解析は次のような手順となる：
- 終了条件が満されるまで以下を繰り返す：
  - トレイルの先頭のリテラルを取り出す。
  - 現在の学習節にその否定が含まれているなら導出原理によって新たに学習節を得る。
  - トレイルからそのリテラルを削除する。
- バックトラックすべき決定レベルを返す。
#h(-1em)ここでの終了条件は、学習節に現在の決定レベルのリテラルがただ1つだけ含まれることとした。

```rust
//| id: scdcl_analyze-conflict
fn analyze_conflict(
    &mut self,
    trail: &mut Trail,
    conflict_clause_id: usize
) -> Result<(usize, Lit, usize), H::Error> {
    <<scdac_setup>>
    <<scdac_loop>>
    <<scdac_finalize>>
}
```

まず学習節を初期化して、その中に含まれる現在の決定レベルのリテラルの個数を計算する。
また、学習節に追加されている変数を管理する `presence` 配列を用意する。
そして、トレイルを先頭から見ていくことになるから、その今見ている位置を表す変数 `trail_pos` も用意する。
```rust
//| id: scdac_setup
let mut learnt_clause = self.cnf.clauses[conflict_clause_id].clone();
let mut current_level_lits = HashSet::new();
let mut presence = vec![None; self.cnf.num_vars];
let mut trail_pos = trail.trail.len() - 1;
let mut backtrack_level = 0;
for (lit_id, lit) in learnt_clause.lits.iter().enumerate() {
    let id = lit.var_id;
    presence[id] = Some(lit_id);
    if trail.decision_levels[id]
        .expect("literal must have been assigned") == trail.current_decision_level {
        current_level_lits.insert(lit.clone());
    }
}
```

学習節に現在の決定レベルのリテラルがただ1つだけ含まれている状態になるまで導出原理による解消を繰り返す。
```rust
//| id: scdac_loop
while current_level_lits.len() > 1 {
    <<scdac_choose-literal>>
    <<scdac_resolve>>
}
```

Trail を先頭から見ていく。
今の学習節の中に含まれているリテラルを見つけるまで探す。
```rust
//| id: scdac_choose-literal
let last_assigned_lit = loop {
    let lit = trail.trail[trail_pos].lit.clone();
    if let Some(_) = presence[lit.var_id] {
        break lit;
    }
    trail_pos -= 1;
};
```

そのリテラルを単位伝播によって導くこととなった理由の節と今の学習節を合わせて解消する。
```rust
//| id: scdac_resolve
let reason_clause_id = match trail.trail[trail_pos].reason {
    AssignmentReason::UnitPropagation { clause_id } => {clause_id},
    AssignmentReason::Decision => panic!("conflict clause should not select a decision literal at this stage")
};
self.resolve(
    trail,
    last_assigned_lit.clone(),
    &self.cnf.clauses[reason_clause_id],
    &mut learnt_clause,
    &mut presence,
    &mut backtrack_level,
    &mut current_level_lits
);
self.handler.handle_event(
    SimpleCdclSolverEvent::Resolve {
        lit: last_assigned_lit,
        reason_clause_id,
        learnt_clause: learnt_clause.clone()
})?;
```

そして最後にループを抜けて得られた学習節を式に追加し、バックトラックすべき決定レベルを返す。
```rust
//| id: scdac_finalize
self.handler.handle_event(SimpleCdclSolverEvent::LearntClause { clause: learnt_clause.clone() })?;
self.cnf.clauses.push(learnt_clause);
Ok((
    backtrack_level,
    current_level_lits
        .iter().next()
        .expect("current level set should contain at least one element").clone(),
    self.cnf.clauses.len() - 1
))
```

先程登場した解消の手順は以下の通り：
- 起点となるリテラルを矛盾節の方から削除する。
- 理由節のリテラルを矛盾節に加えて学習節とする。

起点となるリテラルを削除する。
このことによって `presence` の保持するインデックスがズレるので、その更新も行う。
```rust
//| id: scdre_remove-lit
let resolve_lit_var_id = resolve_lit.var_id;
let resolve_lit_id = presence[resolve_lit_var_id].expect("resolve literal must exist in the learnt clause");
current_level_lits.remove(&resolve_lit.inv());
conflict_clause.lits.swap_remove(resolve_lit_id);
presence[resolve_lit_var_id] = None;
if resolve_lit_id < conflict_clause.lits.len() {
    let swaped_lit = &conflict_clause.lits[resolve_lit_id];
    presence[swaped_lit.var_id] = Some(resolve_lit_id);
};
```

理由節のリテラルでまだ矛盾節の方に加わっていないものだけ加える。
```rust
//| id: scdre_add-lit
for lit in &reason_clause.lits {
    let var_id = lit.var_id;
    if presence[var_id].is_some() || var_id == resolve_lit_var_id {
        continue;
    }

    let idx = conflict_clause.lits.len();
    conflict_clause.lits.push(lit.clone());
    presence[var_id] = Some(idx);

    let decision_level = trail.decision_levels[lit.var_id].expect("literal in reason clause must have a decision level");
    if decision_level < trail.current_decision_level {
        *backtrack_level = (*backtrack_level).max(decision_level);
    } else if decision_level == trail.current_decision_level {
        current_level_lits.insert(lit.clone());
    }
}
```

```rust
//| id: scdcl_resolve
fn resolve(
    &self,
    trail: &mut Trail,
    resolve_lit: Lit,
    reason_clause: &Clause,
    conflict_clause: &mut Clause,
    presence: &mut Vec<Option<usize>>,
    backtrack_level: &mut usize,
    current_level_lits: &mut HashSet<Lit>
) {
    <<scdre_remove-lit>>
    <<scdre_add-lit>>
}
```

矛盾が発生した場合の処理。
もし決定レベルが0ならUNSAT。
そうじゃなければ矛盾の解析をしてバックトラックし、そのあとすぐに学習節によって単位伝播させる。
```rust
//| id: scdcl_conflict
if let Some(conflict_clause_id) = bcp_result {
    self.handler.handle_event(SimpleCdclSolverEvent::Conflict { reason: conflict_clause_id })?;
    if trail.current_decision_level == 0 {
        self.handler.handle_event(SimpleCdclSolverEvent::RootConflict)?;
        return Ok(SatResult::Unsat);
    }

    let (backtrack_level, assert_lit, learnt_clause_id) =
        self.analyze_conflict(&mut trail, conflict_clause_id)?;
    self.handler.handle_event(SimpleCdclSolverEvent::BacktrackTo { level: backtrack_level })?;
    trail.backtrack(backtrack_level);

    trail.push_step(
        assert_lit.clone(),
        AssignmentReason::UnitPropagation { clause_id: learnt_clause_id }
    );
    self.handler.handle_event(
        SimpleCdclSolverEvent::Propagate {
            idx: assert_lit.var_id,
            assign: !assert_lit.negated,
            reason: learnt_clause_id
        }
    )?;
}
```

もしそうでなければ決定をする。
これ以上決定できる変数がなければSAT。

```rust
//| id: scdcl_decide
else {
    if let Some(var_id) = self.pick_unassigned_var(&trail.assign) {
        self.handler.handle_event(
            SimpleCdclSolverEvent::Decide { idx: var_id, assign: true }
        )?;
        trail.push_step(Lit {var_id, negated: false}, AssignmentReason::Decision);
    } else {
        return Ok(SatResult::Sat(trail.assign));
    }
}
```

```rust
//| id: scdcl_repeat-unit-propagation
fn repeat_unit_propagate(
    &mut self,
    trail: &mut Trail,
) -> Result<Option<usize>, H::Error> {
    'outer: loop {
        for (clause_id, clause) in self.cnf.clauses.iter().enumerate() {
            match clause.eval(&trail.assign) {
                ClauseState::Unit(lit) => {
                    let idx = lit.var_id;
                    let val = !lit.negated;
                    self.handler.handle_event(
                        SimpleCdclSolverEvent::Propagate { idx, assign: val, reason: clause_id }
                    )?;
                    trail.push_step(lit, AssignmentReason::UnitPropagation { clause_id });
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

```rust
//| file: rust/viska-sat/src/simple_cdcl.rs
use crate::{assignment::Assignment, clause::{Clause, ClauseState}, cnf::Cnf, event_handler::EventHandler, lit::Lit, solver::{SatResult, Solver}};
use std::collections::HashSet;

#[derive(Debug)]
pub enum SimpleCdclSolverEvent {
    Decide {idx: usize, assign: bool},
    Propagate {idx: usize, assign: bool, reason: usize},
    Conflict {reason: usize},
    Resolve {lit: Lit, reason_clause_id: usize, learnt_clause: Clause},
    LearntClause {clause: Clause},
    RootConflict,
    BacktrackTo {level: usize},
    Finish {result: SatResult}
}

<<scdcl_trail>>

pub struct SimpleCdclSolver<H> 
{
    pub cnf: Cnf,
    pub handler: H
}

impl<H> SimpleCdclSolver<H>
where
    H: EventHandler<Event = SimpleCdclSolverEvent>
{
    <<dpll_pick-unassigned-var>>

    <<scdcl_repeat-unit-propagation>>

    <<scdcl_resolve>>

    <<scdcl_analyze-conflict>>

    <<scdcl_cdcl>>
}

impl<H> Solver for SimpleCdclSolver<H>
where
    H: EventHandler<Event = SimpleCdclSolverEvent>
{
    type Event = SimpleCdclSolverEvent;
    type Handler = H;
    type Error = H::Error;

    fn solve(&mut self) -> Result<SatResult, Self::Error> {
        let result = self.cdcl()?;
        self.handler.handle_event(SimpleCdclSolverEvent::Finish { result: result.clone() })?;
        Ok(result)
    }
}
```
