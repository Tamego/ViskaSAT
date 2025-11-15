// ~/~ begin <<rust/viska-sat/src/solver_runner.typ#rust/viska-sat/src/solver_runner.rs>>[init]
//| file: rust/viska-sat/src/solver_runner.rs
// ~/~ begin <<rust/viska-sat/src/solver_runner.typ#sor_modules>>[init]
//| id: sor_modules
use crate::{event_handler::EventHandler, solver::{SatResult, Solver}, solver_communicator::{SolverCommunicator, SolverCommunicatorError, SolverControl}};
use std::sync::mpsc::{channel, Sender, Receiver, TryRecvError};
use std::thread;
use std::fmt::Debug;
// ~/~ end
// ~/~ begin <<rust/viska-sat/src/solver_runner.typ#sor_solver-runner-event-handler>>[init]
//| id: sor_solver-runner-event-handler
pub struct SolverRunnerEventHandler<Event> {
    com: SolverCommunicator<Event>,
}

// ~/~ begin <<rust/viska-sat/src/solver_runner.typ#soreh_impl>>[init]
//| id: soreh_impl
impl<Event> EventHandler for SolverRunnerEventHandler<Event> {
    type Event = Event;
    type Error = SolverCommunicatorError;

    // ~/~ begin <<rust/viska-sat/src/solver_runner.typ#soreh_handle-event>>[init]
    //| id: soreh_handle-event
    fn handle_event(&mut self, event: Self::Event) -> Result<(), Self::Error> {
        let mut is_pause = false;
        // ~/~ begin <<rust/viska-sat/src/solver_runner.typ#soreh_get-latest-control>>[init]
        //| id: soreh_get-latest-control
        match self.com.try_recv_latest_control() {
            Ok(Some(receive)) => {
                is_pause = receive == SolverControl::Pause;
            }
            Err(err) => return Err(err),
            _ => {}
        };
        // ~/~ end
        // ~/~ begin <<rust/viska-sat/src/solver_runner.typ#soreh_pause-loop>>[init]
        //| id: soreh_pause-loop
        while is_pause {
            match self.com.recv_latest_control() {
                Ok(receive) => {
                    is_pause = receive == SolverControl::Pause;
                }
                Err(err) => return Err(err),
            }
        }
        // ~/~ end
        // ~/~ begin <<rust/viska-sat/src/solver_runner.typ#soreh_send-event>>[init]
        //| id: soreh_send-event
        if let Err(err) = self.com.send_event(event) {
            return Err(err);
        }
        // ~/~ end
        Ok(())
    }
    // ~/~ end
}
// ~/~ end
// ~/~ end
// ~/~ begin <<rust/viska-sat/src/solver_runner.typ#sor_error>>[init]
//| id: sor_error
#[derive(Debug)]
pub enum SolverRunnerError<E> {
    SendFailed,
    ReceiveFailed,
    SolverError(E),
    NotFinished,
    JoinPanicked,
    AlreadyJoined
}
// ~/~ end
// ~/~ begin <<rust/viska-sat/src/solver_runner.typ#sor_runner>>[init]
//| id: sor_runner
pub struct SolverRunner<S: Solver> {
    event_rx: Receiver<S::Event>,
    ctrl_tx: Sender<SolverControl>,
    join_handle: Option<thread::JoinHandle<Result<SatResult, S::Error>>>
}

impl<S> SolverRunner<S>
where
    S: Solver + Send,
    S::Event: Send + 'static,
    S::Error: Send + 'static
{
    // ~/~ begin <<rust/viska-sat/src/solver_runner.typ#sorr_start-solver>>[init]
    //| id: sorr_start-solver
    pub fn start_solver<F>(make_solver: F) -> Self
    where
        F: (FnOnce(SolverRunnerEventHandler<S::Event>) -> S) + Send + 'static
    {
        let (event_tx, event_rx) = channel::<S::Event>();
        let (ctrl_tx, ctrl_rx) = channel::<SolverControl>();
        let handler = SolverRunnerEventHandler {
            com: SolverCommunicator::new(event_tx, ctrl_rx),
        };
        let join_handle = thread::spawn(move || {
            make_solver(handler).solve()
        });
        Self {
            event_rx,
            ctrl_tx,
            join_handle: Some(join_handle)
        }
    }
    // ~/~ end
    // ~/~ begin <<rust/viska-sat/src/solver_runner.typ#sorr_try-recv-event>>[init]
    //| id: sorr_try-recv-event
    pub fn try_recv_event(&self) -> Result<Option<S::Event>, SolverRunnerError<S::Error>> {
        match self.event_rx.try_recv() {
            Ok(recv) => return Ok(Some(recv)),
            Err(TryRecvError::Empty) => return Ok(None),
            Err(TryRecvError::Disconnected) => return Err(SolverRunnerError::ReceiveFailed),
        };
    }
    // ~/~ end
    // ~/~ begin <<rust/viska-sat/src/solver_runner.typ#sorr_send-control>>[init]
    //| id: sorr_send-control
    pub fn send_control(&self, control: SolverControl) -> Result<(), SolverRunnerError<S::Error>> {
        if self.ctrl_tx.send(control).is_err() {
            return Err(SolverRunnerError::SendFailed);
        }
        return Ok(());
    }
    // ~/~ end
    // ~/~ begin <<rust/viska-sat/src/solver_runner.typ#sorr_try-join>>[init]
    //| id: sorr_try-join
    pub fn try_join(&mut self) -> Result<SatResult, SolverRunnerError<S::Error>> {
        let handle = match self.join_handle.as_ref() {
            Some(handle) => {
                if handle.is_finished() {
                    self.join_handle.take().unwrap()
                }
                else {
                    return Err(SolverRunnerError::NotFinished)
                }
            },
            None => return Err(SolverRunnerError::AlreadyJoined),
        };

        match handle.join() {
            Ok(Ok(ret)) => return Ok(ret),
            Ok(Err(err)) => return Err(SolverRunnerError::SolverError(err)),
            Err(_) => return Err(SolverRunnerError::JoinPanicked)
        }
    }
    // ~/~ end
}
// ~/~ end
// ~/~ end
