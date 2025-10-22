// ~/~ begin <<rust/viska-sat/src/basic_types.typ#rust/viska-sat/src/clause.rs>>[init]
//| file: rust/viska-sat/src/clause.rs
use crate::{assignment::Assignment, lit::{LitState, Lit}};
#[derive(Debug, Clone)]
pub struct Clause<Meta=()> {
    pub lits: Vec<Lit>,
    pub meta: Meta,
}

pub enum ClauseState {
    Satisfied,
    Unsatisfied,
    Unit(Lit) ,
    Unresolved
}

impl Clause {
    pub fn eval(&self, assign: &Assignment) -> ClauseState {
        let mut all_unsatisfied = true;
        let mut unit_lit = None;
        for lit in &self.lits {
            match lit.eval(assign) {
                LitState::Satisfied => return ClauseState::Satisfied,
                LitState::Unassigned => {
                    all_unsatisfied = false;
                    if unit_lit.is_some() {
                        return ClauseState::Unresolved;
                    }
                    unit_lit = Some(lit.clone());
                }
                _ => {}
            }
        }

        if all_unsatisfied {
            ClauseState::Unsatisfied
        } else if let Some(lit) = unit_lit {
            ClauseState::Unit(lit)
        } else {
            ClauseState::Unresolved
        }
    }
}
// ~/~ end
