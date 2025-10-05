== 基本的な型
=== リテラル
*リテラル*とは原子論理式それ自体もしくはその否定のどちらかである。
とくに命題論理において原子論理式は命題変数だから、
リテラルとは命題変数それ自体かその否定のいずれかである。

`var` が命題変数を表し、`negated` が否定されているかどうかを表す。
```rust
//| file: rust/viska-sat/src/lit.rs
pub struct Lit {
    pub var_id: usize,
    pub negated: bool
}
```

=== 節
リテラルをORで繋いだ論理式を*節*という。
`Lit` の配列として表現する。
CDCL ソルバのために必要ならメタ情報を付けることを可能にした。
```rust
//| file: rust/viska-sat/src/clause.rs
use crate::lit::Lit;
pub struct Clause<Meta=()> {
    pub lits: Vec<Lit>,
    pub meta: Meta,
}
```

=== CNF（連言標準形）
節をANDで繋いだ構造をしている論理式を*CNF*という。
`Clause` の配列として表現する。
`num_vars` は変数の個数（最大の ID + 1）を表す。
```rust
//| file: rust/viska-sat/src/cnf.rs
use crate::clause::Clause;
pub struct Cnf {
    pub clauses: Vec<Clause>,
    pub num_vars: usize
}
```

=== 割り当て
各変数に真偽値を対応付ける構造を*割り当て*という。
真・偽・未割り当ての3つの値を取り得るので、`Option<bool>` 型を取ることで対応する。
それの配列として割り当てを表現する。
```rust
//| file: rust/viska-sat/src/assignment.rs
pub struct Assignment {
    pub values: Vec<Option<bool>>
}
```
