// ~/~ begin <<rust/viska-sat/src/solver.typ#rust/viska-sat/src/solver.rs>>[init]
//| file: rust/viska-sat/src/solver.rs
use crate::{assignment::Assignment, cnf::Cnf, event_handler::EventHandler};
// ~/~ begin <<rust/viska-sat/src/solver.typ#sol_solver-result>>[init]
//| id: sol_solver-result
#[derive(Debug, Clone)]
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
    type Handler: EventHandler<Event = Self::Event, Error = Self::Error>;

    fn solve(&mut self) -> Result<SatResult, Self::Error>;

    fn make_solver(cnf: Cnf, handler: Self::Handler) -> Self;
}
// ~/~ end
// ~/~ end
