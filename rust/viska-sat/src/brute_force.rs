// ~/~ begin <<rust/viska-sat/src/brute_force.typ#rust/viska-sat/src/brute_force.rs>>[init]
//| file: rust/viska-sat/src/brute_force.rs
use crate::{assignment::Assignment, cnf::Cnf, event_handler::EventHandler, solver::{SatResult, Solver}};

pub enum BruteForceSolverEvent {
    Choose {idx: usize, assign: bool},
    Eval {result: bool},
    Unchoose {idx: usize},
}

pub struct BruteForceSolver<H> 
{
    cnf: Cnf,
    handler: H
}

impl<H> BruteForceSolver<H>
where
    H: EventHandler<Event = BruteForceSolverEvent>
{
    // ~/~ begin <<rust/viska-sat/src/brute_force.typ#brf_brute-force>>[init]
    //|  id: brf_brute-force
    fn brute_force(&mut self, idx: usize, assign: &mut Assignment) -> Result<SatResult, H::Error> {
        // ~/~ begin <<rust/viska-sat/src/brute_force.typ#brf_base-case>>[init]
        //|id: brf_base-case
        if assign.is_full() {
            let is_sat = self.cnf.is_satisfied_by(assign);
            self.handler.handle_event(BruteForceSolverEvent::Eval { result: is_sat })?;
            if is_sat {
                return Ok(SatResult::Sat(assign.clone()));
            }
            else {
                return Ok(SatResult::Unsat)
            }
        }
        // ~/~ end
        // ~/~ begin <<rust/viska-sat/src/brute_force.typ#brf_recursive-step>>[init]
        //| id: brf_recursive-step
        let next_idx = idx + 1;
        for choice in [true, false] {
            self.handler.handle_event(BruteForceSolverEvent::Choose { idx: next_idx, assign: choice })?;
            assign.values[next_idx] = Some(choice);
            if let SatResult::Sat(solution) = self.brute_force(next_idx, assign)? {
                return Ok(SatResult::Sat(solution));
            }
            self.handler.handle_event(BruteForceSolverEvent::Unchoose { idx: next_idx })?;
        }
        return Ok(SatResult::Unsat);
        // ~/~ end
    }
    // ~/~ end
}

impl<H> Solver for BruteForceSolver<H>
where
    H: EventHandler<Event = BruteForceSolverEvent>
{
    type Event = BruteForceSolverEvent;
    type Handler = H;
    type Error = H::Error;

    fn solve(&mut self) -> Result<SatResult, Self::Error> {
        self.brute_force(0, &mut Assignment { values: vec![None; self.cnf.num_vars]})
    }
}
// ~/~ end
