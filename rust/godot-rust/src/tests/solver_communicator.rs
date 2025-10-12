// ~/~ begin <<rust/godot-rust/src/tests/solver_communicator.typ#rust/godot-rust/src/tests/solver_communicator.rs>>[init]
//| file: rust/godot-rust/src/tests/solver_communicator.rs
use godot::prelude::*;
use godot::classes::{Control, IControl};
// ~/~ begin <<rust/godot-rust/src/tests/solver_communicator.typ#soc_modules>>[init]
//| id: soc_modules
use viska_sat::{solver::{Solver, SatResult}, event_handler::EventHandler, solver_communicator::{SolverCommunicator, SolverControl, SolverCommunicatorError}};
use std::sync::mpsc::{channel, Sender, Receiver};

use std::time::Duration;
use std::thread;
// ~/~ end
// ~/~ begin <<rust/godot-rust/src/tests/solver_communicator.typ#soc_test-handler>>[init]
//| id: soc_test-handler
// ~/~ begin <<rust/godot-rust/src/tests/solver_communicator.typ#socth-decl>>[init]
//| id: socth-decl
struct TestHandler {
    com: SolverCommunicator<u64>,
    is_pause: bool
}
// ~/~ end

impl EventHandler for TestHandler {
    type Event = u64;
    type Error = SolverCommunicatorError;

    fn handle_event(&mut self, event: Self::Event) -> Result<(), Self::Error> {
        // ~/~ begin <<rust/godot-rust/src/tests/solver_communicator.typ#socth_try-recv-latest>>[init]
        //| id: socth_try-recv-latest
        match self.com.try_recv_latest_control() {
            Ok(Some(receive)) => {
                self.is_pause = receive == SolverControl::Pause;
            }
            Err(err) => return Err(err),
            _ => {}
        };
        // ~/~ end
        // ~/~ begin <<rust/godot-rust/src/tests/solver_communicator.typ#socth_pause-loop>>[init]
        //| id: socth_pause-loop
        while self.is_pause {
            match self.com.recv_latest_control() {
                Ok(receive) => {
                    self.is_pause = receive == SolverControl::Pause;
                }
                Err(err) => return Err(err),
            }
        }
        // ~/~ end
        // ~/~ begin <<rust/godot-rust/src/tests/solver_communicator.typ#socth_send-event>>[init]
        //| id: socth_send-event
        if let Err(err) = self.com.send_event(event) {
            return Err(err);
        }
        // ~/~ end
        Ok(())
    }
}
// ~/~ end
// ~/~ begin <<rust/godot-rust/src/tests/solver_communicator.typ#soc_dummy-solver>>[init]
//| id: soc_dummy-solver
// ~/~ begin <<rust/godot-rust/src/tests/solver_trait.typ#sotds_decl>>[init]
//| id: sotds_decl
struct DummySolver<H> {
    handler: H,
}
// ~/~ end
impl<H> Solver for DummySolver<H>
where
    H: EventHandler<Error = SolverCommunicatorError, Event = u64>
{
    // ~/~ begin <<rust/godot-rust/src/tests/solver_communicator.typ#socds_associated-types>>[init]
    //| id: socds_associated-types
    type Event = u64;
    type Error = SolverCommunicatorError;
    type Handler = H;
    // ~/~ end
    // ~/~ begin <<rust/godot-rust/src/tests/solver_communicator.typ#socds_solve>>[init]
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
    // ~/~ end
}
// ~/~ end


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

    // ~/~ begin <<rust/godot-rust/src/tests/solver_communicator.typ#soc_ready>>[init]
    //| id: soc_ready
    fn ready(&mut self) {
        // ~/~ begin <<rust/godot-rust/src/tests/solver_communicator.typ#socr_start-channel>>[init]
        //| id: socr_start-channel
        let (event_tx, event_rx) = channel::<u64>();
        let (ctrl_tx, ctrl_rx) = channel::<SolverControl>();
        self.event_rx = Some(event_rx);
        self.ctrl_tx = Some(ctrl_tx);
        let handler = TestHandler {
            com: SolverCommunicator::new(event_tx, ctrl_rx),
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
    // ~/~ begin <<rust/godot-rust/src/tests/solver_communicator.typ#soc_process>>[init]
    //| id: soc_process
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
        // ~/~ begin <<rust/godot-rust/src/tests/solver_communicator.typ#soc_pause-stop>>[init]
        //| id: soc_pause-stop
        let input = Input::singleton();
        if input.is_action_just_pressed("ui_accept") {
            self.is_pause = !self.is_pause;
            godot_print!("is_pause: {}", self.is_pause);
            ctrl_tx.send(if self.is_pause {SolverControl::Pause} else {SolverControl::Resume} ).unwrap();
        }
        // ~/~ end
    }
    // ~/~ end
}
// ~/~ end
