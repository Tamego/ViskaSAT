// ~/~ begin <<rust/godot-rust/src/tests/solver_runner.typ#rust/godot-rust/src/tests/solver_runner.rs>>[init]
//| file: rust/godot-rust/src/tests/solver_runner.rs
use godot::prelude::*;
use godot::classes::{Control, IControl, Input};
use viska_sat::cnf::Cnf;
// ~/~ begin <<rust/godot-rust/src/tests/solver_runner.typ#sort_modules>>[init]
//| id: sort_modules
use viska_sat::{solver::{Solver, SatResult}, event_handler::EventHandler, solver_communicator::{SolverControl, SolverCommunicatorError}, solver_runner::{SolverRunner, SolverRunnerEventHandler}};

use std::time::Duration;
use std::thread;
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
    fn make_solver(_cnf: Cnf, handler: Self::Handler) -> Self {
        DummySolver {
            handler
        }
    }
}
// ~/~ end

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

    // ~/~ begin <<rust/godot-rust/src/tests/solver_runner.typ#sort_ready>>[init]
    //| id: sort_ready
    fn ready(&mut self) {
        self.runner = Some(SolverRunner::start_solver(|handler| DummySolver{handler}));
    }
    // ~/~ end
    // ~/~ begin <<rust/godot-rust/src/tests/solver_runner.typ#sort_process>>[init]
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
    // ~/~ end
}
// ~/~ end
