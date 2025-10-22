// ~/~ begin <<rust/viska-sat/src/brute_force.typ#rust/viska-sat/src/brute_force.rs>>[init]
//| file: rust/viska-sat/src/brute_force.rs
use crate::{assignment::Assignment, cnf::{Cnf, CnfState}, event_handler::EventHandler, solver::{SatResult, Solver}};

#[derive(Debug)]
pub enum BruteForceSolverEvent {
    Decide {idx: usize, assign: bool},
    Eval {result: CnfState},
    Backtrack {idx: usize},
    Finish {result: SatResult}
}

pub struct BruteForceSolver<H> 
{
    pub cnf: Cnf,
    pub handler: H
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
            let sat_state = self.cnf.eval(assign);
            self.handler.handle_event(BruteForceSolverEvent::Eval { result: sat_state.clone() })?;
            match sat_state {
                CnfState::Satisfied => return Ok(SatResult::Sat(assign.clone())),
                CnfState::Unsatisfied => return Ok(SatResult::Unsat),
                CnfState::Unresolved => panic!("full assignment cannot be unresolved")
            };
        }
        // ~/~ end
        // ~/~ begin <<rust/viska-sat/src/brute_force.typ#brf_recursive-step>>[init]
        //| id: brf_recursive-step
        let mut ret = SatResult::Unsat;
        for choice in [true, false] {
            self.handler.handle_event(BruteForceSolverEvent::Decide { idx, assign: choice })?;
            assign.values[idx] = Some(choice);
            let result = self.brute_force(idx + 1, assign)?;
            self.handler.handle_event(BruteForceSolverEvent::Backtrack { idx })?;
            match result {
                sat @ SatResult::Sat(_) => {
                    ret = sat;
                    break;
                }
                SatResult::Unsat => {}
            }
        }
        assign.values[idx] = None;
        return Ok(ret);
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
        let result = self.brute_force(0, &mut Assignment { values: vec![None; self.cnf.num_vars]})?;
        self.handler.handle_event(BruteForceSolverEvent::Finish { result: result.clone() })?;
        Ok(result)
    }
}
// ~/~ end
