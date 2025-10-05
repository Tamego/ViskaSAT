// ~/~ begin <<rust/viska-sat/src/solver_communicator.typ#rust/viska-sat/src/solver_communicator.rs>>[init]
//| file: rust/viska-sat/src/solver_communicator.rs
// ~/~ begin <<rust/viska-sat/src/solver_communicator.typ#sol_solver-control>>[init]
//| id: sol_solver-control
pub enum SolverControl {
    Pause,
    Resume
}
// ~/~ end
// ~/~ begin <<rust/viska-sat/src/solver_communicator.typ#sol_solver-communicator-error>>[init]
//| id: sol_solver-communicator-error
pub enum SolverCommunicatorError {
    SendFailed,
    ReceiveFailed,
}
// ~/~ end
// ~/~ begin <<rust/viska-sat/src/solver_communicator.typ#sol_solver-communicator>>[init]
//| id: sol_solver-communicator
pub trait SolverCommunicator {
    type Event;

    fn send_event(&mut self, event: Self::Event) -> Result<(), SolverCommunicatorError>;
    fn recv_latest_control(&mut self) -> Result<SolverControl, SolverCommunicatorError>;
    fn try_recv_latest_control(&mut self) -> Result<Option<SolverControl>, SolverCommunicatorError>;
}
// ~/~ end
// ~/~ end
