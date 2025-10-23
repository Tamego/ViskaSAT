// ~/~ begin <<rust/viska-sat/src/dpll.typ#rust/viska-sat/src/dpll.rs>>[init]
//| file: rust/viska-sat/src/dpll.rs
use crate::{assignment::Assignment, clause::ClauseState, cnf::{Cnf, CnfState}, event_handler::EventHandler, solver::{SatResult, Solver}};

#[derive(Debug)]
pub enum DpllSolverEvent {
    Decide {idx: usize, assign: bool},
    Propagated {idx: usize, assign: bool, reason: usize},
    Eval {result: CnfState},
    Backtrack {idx: usize},
    Finish {result: SatResult}
}

pub struct DpllSolver<H> 
{
    pub cnf: Cnf,
    pub handler: H
}

impl<H> DpllSolver<H>
where
    H: EventHandler<Event = DpllSolverEvent>
{
    // ~/~ begin <<rust/viska-sat/src/dpll.typ#dpll_pick-unassigned-var>>[init]
    //| id: dpll_pick-unassigned-var
    fn pick_unassigned_var(&self, assign: &Assignment) -> Option<usize> {
        for i in 0..assign.values.len() {
            if assign.values[i].is_none() {
                return Some(i);
            }
        }
        return None;
    }
    // ~/~ end

    // ~/~ begin <<rust/viska-sat/src/dpll.typ#dpll_repeat-unit-propagation>>[init]
    //| id: dpll_repeat-unit-propagation
    fn repeat_unit_propagate(
        &mut self,
        assign: &mut Assignment,
        propagated_vars: &mut Vec<usize>
    ) -> Result<CnfState, H::Error> {
        'outer: loop {
            for (clause_id, clause) in self.cnf.clauses.iter().enumerate() {
                match clause.eval(assign) {
                    ClauseState::Unit(lit) => {
                        let idx = lit.var_id;
                        let val = !lit.negated;
                        self.handler.handle_event(
                            DpllSolverEvent::Propagated { idx, assign: val, reason: clause_id }
                        )?;
                        assign.values[idx] = Some(val);
                        propagated_vars.push(idx);
                        continue 'outer;
                    }
                    ClauseState::Unsatisfied => break 'outer,
                    _ => {}
                }
            }
            break;
        }
        Ok(self.cnf.eval(assign))
    }
    // ~/~ end

    // ~/~ begin <<rust/viska-sat/src/dpll.typ#dpll_dpll>>[init]
    //| id: dpll_dpll
    fn dpll(&mut self, assign: &mut Assignment) -> Result<SatResult, H::Error> {
        let mut ret = SatResult::Unsat;
        // ~/~ begin <<rust/viska-sat/src/dpll.typ#dpll_unit-propagation-and-conflict>>[init]
        //| id: dpll_unit-propagation-and-conflict
        let mut propagated_vars = vec![];
        if let CnfState::Unsatisfied = self.repeat_unit_propagate(assign, &mut propagated_vars)? {
            self.handler.handle_event(DpllSolverEvent::Eval { result: CnfState::Unsatisfied })?;
            ret = SatResult::Unsat;
        } 
        // ~/~ end
        // ~/~ begin <<rust/viska-sat/src/dpll.typ#dpll_eval-with-assignment>>[init]
        //| id: dpll_eval-with-assignment
        else if assign.is_full() {
            let sat_state = self.cnf.eval(assign);
            self.handler.handle_event(DpllSolverEvent::Eval { result: sat_state.clone() })?;
            match sat_state {
                CnfState::Satisfied => return Ok(SatResult::Sat(assign.clone())),
                CnfState::Unsatisfied => return Ok(SatResult::Unsat),
                CnfState::Unresolved => panic!("full assignment cannot be unresolved")
            };
        }
        // ~/~ end
        // ~/~ begin <<rust/viska-sat/src/dpll.typ#dpll_decide>>[init]
        //| id: dpll_decide
        else {
            let idx = self.pick_unassigned_var(assign).expect("branching called with fully assigned assignment");
            for choice in [true, false] {
                self.handler.handle_event(DpllSolverEvent::Decide { idx, assign: choice })?;
                assign.values[idx] = Some(choice);
                let result = self.dpll(assign)?;
                self.handler.handle_event(DpllSolverEvent::Backtrack { idx })?;
                match result {
                    sat @ SatResult::Sat(_) => {
                        ret = sat;
                        break;
                    }
                    SatResult::Unsat => {}
                }
            }
            assign.values[idx] = None;
        }
        // ~/~ end
        // ~/~ begin <<rust/viska-sat/src/dpll.typ#dpll_return>>[init]
        //| id: dpll_return
        while let Some(var_id) = propagated_vars.pop() {
            assign.values[var_id] = None;
            self.handler.handle_event(DpllSolverEvent::Backtrack { idx: var_id })?;
        }
        return Ok(ret);
        // ~/~ end
    }
    // ~/~ end
}

impl<H> Solver for DpllSolver<H>
where
    H: EventHandler<Event = DpllSolverEvent>
{
    type Event = DpllSolverEvent;
    type Handler = H;
    type Error = H::Error;

    fn solve(&mut self) -> Result<SatResult, Self::Error> {
        let result = self.dpll(&mut Assignment { values: vec![None; self.cnf.num_vars]})?;
        self.handler.handle_event(DpllSolverEvent::Finish { result: result.clone() })?;
        Ok(SatResult::Unsat)
    }
}
// ~/~ end
