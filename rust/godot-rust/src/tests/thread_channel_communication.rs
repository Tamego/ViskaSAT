// ~/~ begin <<rust/godot-rust/src/tests/thread_channel_communication.typ#rust/godot-rust/src/tests/thread_channel_communication.rs>>[init]
//| file: rust/godot-rust/src/tests/thread_channel_communication.rs
use godot::prelude::*;
use godot::classes::{Control, IControl};
// ~/~ begin <<rust/godot-rust/src/tests/thread_channel_communication.typ#tcc_modules>>[init]
//| id: tcc_modules
use std::thread;
use std::sync::mpsc;
use std::time::Duration;
// ~/~ end

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
    // ~/~ begin <<rust/godot-rust/src/tests/thread_channel_communication.typ#tcc_init>>[init]
    //| id: tcc_init
    fn init(base: Base<Control>) -> Self {
        // ~/~ begin <<rust/godot-rust/src/tests/thread_channel_communication.typ#tcc_channel>>[init]
        //| id: tcc_channel
        let (num_tx, num_rx) = mpsc::channel();
        let (ctrl_tx, ctrl_rx) = mpsc::channel::<bool>();
        // ~/~ end
        // ~/~ begin <<rust/godot-rust/src/tests/thread_channel_communication.typ#tcc_thread>>[init]
        //| id: tcc_thread
        thread::spawn(move || {
            let mut is_pause = false;
            for val in 0..=100 {
                // ~/~ begin <<rust/godot-rust/src/tests/thread_channel_communication.typ#tcc_pause-handle>>[init]
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
                // ~/~ end
                num_tx.send(val).unwrap();
                thread::sleep(Duration::from_secs(1));
            }
        });
        // ~/~ end
        Self {
            num_rx,
            ctrl_tx,
            is_pause: false,
            base
        }
    }
    // ~/~ end
    // ~/~ begin <<rust/godot-rust/src/tests/thread_channel_communication.typ#tcc_process>>[init]
    //| id: tcc_process
    fn process(&mut self, _delta: f64) {
        // ~/~ begin <<rust/godot-rust/src/tests/thread_channel_communication.typ#tcc_receive>>[init]
        //| id: tcc_receive
        if let Ok(received) = self.num_rx.try_recv() {
            godot_print!("{}", received);
        }
        // ~/~ end
        // ~/~ begin <<rust/godot-rust/src/tests/thread_channel_communication.typ#tcc_pause-stop>>[init]
        //| id: tcc_pause-stop
        let input = Input::singleton();
        if input.is_action_just_pressed("ui_accept") {
            self.is_pause = !self.is_pause;
            godot_print!("is_pause: {}", self.is_pause);
            self.ctrl_tx.send(self.is_pause).unwrap();
        }
        // ~/~ end
    }
    // ~/~ end
}
// ~/~ end
