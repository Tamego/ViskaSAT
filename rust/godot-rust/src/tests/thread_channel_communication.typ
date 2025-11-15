== スレッド間のチャネルの通信 <sec_thread-test>
`Solver` と `SolverRunner` 間の通信の中核をなすチャネルについてテストしてみる。

スレッドとチャネルのモジュールを読み込む。
```rust
//| id: tcc_modules
use std::thread;
use std::sync::mpsc;
use std::time::Duration;
```

=== `init`

フィールドの初期化をする。
```rust
//| id: tcc_init
fn init(base: Base<Control>) -> Self {
    Self {
        event_rx: None,
        ctrl_tx: None,
        is_pause: true,
        base
    }
}
```

=== `ready`

チャネルを立ててフィールドに代入したり、その他変数を用意する。
```rust
//| id: tcc_init_vars
let (event_tx, event_rx) = mpsc::channel::<u64>();
let (ctrl_tx, ctrl_rx) = mpsc::channel::<bool>();
self.event_rx = Some(event_rx);
self.ctrl_tx = Some(ctrl_tx);

let mut is_pause = self.is_pause;
```

そして、1 秒ごとに数字をカウントアップするスレッドを立てる。

```rust
//| id: tcc_thread
thread::spawn(move || {
    for val in 0..=100 {
        <<tcc_pause-handle>>
        event_tx.send(val).unwrap();
        thread::sleep(Duration::from_secs(1));
    }
});
```

ただし、一時停止のメッセージを受け取ったら再開のメッセージを受け取るまで停止する。
```rust
//| id: tcc_pause-handle
while let Ok(received) = ctrl_rx.try_recv() {
    is_pause = received;
}
while is_pause {
    let mut pause_flag = ctrl_rx.recv().unwrap();
    while let Ok(received) = ctrl_rx.try_recv() {
        pause_flag = received;
    }
    is_pause = pause_flag;
}
```

```rust
//| id: tcc_ready
fn ready(&mut self) {
    <<tcc_init_vars>>
    <<tcc_thread>>
}
```

=== `process`

そもそもチャネルが作られているか確認する。
```rust
//| id: tcc_check-channel
let (event_rx, ctrl_tx) = match (&self.event_rx, &self.ctrl_tx) {
    (Some(rx), Some(tx)) => (rx, tx),
    _ => return,
};
```

もしデータがあるなら受け取る。
```rust
//| id: tcc_receive
if let Ok(received) = event_rx.try_recv() {
    godot_print!("{}", received);
}
```

決定ボタンが押されたらカウントアップの一時停止・再開をする。
```rust
//| id: tcc_pause-stop
let input = Input::singleton();
if input.is_action_just_pressed("ui_accept") {
    self.is_pause = !self.is_pause;
    godot_print!("is_pause: {}", self.is_pause);
    ctrl_tx.send(self.is_pause).unwrap();
}
```

```rust
//| id: tcc_process
fn process(&mut self, _delta: f64) {
    <<tcc_check-channel>>
    <<tcc_receive>>
    <<tcc_pause-stop>>
}
```

```rust
//| file: rust/godot-rust/src/tests/thread_channel_communication.rs
use godot::prelude::*;
use godot::classes::{Control, IControl, Input};
<<tcc_modules>>

#[derive(GodotClass)]
#[class(base=Control)]
struct ThreadChannelCommunication {
    event_rx: Option<mpsc::Receiver<u64>>,
    ctrl_tx: Option<mpsc::Sender<bool>>,
    is_pause: bool,
    base: Base<Control>
}

#[godot_api]
impl IControl for ThreadChannelCommunication {
    <<tcc_init>>
    <<tcc_ready>>
    <<tcc_process>>
}
```
