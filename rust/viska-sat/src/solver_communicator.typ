== `Solver` と `SolverRunner` 間の通信
`Solver` と `SolverRunner` 間の通信のために `SolverCommunicator` トレイトを定める。
これは以下の関数を持つ：
/ `SolverCommunicator::send_event()`: `SolverRunner` にソルバのイベントを伝える。
/ `SolverCommunicator::recv_latest_control()`: `SolverRunner` からの*最新の制御のみ*（`SolverControl`）を受けとる。スレッドをブロックする。
/ `SolverCommunicator::try_recv_latest_control()`: `SolverRunner` からの*最新の制御のみ*を受けとる。スレッドをブロックしない。

`SolverControl` は全ソルバに共通するので、ここで列挙型で定義する。
停止と再開のみを想定しているが、今後増やすかもしれない。
```rust
//| id: sol_solver-control
pub enum SolverControl {
    Pause,
    Resume
}
```

また、`SolverCommunicator` に関連するエラーハンドリングのための列挙型を作る。
```rust
//| id: sol_solver-communicator-error
pub enum SolverCommunicatorError {
    SendFailed,
    ReceiveFailed,
}
```

イベントの種類はソルバ依存なので、`Solver` トレイトと同様に、
`Event` と関連型にして各ソルバが自由に決められるようにした。
```rust
//| id: sol_solver-communicator
pub trait SolverCommunicator {
    type Event;

    fn send_event(&mut self, event: Self::Event) -> Result<(), SolverCommunicatorError>;
    fn recv_latest_control(&mut self) -> Result<SolverControl, SolverCommunicatorError>;
    fn try_recv_latest_control(&mut self) -> Result<Option<SolverControl>, SolverCommunicatorError>;
}
```

```rust
//| file: rust/viska-sat/src/solver_communicator.rs
<<sol_solver-control>>
<<sol_solver-communicator-error>>
<<sol_solver-communicator>>
```
