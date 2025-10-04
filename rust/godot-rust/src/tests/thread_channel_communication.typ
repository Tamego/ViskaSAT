== スレッド間のチャネルの通信
`Solver` と `SolverRunner` 間の通信の中核をなすチャネルについてテストしてみる。

スレッドとチャネルのモジュールを読み込む。
```rust
//| id: tcc_modules
use std::thread;
use std::sync::mpsc;
use std::time::Duration;
```

チャネルを立てる。
```rust
//| id: tcc_channel
let (num_tx, num_rx) = mpsc::channel();
let (ctrl_tx, ctrl_rx) = mpsc::channel::<bool>();
```

そして、1 秒ごとに数字をカウントアップするスレッドを立てる。

```rust
//| id: tcc_thread
thread::spawn(move || {
    let mut is_pause = false;
    for val in 0..=100 {
        <<tcc_pause-handle>>
        num_tx.send(val).unwrap();
        thread::sleep(Duration::from_secs(1));
    }
});
```

ただし、一時停止のメッセージを受け取ったら再開のメッセージを受け取るまで停止する。
```rust
//| id: tcc_pause-handle
if let Ok(received) = ctrl_rx.try_recv() {
    is_pause = received;
}
if is_pause {
    loop {
        let pause_flag = ctrl_rx.recv().unwrap();
        if !pause_flag {
            is_pause = pause_flag;
            break;
        }
    }
}
```

```rust
//| id: tcc_init
fn init(base: Base<Control>) -> Self {
    <<tcc_channel>>
    <<tcc_thread>>
    Self {
        num_rx,
        ctrl_tx,
        is_pause: false,
        base
    }
}
```

もしデータがあるなら受け取る。
```rust
//| id: tcc_receive
if let Ok(received) = self.num_rx.try_recv() {
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
    self.ctrl_tx.send(self.is_pause).unwrap();
}
```

```rust
//| id: tcc_process
fn process(&mut self, _delta: f64) {
    <<tcc_receive>>
    <<tcc_pause-stop>>
}
```

```rust
//| file: rust/godot-rust/src/tests/thread_channel_communication.rs
use godot::prelude::*;
use godot::classes::{Control, IControl};
<<tcc_modules>>

#[derive(GodotClass)]
#[class(base=Control)]
struct ThreadChannelCommunicatoin {
    num_rx: mpsc::Receiver<u64>,
    ctrl_tx: mpsc::Sender<bool>,
    is_pause: bool,
    base: Base<Control>
}

#[godot_api]
impl IControl for ThreadChannelCommunicatoin {
    <<tcc_init>>
    <<tcc_process>>
}
```
