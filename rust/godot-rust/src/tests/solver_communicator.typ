== `SolverCommunicator`
`SolverCommunicator` のテストをする。
引き続き同じ内容を実装しながら一部を差し替えていく。
@sec_solver-trait-test 節のほとんどと内容が共通するので変更点だけピックアップする。

新たに `SolverCommunicator` を読み込む。
```rust
//| id: soc_modules
use viska_sat::{solver::{Solver, SatResult}, event_handler::EventHandler, solver_communicator::{SolverCommunicator, SolverControl, SolverCommunicatorError}};
use std::sync::mpsc::{channel, Sender, Receiver};

use std::time::Duration;
use std::thread;
```

=== `TestHandler`

`SolverCommunicator` を使って `TestHandler` を書き直す。
`Sender`, `Receiver` を直接持つのではなく、かわりに `SolverCommunicator` を使うようにした。
```rust
//| id: socth-decl
struct TestHandler {
    com: SolverCommunicator<u64>,
    is_pause: bool
}
```

最新の制御があれば受けとって、停止かどうかを `is_pause` に入れる。
```rust
//| id: socth_try-recv-latest
match self.com.try_recv_latest_control() {
    Ok(Some(receive)) => {
        self.is_pause = receive == SolverControl::Pause;
    }
    Err(err) => return Err(err),
    _ => {}
};
```

もし停止する必要があるなら、再開の制御を受けとるまでループする。
```rust
//| id: socth_pause-loop
while self.is_pause {
    match self.com.recv_latest_control() {
        Ok(receive) => {
            self.is_pause = receive == SolverControl::Pause;
        }
        Err(err) => return Err(err),
    }
}
```

最後にイベントを送信する。
```rust
//| id: socth_send-event
if let Err(err) = self.com.send_event(event) {
    return Err(err);
}
```

```rust
//| id: soc_test-handler
<<socth-decl>>

impl EventHandler for TestHandler {
    type Event = u64;
    type Error = SolverCommunicatorError;

    fn handle_event(&mut self, event: Self::Event) -> Result<(), Self::Error> {
        <<socth_try-recv-latest>>
        <<socth_pause-loop>>
        <<socth_send-event>>
        Ok(())
    }
}
```

=== `DummySolver`

型を現行に追従するように修正した。
```rust
//| id: socds_associated-types
type Event = u64;
type Error = SolverCommunicatorError;
type Handler = H;
```

ソルバの中身はだいたいそのまま。
```rust
//| id: socds_solve
fn solve(&mut self) -> Result<viska_sat::solver::SatResult, Self::Error> {
    for val in 0..=100 {
        if let Err(err) = self.handler.handle_event(val) {
            return Err(err);
        }
        thread::sleep(Duration::from_secs(1));
    }
    Ok(SatResult::Unsat)
}
```

```rust
//| id: soc_dummy-solver
<<sotds_decl>>
impl<H> Solver for DummySolver<H>
where
    H: EventHandler<Error = SolverCommunicatorError, Event = u64>
{
    <<socds_associated-types>>
    <<socds_solve>>
    fn make_solver(_cnf: Cnf, handler: Self::Handler) -> Self {
        DummySolver {
            handler
        }
    }
}
```

=== `ready`

フィールドと型を調整した。
```rust
//| id: socr_start-channel
let (event_tx, event_rx) = channel::<u64>();
let (ctrl_tx, ctrl_rx) = channel::<SolverControl>();
self.event_rx = Some(event_rx);
self.ctrl_tx = Some(ctrl_tx);
let handler = TestHandler {
    com: SolverCommunicator::new(event_tx, ctrl_rx),
    is_pause: self.is_pause,
};
```

```rust
//| id: soc_ready
fn ready(&mut self) {
    <<socr_start-channel>>
    <<sotr_start-solving>>
}
```

=== `process`

`SolverControl` の表現に直した。
```rust
//| id: soc_pause-stop
let input = Input::singleton();
if input.is_action_just_pressed("ui_accept") {
    self.is_pause = !self.is_pause;
    godot_print!("is_pause: {}", self.is_pause);
    ctrl_tx.send(if self.is_pause {SolverControl::Pause} else {SolverControl::Resume} ).unwrap();
}
```

```rust
//| id: soc_process
fn process(&mut self, _delta: f64) {
    <<tcc_check-channel>>
    <<tcc_receive>>
    <<soc_pause-stop>>
}
```

```rust
//| file: rust/godot-rust/src/tests/solver_communicator.rs
use godot::prelude::*;
use godot::classes::{Control, IControl, Input};
use viska_sat::cnf::Cnf;
<<soc_modules>>
<<soc_test-handler>>
<<soc_dummy-solver>>


#[derive(GodotClass)]
#[class(base=Control)]
struct SolverCommunicatorTest {
    event_rx: Option<Receiver<u64>>,
    ctrl_tx: Option<Sender<SolverControl>>,
    is_pause: bool,
    base: Base<Control>
}

#[godot_api]
impl IControl for SolverCommunicatorTest {
    fn init(base: Base<Control>) -> Self {
        Self {
            event_rx: None,
            ctrl_tx: None,
            is_pause: true,
            base
        }
    }

    <<soc_ready>>
    <<soc_process>>
}
```
