== `Solver` と `SolverRunner` 間の通信
`Solver` と `SolverRunner` 間の通信のために `SolverCommunicator` を定める。
これは以下の関数を持つ：
/ `new()`: `event_tx` と `ctrl_rx` を引数にとるコンストラクタ。
/ `send_event()`: `SolverRunner` にソルバのイベントを伝える。
/ `try_recv_latest_control()`: `SolverRunner` からの*最新の制御のみ*を受けとる。スレッドをブロックしない。
/ `recv_latest_control()`: `SolverRunner` からの*最新の制御のみ*（`SolverControl`）を受けとる。スレッドをブロックする。

`SolverControl` は全ソルバに共通するので、ここで列挙型で定義する。
停止と再開のみを想定しているが、今後増やすかもしれない。
```rust
//| id: sol_solver-control
#[derive(PartialEq, Eq)]
pub enum SolverControl {
    Pause,
    Resume
}
```

また、`SolverCommunicator` に関連するエラーハンドリングのための列挙型を作る。
```rust
//| id: sol_solver-communicator-error
#[derive(Debug)]
pub enum SolverCommunicatorError {
    SendFailed,
    ReceiveFailed,
}
```

イベントの種類はソルバ依存なので、ジェネリクスにして処理する。
通信には `mpsc` を使う。
`event_tx` はイベントを `SolverRunner` に知らせ、
`ctrl_rx` で `SolverRunner` からの制御を受け取る。
```rust
//| id: sol_solver-communicator-decl
pub struct SolverCommunicator<Event> {
    event_tx: Sender<Event>,
    ctrl_rx: Receiver<SolverControl>,
}
```

前述の通りに実装をしていく。
```rust
//| id: sol_solver-communicator-impl
impl<Event> SolverCommunicator<Event> {
    <<solsc_constructor>>
    <<solsc_send-event>>
    <<solsc_try-recv-latest-control>>
    <<solsc_recv-latest-control>>
}
```

```rust
//| id: solsc_constructor
pub fn new(event_tx: Sender<Event>, ctrl_rx: Receiver<SolverControl>) -> Self {
    Self { event_tx, ctrl_rx }
}
```

イベントを送信する。
```rust
//| id: solsc_send-event
pub fn send_event(&mut self, event: Event) -> Result<(), SolverCommunicatorError> {
    if self.event_tx.send(event).is_err() {
        return Err(SolverCommunicatorError::SendFailed);
    }
    Ok(())
}
```

最新の制御メッセージを受け取る。
ここではブロックしない `try_recv()` を使う。
キューが空になるまで最新のメッセージを読むということをやっている。
```rust
//| id: solsc_try-recv-latest-control
pub fn try_recv_latest_control(&mut self) -> Result<Option<SolverControl>, SolverCommunicatorError> {
    let mut recv = None;
    loop {
        match self.ctrl_rx.try_recv() {
            Ok(received) => recv = Some(received),
            Err(TryRecvError::Empty) => break Ok(recv),
            Err(TryRecvError::Disconnected) => return Err(SolverCommunicatorError::ReceiveFailed),
        }
    }
}
```

今度は `try_recv_latest_control()` のブロックする版 `recv_latest_control()` を定義する。
最初の一件だけ `recv()` でブロックして、それに続くメッセージは `try_recv()` で空になるまで見る。
後者については `try_recv_latest_control()` そのものなので再利用する。
```rust
//| id: solsc_recv-latest-control
pub fn recv_latest_control(&mut self) -> Result<SolverControl, SolverCommunicatorError> {
    let mut recv= match self.ctrl_rx.recv() {
        Ok(val) => val,
        Err(_) => return Err(SolverCommunicatorError::ReceiveFailed),
    };
    match self.try_recv_latest_control() {
        Ok(Some(received)) => {
            recv = received;
        },
        Err(_) => return Err(SolverCommunicatorError::ReceiveFailed),
        _ => {}
    }
    Ok(recv)
}
```

```rust
//| file: rust/viska-sat/src/solver_communicator.rs
use std::sync::mpsc::{Sender, Receiver, TryRecvError};
<<sol_solver-control>>
<<sol_solver-communicator-error>>

<<sol_solver-communicator-decl>>
<<sol_solver-communicator-impl>>
```
