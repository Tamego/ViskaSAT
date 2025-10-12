== `SolverRunner`
別スレッドでソルバを動かし、その進捗をチャネルを通して受けとる。

必要なものを読み込む。
```rust
//| id: sor_modules
use crate::{event_handler::EventHandler, solver::{SatResult, Solver}, solver_communicator::{SolverCommunicator, SolverCommunicatorError, SolverControl}};
use std::sync::mpsc::{channel, Sender, Receiver, TryRecvError};
use std::thread;
use std::fmt::Debug;
```

=== イベントハンドラ
まずは、専用のイベントハンドラを定義する。
コミュニケータを持ち、ソルバとランナー間のやり取りを実現できるようにする。
ソルバによってイベントの型が異なるので、それはジェネリック型で表現する。

```rust
//| id: sor_solver-runner-event-handler
pub struct SolverRunnerEventHandler<Event> {
    com: SolverCommunicator<Event>,
}

<<soreh_impl>>
```

`handle_event()` を実装する。
ここで、関連型について、`Error` は今回使うコミュニケータのエラー型 `CommunicatorError` を使う。

```rust
//| id: soreh_impl
impl<Event> EventHandler for SolverRunnerEventHandler<Event> {
    type Event = Event;
    type Error = SolverCommunicatorError;

    <<soreh_handle-event>>
}
```

以下の様な流れで処理する。
1. もし制御が届いていたら、最新のものに基づいて、`is_pause` を設定する。
2. `is_pause` が真である限りループさせる。これによってソルバ自体をブロックする。
  - 新しく制御が届いていたら、それに基づいて `is_pause` を設定する。
3. イベントを送信する。
```rust
//| id: soreh_handle-event
fn handle_event(&mut self, event: Self::Event) -> Result<(), Self::Error> {
    let mut is_pause = false;
    <<soreh_get-latest-control>>
    <<soreh_pause-loop>>
    <<soreh_send-event>>
    Ok(())
}
```

最新の制御が届いていたら、それに基づいて `is_pause` を設定する。
現時点では `SolverControl` は `Pause` か `Resume` しかないので、
`Pause` であるかどうかで判断している。
ここでは非ブロッキング版の `try_recv_latest_control` を使っている。
```rust
//| id: soreh_get-latest-control
match self.com.try_recv_latest_control() {
    Ok(Some(receive)) => {
        is_pause = receive == SolverControl::Pause;
    }
    Err(err) => return Err(err),
    _ => {}
};
```

`SolverControl::Resume` が届くまでずっとループする。
ただ、`is_pause` を前述のように設定する方法でも同じことができるので、そのように実装した。
ここではブロッキング版の `recv_latest_control` を使っている。
```rust
//| id: soreh_pause-loop
while is_pause {
    match self.com.recv_latest_control() {
        Ok(receive) => {
            is_pause = receive == SolverControl::Pause;
        }
        Err(err) => return Err(err),
    }
}
```

イベントを送信する。
```rust
//| id: soreh_send-event
if let Err(err) = self.com.send_event(event) {
    return Err(err);
}
```

=== ランナー
スレッドを立てて、そこでソルバを実行する。
/ `start_solver()`: ソルバを別スレッドで走らせ、ランナー自体を返す。
/ `try_recv_event()`: ソルバからイベントをノンブロッキングで受け取る。
/ `send_control()`: 制御をソルバに伝える。
/ `try_join()`: スレッドが終了しているかを確認し、もし終了しているならそのスレッドの返り値を返す。

```rust
//| id: sor_runner
pub struct SolverRunner<S: Solver> {
    event_rx: Receiver<S::Event>,
    ctrl_tx: Sender<SolverControl>,
    join_handle: Option<thread::JoinHandle<Result<SatResult, S::Error>>>
}

impl<S> SolverRunner<S>
where
    S: Solver + Send,
    S::Event: Send + 'static,
    S::Error: Debug + Send + 'static
{
    <<sorr_start-solver>>
    <<sorr_try-recv-event>>
    <<sorr_send-control>>
    <<sorr_try-join>>
}
```

スレッドを立てて、そこでソルバを実行する。
クロージャを使うことで、柔軟にソルバを初期化できるようにしている。
ハンドラはこちらで用意するので、ハンドラを受けとってソルバを返すクロージャを取る。

```rust
//| id: sorr_start-solver
pub fn start_solver<F>(make_solver: F) -> Self
where
    F: (FnOnce(SolverRunnerEventHandler<S::Event>) -> S) + Send + 'static
{
    let (event_tx, event_rx) = channel::<S::Event>();
    let (ctrl_tx, ctrl_rx) = channel::<SolverControl>();
    let handler = SolverRunnerEventHandler {
        com: SolverCommunicator::new(event_tx, ctrl_rx),
    };
    let join_handle = thread::spawn(move || {
        make_solver(handler).solve()
    });
    Self {
        event_rx,
        ctrl_tx,
        join_handle: Some(join_handle)
    }
}
```

イベントの送受信に関するエラーの列挙型を用意する。
```rust
//| id: sor_error
pub enum SolverRunnerError<S: Solver> {
    SendFailed,
    ReceiveFailed,
    SolverError(S::Error),
    NotFinished,
    JoinPanicked,
    AlreadyJoined
}
```

最新のイベントを受けとる。
```rust
//| id: sorr_try-recv-event
pub fn try_recv_event(&mut self) -> Result<Option<S::Event>, SolverRunnerError<S>> {
    match self.event_rx.try_recv() {
        Ok(recv) => return Ok(Some(recv)),
        Err(TryRecvError::Empty) => return Ok(None),
        Err(TryRecvError::Disconnected) => return Err(SolverRunnerError::ReceiveFailed),
    };
}
```

イベントを送信する。
```rust
//| id: sorr_send-control
pub fn send_control(&mut self, control: SolverControl) -> Result<(), SolverRunnerError<S>> {
    if self.ctrl_tx.send(control).is_err() {
        return Err(SolverRunnerError::SendFailed);
    }
    return Ok(());
}
```

```rust
//| id: sorr_try-join
pub fn try_join(&mut self) -> Result<SatResult, SolverRunnerError<S>> {
    let handle = match self.join_handle.as_ref() {
        Some(handle) => {
            if handle.is_finished() {
                self.join_handle.take().unwrap()
            }
            else {
                return Err(SolverRunnerError::NotFinished)
            }
        },
        None => return Err(SolverRunnerError::AlreadyJoined),
    };

    match handle.join() {
        Ok(Ok(ret)) => return Ok(ret),
        Ok(Err(err)) => return Err(SolverRunnerError::SolverError(err)),
        Err(_) => return Err(SolverRunnerError::JoinPanicked)
    }
}
```

```rust
//| file: rust/viska-sat/src/solver_runner.rs
<<sor_modules>>
<<sor_solver-runner-event-handler>>
<<sor_error>>
<<sor_runner>>
```
