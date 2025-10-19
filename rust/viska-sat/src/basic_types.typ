== 基本的な型
=== 割り当て
各変数に真偽値を対応付ける構造を*割り当て*という。
全ての変数に真偽値が割り当てられているとき、その割り当ては*完全*であるという。
真・偽・未割り当ての3つの値を取り得るので、`Option<bool>` 型を取ることで対応する。
それの配列として割り当てを表現する。
つまり、割り当てが完全なとき、各要素は `Some(true)` か `Some(false)` のいずれかである。
```rust
//| file: rust/viska-sat/src/assignment.rs
#[derive(Clone)]
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
`is_satisfied()` は完全な割り当てを取って、それに沿ってリテラルを評価した結果を返す。
完全でない場合はパニックする。

```rust
//| file: rust/viska-sat/src/lit.rs
use crate::assignment::Assignment;

pub struct Lit {
    pub var_id: usize,
    pub negated: bool
}

impl Lit {
    pub fn is_satisfied_by(&self, assign: &Assignment) -> bool {
        match assign.values[self.var_id] {
            None => panic!(),
            Some(val) => val ^ self.negated
        }
    }
}
```

=== 節
リテラルをORで繋いだ論理式を*節*という。
`Lit` の配列として表現する。
CDCL ソルバのために必要ならメタ情報を付けることを可能にした。

節内のリテラルのいずれかが充足していれば、その節は充足する。
```rust
//| file: rust/viska-sat/src/clause.rs
use crate::{assignment::Assignment, lit::Lit};
pub struct Clause<Meta=()> {
    pub lits: Vec<Lit>,
    pub meta: Meta,
}

impl Clause {
    pub fn is_satisfied_by(&self, assign: &Assignment) -> bool {
        for lit in &self.lits {
            if lit.is_satisfied_by(assign) {
                return true;
            }
        }
        return false;
    }
}
```

=== CNF（連言標準形）
節をANDで繋いだ構造をしている論理式を*CNF*という。
`Clause` の配列として表現する。
`num_vars` は変数の個数（最大の ID + 1）を表す。
全ての節が充足するときに充足する。
```rust
//| file: rust/viska-sat/src/cnf.rs
use crate::{assignment::Assignment, clause::Clause};
pub struct Cnf {
    pub clauses: Vec<Clause>,
    pub num_vars: usize
}

impl Cnf {
    pub fn is_satisfied_by(&self, assign: &Assignment) -> bool {
        for clause in &self.clauses {
            if !clause.is_satisfied_by(assign) {
                return false;
            }
        }
        return true;
    }
}
```

