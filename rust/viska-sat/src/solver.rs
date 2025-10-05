// ~/~ begin <<rust/viska-sat/src/solver.typ#rust/viska-sat/src/solver.rs>>[init]
//| file: rust/viska-sat/src/solver.rs
use crate::{assignment::Assignment, cnf::Cnf};
// ~/~ begin <<rust/viska-sat/src/solver.typ#sol_solver-result>>[init]
//| id: sol_solver-result
pub enum SatResult {
    Sat(Assignment),
    Unsat
}
// ~/~ end
// ~/~ begin <<rust/viska-sat/src/solver.typ#sol_solver-trait>>[init]
//| id: sol_solver-trait
pub trait Solver {
    type Event;
    type Error;

    fn initialize(&mut self, problem: Cnf);
    fn solve(&mut self) -> SatResult;
    fn emit_event(&mut self) -> Result<(), Self::Error>;
}
// ~/~ end

// ~/~ begin <<rust/viska-sat/src/solver.typ#sol_solver-control>>[init]
//| id: sol_solver-control
pub enum SolverControl {
    Pause,
    Resume
}
// ~/~ end
// ~/~ begin <<rust/viska-sat/src/solver.typ#sol_solver-communicator-error>>[init]
//| id: sol_solver-communicator-error
pub enum SolverCommunicatorError {
    SendFailed,
    ReceiveFailed,
}
// ~/~ end
// ~/~ begin <<rust/viska-sat/src/solver.typ#sol_solver-communicator>>[init]
//| id: sol_solver-communicator
pub trait SolverCommunicator {
    type Event;

    fn send_event(&mut self, event: Self::Event) -> Result<(), SolverCommunicatorError>;
    fn recv_latest_control(&mut self) -> Result<SolverControl, SolverCommunicatorError>;
    fn try_recv_latest_control(&mut self) -> Result<Option<SolverControl>, SolverCommunicatorError>;
}
// ~/~ end
// ~/~ end
