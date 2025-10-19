// ~/~ begin <<rust/viska-sat/src/basic_types.typ#rust/viska-sat/src/clause.rs>>[init]
//| file: rust/viska-sat/src/clause.rs
use crate::{assignment::Assignment, lit::Lit};
pub struct Clause<Meta=()> {
    pub lits: Vec<Lit>,
    pub meta: Meta,
}

impl Clause {
    pub fn is_satisfied_by(&self, assign: &Assignment) -> bool {
        for lit in &self.lits {
            if lit.is_satisfied_by(assign) {
                return true;
            }
        }
        return false;
    }
}
// ~/~ end
