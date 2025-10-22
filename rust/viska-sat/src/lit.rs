// ~/~ begin <<rust/viska-sat/src/basic_types.typ#rust/viska-sat/src/lit.rs>>[init]
//| file: rust/viska-sat/src/lit.rs
use crate::assignment::Assignment;

#[derive(Debug, Clone)]
pub struct Lit {
    pub var_id: usize,
    pub negated: bool
}

pub enum LitState {
    Satisfied,
    Unsatisfied,
    Unassigned
}

impl Lit {
    pub fn eval(&self, assign: &Assignment) -> LitState {
        match assign.values[self.var_id] {
            None => LitState::Unassigned,
            Some(val) => if val ^ self.negated {LitState::Satisfied} else {LitState::Unsatisfied}
        }
    }
}
// ~/~ end
