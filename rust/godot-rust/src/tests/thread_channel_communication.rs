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
struct ThreadChannelCommunication {
    event_rx: Option<mpsc::Receiver<u64>>,
    ctrl_tx: Option<mpsc::Sender<bool>>,
    is_pause: bool,
    base: Base<Control>
}

#[godot_api]
impl IControl for ThreadChannelCommunication {
    // ~/~ begin <<rust/godot-rust/src/tests/thread_channel_communication.typ#tcc_init>>[init]
    //| id: tcc_init
    fn init(base: Base<Control>) -> Self {
        Self {
            event_rx: None,
            ctrl_tx: None,
            is_pause: true,
            base
        }
    }
    // ~/~ end
    // ~/~ begin <<rust/godot-rust/src/tests/thread_channel_communication.typ#tcc_ready>>[init]
    //| id: tcc_ready
    fn ready(&mut self) {
        // ~/~ begin <<rust/godot-rust/src/tests/thread_channel_communication.typ#tcc_init_vars>>[init]
        //| id: tcc_init_vars
        let (event_tx, event_rx) = mpsc::channel::<u64>();
        let (ctrl_tx, ctrl_rx) = mpsc::channel::<bool>();
        self.event_rx = Some(event_rx);
        self.ctrl_tx = Some(ctrl_tx);

        let mut is_pause = self.is_pause;
        // ~/~ end
        // ~/~ begin <<rust/godot-rust/src/tests/thread_channel_communication.typ#tcc_thread>>[init]
        //| id: tcc_thread
        thread::spawn(move || {
            for val in 0..=100 {
                // ~/~ begin <<rust/godot-rust/src/tests/thread_channel_communication.typ#tcc_pause-handle>>[init]
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
                // ~/~ end
                event_tx.send(val).unwrap();
                thread::sleep(Duration::from_secs(1));
            }
        });
        // ~/~ end
    }
    // ~/~ end
    // ~/~ begin <<rust/godot-rust/src/tests/thread_channel_communication.typ#tcc_process>>[init]
    //| id: tcc_process
    fn process(&mut self, _delta: f64) {
        // ~/~ begin <<rust/godot-rust/src/tests/thread_channel_communication.typ#tcc_check-channel>>[init]
        //| id: tcc_check-channel
        let (event_rx, ctrl_tx) = match (&self.event_rx, &self.ctrl_tx) {
            (Some(rx), Some(tx)) => (rx, tx),
            _ => return,
        };
        // ~/~ end
        // ~/~ begin <<rust/godot-rust/src/tests/thread_channel_communication.typ#tcc_receive>>[init]
        //| id: tcc_receive
        if let Ok(received) = event_rx.try_recv() {
            godot_print!("{}", received);
        }
        // ~/~ end
        // ~/~ begin <<rust/godot-rust/src/tests/thread_channel_communication.typ#tcc_pause-stop>>[init]
        //| id: tcc_pause-stop
        let input = Input::singleton();
        if input.is_action_just_pressed("ui_accept") {
            self.is_pause = !self.is_pause;
            godot_print!("is_pause: {}", self.is_pause);
            ctrl_tx.send(self.is_pause).unwrap();
        }
        // ~/~ end
    }
    // ~/~ end
}
// ~/~ end
