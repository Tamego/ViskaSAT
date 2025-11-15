== `Solver` トレイト <sec_solver-trait-test>
@sec_solver 節で定義した `Solver` トレイトをテストしてみる。
@sec_thread-test 節の一部を `Solver` トレイトを実装した構造体に置き換えて同様に動作することを確認する。

```rust
//| id: sot_modules
use viska_sat::{solver::{Solver, SatResult}, event_handler::EventHandler};
use std::sync::mpsc::{channel, Sender, Receiver, TryRecvError};

use std::time::Duration;
use std::thread;
```

また、適当なエラーの型を作っておく。
```rust
//| id: sot_error-type
#[derive(Debug)]
struct TestError;
```

=== `TestHandler`
イベントハンドラーを作る。
@sec_thread-test 節のそれとほぼ同じような内容にする。
```rust
//| id: sotth-decl
struct TestHandler {
    event_tx: Sender<u64>,
    ctrl_rx: Receiver<bool>,
    is_pause: bool
}
```

関連型を設定する。
`Event` は今の進捗、つまりカウントアップした数字を表せるように `u64` にした。
また、`Error` は適当に作った `TestError` にしておく。
```rust
//| id: sotth_associated-types
type Event = u64;
type Error = TestError;
```

最新の制御メッセージを取る。
```rust
//| id: sotth_try-recv-latest
loop {
    match self.ctrl_rx.try_recv() {
        Ok(received) => self.is_pause = received,
        Err(TryRecvError::Empty) => break,
        Err(TryRecvError::Disconnected) => return Err(TestError),
    }
}
```

停止中なら再開の制御メッセージが届くまで待機する。
```rust
//| id: sotth_recv-latest
while self.is_pause {
    self.is_pause = match self.ctrl_rx.recv() {
        Ok(val) => val,
        Err(_) => return Err(TestError),
    };

    <<sotth_try-recv-latest>>
}
```

イベントを送信する。
```rust
//| id: sotth_send-event
if self.event_tx.send(event).is_err() {
    return Err(TestError);
}
```

```rust
//| id: sot_test-handler
<<sotth-decl>>

impl EventHandler for TestHandler {
    <<sotth_associated-types>>

    fn handle_event(&mut self, event: Self::Event) -> Result<(), Self::Error> {
        <<sotth_try-recv-latest>>
        <<sotth_recv-latest>>
        <<sotth_send-event>>
        Ok(())
    }
}
```

=== `DummySolver`
実際にソルバとしては機能しない、ただ数字をカウントアップするだけのダミー `DummySolver` を作る。
```rust
//| id: sotds_decl
struct DummySolver<H> {
    handler: H,
}
```

関連型を設定する。
これは `TestHandler` と同じ。
```rust
//| id: sotds_associated-types
type Event = u64;
type Error = TestError;
type Handler = H;
```

ソルバの中身を定義する。
```rust
//| id: sotds_solve
fn solve(&mut self) -> Result<viska_sat::solver::SatResult, Self::Error> {
    for val in 0..=100 {
        if self.handler.handle_event(val).is_err() {
            return Err(TestError);
        }
        thread::sleep(Duration::from_secs(1));
    }
    Ok(SatResult::Unsat)
}
```

```rust
//| id: sot_dummy-solver
<<sotds_decl>>
impl<H> Solver for DummySolver<H> 
where
    H: EventHandler<Event = u64, Error = TestError>
{
    <<sotds_associated-types>>
    <<sotds_solve>>
    fn make_solver(_cnf: Cnf, handler: Self::Handler) -> Self {
        DummySolver {
            handler
        }
    }
}
```

あとはこれを動かすだけ。
重要な部分だけピックアップする。

=== `ready`
チャネルを立てて、`EventHandler` に渡す。
```rust
//| id: sotr_start-channel
let (event_tx, event_rx) = channel::<u64>();
let (ctrl_tx, ctrl_rx) = channel::<bool>();
self.event_rx = Some(event_rx);
self.ctrl_tx = Some(ctrl_tx);
let handler = TestHandler {
    event_tx,
    ctrl_rx,
    is_pause: self.is_pause,
};
```

`DummySolver` を作って解き始める。
```rust
//| id: sotr_start-solving
let mut solver = DummySolver {
    handler
};
thread::spawn(move || {
    solver.solve().unwrap();
});
```

```rust
//| id: sot_ready
fn ready(&mut self) {
    <<sotr_start-channel>>
    <<sotr_start-solving>>
}
```

=== `process`
`process` は@sec_thread-test 節の実装をそのまま使用する。

```rust
//| file: rust/godot-rust/src/tests/solver_trait.rs
use godot::prelude::*;
use godot::classes::{Control, IControl, Input};
use viska_sat::cnf::Cnf;
<<sot_modules>>
<<sot_error-type>>
<<sot_test-handler>>
<<sot_dummy-solver>>


#[derive(GodotClass)]
#[class(base=Control)]
struct SolverTrait {
    event_rx: Option<Receiver<u64>>,
    ctrl_tx: Option<Sender<bool>>,
    is_pause: bool,
    base: Base<Control>
}

#[godot_api]
impl IControl for SolverTrait {
    fn init(base: Base<Control>) -> Self {
        Self {
            event_rx: None,
            ctrl_tx: None,
            is_pause: true,
            base
        }
    }

    <<sot_ready>>
    <<tcc_process>>
}
```
