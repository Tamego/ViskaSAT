== 基本設計
SAT ソルバのアルゴリズム部分だけを取り出してライブラリとして使えるようにする。

/ `Solver`: 様々なアルゴリズムのソルバの共通のインターフェース。
  このトレイトを持つものはロジックだけに集中し、Godot については何も触らない。
/ `SolverRunner`: `Solver` とGodotの橋渡し的役割をする。
  `Solver` を別スレッドで走らせ、ソルバの進捗を得たりソルバを制御したりと双方向のやりとりを可能にする。

可読性のためにソースを分割して記述する。

```rust
//| file: rust/viska-sat/src/lib.rs
mod lit;
mod clause;
mod cnf;
mod solver;
```
