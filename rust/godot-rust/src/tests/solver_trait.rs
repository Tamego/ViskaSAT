// ~/~ begin <<rust/godot-rust/src/tests/solver_trait.typ#rust/godot-rust/src/tests/solver_trait.rs>>[init]
//| file: rust/godot-rust/src/tests/solver_trait.rs
use godot::prelude::*;
use godot::classes::{Control, IControl, Input};
use viska_sat::cnf::Cnf;
// ~/~ begin <<rust/godot-rust/src/tests/solver_trait.typ#sot_modules>>[init]
//| id: sot_modules
use viska_sat::{solver::{Solver, SatResult}, event_handler::EventHandler};
use std::sync::mpsc::{channel, Sender, Receiver, TryRecvError};

use std::time::Duration;
use std::thread;
// ~/~ end
// ~/~ begin <<rust/godot-rust/src/tests/solver_trait.typ#sot_error-type>>[init]
//| id: sot_error-type
#[derive(Debug)]
struct TestError;
// ~/~ end
// ~/~ begin <<rust/godot-rust/src/tests/solver_trait.typ#sot_test-handler>>[init]
//| id: sot_test-handler
// ~/~ begin <<rust/godot-rust/src/tests/solver_trait.typ#sotth-decl>>[init]
//| id: sotth-decl
struct TestHandler {
    event_tx: Sender<u64>,
    ctrl_rx: Receiver<bool>,
    is_pause: bool
}
// ~/~ end

impl EventHandler for TestHandler {
    // ~/~ begin <<rust/godot-rust/src/tests/solver_trait.typ#sotth_associated-types>>[init]
    //| id: sotth_associated-types
    type Event = u64;
    type Error = TestError;
    // ~/~ end

    fn handle_event(&mut self, event: Self::Event) -> Result<(), Self::Error> {
        // ~/~ begin <<rust/godot-rust/src/tests/solver_trait.typ#sotth_try-recv-latest>>[init]
        //| id: sotth_try-recv-latest
        loop {
            match self.ctrl_rx.try_recv() {
                Ok(received) => self.is_pause = received,
                Err(TryRecvError::Empty) => break,
                Err(TryRecvError::Disconnected) => return Err(TestError),
            }
        }
        // ~/~ end
        // ~/~ begin <<rust/godot-rust/src/tests/solver_trait.typ#sotth_recv-latest>>[init]
        //| id: sotth_recv-latest
        while self.is_pause {
            self.is_pause = match self.ctrl_rx.recv() {
                Ok(val) => val,
                Err(_) => return Err(TestError),
            };

            // ~/~ begin <<rust/godot-rust/src/tests/solver_trait.typ#sotth_try-recv-latest>>[init]
            //| id: sotth_try-recv-latest
            loop {
                match self.ctrl_rx.try_recv() {
                    Ok(received) => self.is_pause = received,
                    Err(TryRecvError::Empty) => break,
                    Err(TryRecvError::Disconnected) => return Err(TestError),
                }
            }
            // ~/~ end
        }
        // ~/~ end
        // ~/~ begin <<rust/godot-rust/src/tests/solver_trait.typ#sotth_send-event>>[init]
        //| id: sotth_send-event
        if self.event_tx.send(event).is_err() {
            return Err(TestError);
        }
        // ~/~ end
        Ok(())
    }
}
// ~/~ end
// ~/~ begin <<rust/godot-rust/src/tests/solver_trait.typ#sot_dummy-solver>>[init]
//| id: sot_dummy-solver
// ~/~ begin <<rust/godot-rust/src/tests/solver_trait.typ#sotds_decl>>[init]
//| id: sotds_decl
struct DummySolver<H> {
    handler: H,
}
// ~/~ end
impl<H> Solver for DummySolver<H> 
where
    H: EventHandler<Event = u64, Error = TestError>
{
    // ~/~ begin <<rust/godot-rust/src/tests/solver_trait.typ#sotds_associated-types>>[init]
    //| id: sotds_associated-types
    type Event = u64;
    type Error = TestError;
    type Handler = H;
    // ~/~ end
    // ~/~ begin <<rust/godot-rust/src/tests/solver_trait.typ#sotds_solve>>[init]
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
    // ~/~ end
    fn make_solver(_cnf: Cnf, handler: Self::Handler) -> Self {
        DummySolver {
            handler
        }
    }
}
// ~/~ end


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

    // ~/~ begin <<rust/godot-rust/src/tests/solver_trait.typ#sot_ready>>[init]
    //| id: sot_ready
    fn ready(&mut self) {
        // ~/~ begin <<rust/godot-rust/src/tests/solver_trait.typ#sotr_start-channel>>[init]
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
        // ~/~ end
        // ~/~ begin <<rust/godot-rust/src/tests/solver_trait.typ#sotr_start-solving>>[init]
        //| id: sotr_start-solving
        let mut solver = DummySolver {
            handler
        };
        thread::spawn(move || {
            solver.solve().unwrap();
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
