// ~/~ begin <<rust/viska-sat/src/solver_communicator.typ#rust/viska-sat/src/solver_communicator.rs>>[init]
//| file: rust/viska-sat/src/solver_communicator.rs
use std::sync::mpsc::{Sender, Receiver, TryRecvError};
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

// ~/~ begin <<rust/viska-sat/src/solver_communicator.typ#sol_solver-communicator-decl>>[init]
//| id: sol_solver-communicator-decl
pub struct SolverCommunicator<Event> {
    pub event_tx: Sender<Event>,
    pub ctrl_rx: Receiver<SolverControl>,
}
// ~/~ end
// ~/~ begin <<rust/viska-sat/src/solver_communicator.typ#sol_solver-communicator-impl>>[init]
//| id: sol_solver-communicator-impl
impl<Event> SolverCommunicator<Event> {
    // ~/~ begin <<rust/viska-sat/src/solver_communicator.typ#solsc_send-event>>[init]
    //| id: solsc_send-event
    pub fn send_event(&mut self, event: Event) -> Result<(), SolverCommunicatorError> {
        if self.event_tx.send(event).is_err() {
            return Err(SolverCommunicatorError::SendFailed);
        }
        Ok(())
    }
    // ~/~ end
    // ~/~ begin <<rust/viska-sat/src/solver_communicator.typ#solsc_try-recv-latest-control>>[init]
    //| id: solsc_try-recv-latest-control
    pub fn try_recv_latest_control(&mut self) -> Result<Option<SolverControl>, SolverCommunicatorError> {
        let mut recv = None;
        loop {
            match self.ctrl_rx.try_recv() {
                Ok(received) => recv = Some(received),
                Err(TryRecvError::Empty) => break Ok(recv),
                Err(TryRecvError::Disconnected) => return Err(SolverCommunicatorError::ReceiveFailed),
            }
        }
    }
    // ~/~ end
    // ~/~ begin <<rust/viska-sat/src/solver_communicator.typ#solsc_recv-latest-control>>[init]
    //| id: solsc_recv-latest-control
    pub fn recv_latest_control(&mut self) -> Result<SolverControl, SolverCommunicatorError> {
        let mut recv= match self.ctrl_rx.recv() {
            Ok(val) => val,
            Err(_) => return Err(SolverCommunicatorError::ReceiveFailed),
        };
        if let Ok(Some(received)) = self.try_recv_latest_control() {
            recv = received;
        }
        Ok(recv)
    }
    // ~/~ end
}
// ~/~ end
// ~/~ end
