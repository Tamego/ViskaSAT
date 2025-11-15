== `SolverRunner`
例によって同じ内容を `SolverRunner` を使って書き換えてテストする。

モジュールを調整。
```rust
//| id: sort_modules
use viska_sat::{solver::{Solver, SatResult}, event_handler::EventHandler, solver_communicator::{SolverControl, SolverCommunicatorError}, solver_runner::{SolverRunner, SolverRunnerEventHandler}};

use std::time::Duration;
use std::thread;
```

```rust
//| id: sort_ready
fn ready(&mut self) {
    self.runner = Some(SolverRunner::start_solver(|handler| DummySolver{handler}));
}
```

```rust
//| id: sort_process
fn process(&mut self, _delta: f64) {
    let runner = match &self.runner {
        Some(r) => r,
        None => return
    };
    if let Ok(Some(received)) = runner.try_recv_event() {
        godot_print!("{}", received);
    }

    let input = Input::singleton();
    if input.is_action_just_pressed("ui_accept") {
        self.is_pause = !self.is_pause;
        godot_print!("is_pause: {}", self.is_pause);
        let con = if self.is_pause {SolverControl::Pause} else {SolverControl::Resume};
        runner.send_control(con).unwrap();
    }
}
```

```rust
//| file: rust/godot-rust/src/tests/solver_runner.rs
use godot::prelude::*;
use godot::classes::{Control, IControl, Input};
use viska_sat::cnf::Cnf;
<<sort_modules>>
<<soc_dummy-solver>>

type Runner = SolverRunner<DummySolver<SolverRunnerEventHandler<u64>>>;

#[derive(GodotClass)]
#[class(base=Control)]
struct SolverRunnerTest {
    runner: Option<Runner>,
    is_pause: bool,
    base: Base<Control>
}

#[godot_api]
impl IControl for SolverRunnerTest {
    fn init(base: Base<Control>) -> Self {
        Self {
            runner: None,
            is_pause: false,
            base
        }
    }

    <<sort_ready>>
    <<sort_process>>
}
```
