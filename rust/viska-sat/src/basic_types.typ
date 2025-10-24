== 基本的な型
=== 割り当て
各変数に真偽値を対応付ける構造を*割り当て*という。
全ての変数に真偽値が割り当てられているとき、その割り当ては*完全*であるという。
真・偽・未割り当ての3つの値を取り得るので、`Option<bool>` 型を取ることで対応する。
それの配列として割り当てを表現する。
つまり、割り当てが完全なとき、各要素は `Some(true)` か `Some(false)` のいずれかである。
```rust
//| file: rust/viska-sat/src/assignment.rs
#[derive(Debug, Clone)]
pub struct Assignment {
    pub values: Vec<Option<bool>>
}

impl Assignment {
    pub fn is_full(&self) -> bool {
        for val in &self.values {
            if val.is_none() {
                return false;
            }
        }
        return true;
    }
}
```

=== リテラル
*リテラル*とは原子論理式それ自体もしくはその否定のどちらかである。
とくに、原子論理式のときを*正リテラル*と言い、そうでないときは*負リテラル*という。
また、命題論理において原子論理式は命題変数だから、
リテラルとは命題変数それ自体かその否定のいずれかである。

変数が真に割り当てられたときに正リテラルは充足し、
偽に割り当てられたときに負リテラルは充足する。

`var` が命題変数を表し、`negated` が否定されているかどうかを表す。
`assign` を取って、以下のいずれかに評価する。
/ Satisfied: 充足
/ Unsatisfied: 非充足
/ Unassigned: 未割り当て

```rust
//| file: rust/viska-sat/src/lit.rs
use crate::assignment::Assignment;

#[derive(Debug, Clone, Eq, Hash, PartialEq)]
pub struct Lit {
    pub var_id: usize,
    pub negated: bool
}

pub enum LitState {
    Satisfied,
    Unsatisfied,
    Unassigned
}

impl Lit {
    pub fn eval(&self, assign: &Assignment) -> LitState {
        match assign.values[self.var_id] {
            None => LitState::Unassigned,
            Some(val) => if val ^ self.negated {LitState::Satisfied} else {LitState::Unsatisfied}
        }
    }
}
```

=== 節
リテラルをORで繋いだ論理式を*節*という。
`Lit` の配列として表現する。
CDCL ソルバのために必要ならメタ情報を付けることを可能にした。

節内のリテラルのいずれかが充足していれば、その節は充足する。
/ Satisfied: 充足
/ Unsatisfied: 非充足
/ Unit: 単位節
/ Unresolved: 未割り当てが複数個

```rust
//| file: rust/viska-sat/src/clause.rs
use crate::{assignment::Assignment, lit::{LitState, Lit}};
#[derive(Debug, Clone)]
pub struct Clause<Meta=()> {
    pub lits: Vec<Lit>,
    pub meta: Meta,
}

pub enum ClauseState {
    Satisfied,
    Unsatisfied,
    Unit(Lit) ,
    Unresolved
}

impl Clause {
    pub fn eval(&self, assign: &Assignment) -> ClauseState {
        let mut all_unsatisfied = true;
        let mut unit_lit = None;
        for lit in &self.lits {
            match lit.eval(assign) {
                LitState::Satisfied => return ClauseState::Satisfied,
                LitState::Unassigned => {
                    all_unsatisfied = false;
                    if unit_lit.is_some() {
                        return ClauseState::Unresolved;
                    }
                    unit_lit = Some(lit.clone());
                }
                _ => {}
            }
        }

        if all_unsatisfied {
            ClauseState::Unsatisfied
        } else if let Some(lit) = unit_lit {
            ClauseState::Unit(lit)
        } else {
            ClauseState::Unresolved
        }
    }
}
```

=== CNF（連言標準形）
節をANDで繋いだ構造をしている論理式を*CNF*という。
`Clause` の配列として表現する。
`num_vars` は変数の個数（最大の ID + 1）を表す。
全ての節が充足するときに充足する。

ClauseState が Unit であるような節を集めるメソッドを用意した。
```rust
//| file: rust/viska-sat/src/cnf.rs
use crate::{assignment::Assignment, clause::{Clause, ClauseState}};

#[derive(Debug, Clone)]
pub struct Cnf {
    pub clauses: Vec<Clause>,
    pub num_vars: usize
}

#[derive(Debug, Clone)]
pub enum CnfState {
      Satisfied,
      Unsatisfied,
      Unresolved,
}

impl Cnf {
    pub fn eval(&self, assign: &Assignment) -> CnfState {
        let mut all_satisfied = true;
        for clause in &self.clauses {
            match clause.eval(assign) {
                ClauseState::Unresolved => all_satisfied = false,
                ClauseState::Unsatisfied => return CnfState::Unsatisfied,
                _ => {}
            }
        }
        if all_satisfied {
            CnfState::Satisfied
        } else {
            CnfState::Unresolved
        }
    }
}
```

