// ~/~ begin <<rust/viska-sat/src/dpll.typ#rust/viska-sat/src/dpll.rs>>[init]
//| file: rust/viska-sat/src/dpll.rs
use crate::{assignment::Assignment, cnf::Cnf, event_handler::EventHandler, solver::{SatResult, Solver}};

#[derive(Debug)]
pub enum DpllSolverEvent {
    Decide {idx: usize, assign: bool},
    Propagated {idx: usize, assign: bool, reason: usize},
    Eval {result: bool},
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

    // ~/~ begin <<rust/viska-sat/src/dpll.typ#dpll_dpll>>[init]
    //| id: dpll_dpll
    fn dpll(&mut self, assign: &mut Assignment) -> Result<SatResult, H::Error> {
        // ~/~ begin <<rust/viska-sat/src/dpll.typ#dpll_unit-propagation>>[init]
        //| id: dpll_unit-propagation
        let mut propagated_vars = vec![];
        let mut unit_clauses = self.cnf.collect_unit_clauses(assign);
        while let Some(unit_clause) = unit_clauses.pop() {
            let propagated_lit = unit_clause.lit;
            let propagated_var_id = propagated_lit.var_id;
            let val = !propagated_lit.negated;
            assign.values[propagated_var_id] = Some(val);
            self.handler.handle_event(DpllSolverEvent::Propagated { idx: propagated_var_id, assign: val, reason: unit_clause.clause_id })?;
            propagated_vars.push(propagated_var_id);
        }
        // ~/~ end
        // ~/~ begin <<rust/viska-sat/src/dpll.typ#dpll_eval-with-assignment>>[init]
        //| id: dpll_eval-with-assignment
        if assign.is_full() {
            let is_sat = self.cnf.is_satisfied_by(assign);
            self.handler.handle_event(DpllSolverEvent::Eval { result: is_sat })?;
            if is_sat {
                return Ok(SatResult::Sat(assign.clone()));
            }
            else {
                return Ok(SatResult::Unsat)
            }
        }
        // ~/~ end
        // ~/~ begin <<rust/viska-sat/src/dpll.typ#dpll_decide>>[init]
        //| id: dpll_decide
        let mut ret = SatResult::Unsat;
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
        while let Some(var_id) = propagated_vars.pop() {
            assign.values[var_id] = None;
        }
        assign.values[idx] = None;
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
