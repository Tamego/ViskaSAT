// ~/~ begin <<rust/viska-sat/src/basic_types.typ#rust/viska-sat/src/cnf.rs>>[init]
//| file: rust/viska-sat/src/cnf.rs
use crate::{assignment::Assignment, clause::{Clause, ClauseState}};

#[derive(Debug, Clone)]
pub struct Cnf {
    pub clauses: Vec<Clause>,
    pub num_vars: usize
}

#[derive(Debug, Clone)]
pub enum CnfState {
      Satisfied,
      Unsatisfied,
      Unresolved,
}

impl Cnf {
    pub fn eval(&self, assign: &Assignment) -> CnfState {
        let mut all_satisfied = true;
        for clause in &self.clauses {
            match clause.eval(assign) {
                ClauseState::Unresolved => all_satisfied = false,
                ClauseState::Unsatisfied => return CnfState::Unsatisfied,
                _ => {}
            }
        }
        if all_satisfied {
            CnfState::Satisfied
        } else {
            CnfState::Unresolved
        }
    }
}
// ~/~ end
