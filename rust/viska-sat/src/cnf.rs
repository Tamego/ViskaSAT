// ~/~ begin <<rust/viska-sat/src/basic_types.typ#rust/viska-sat/src/cnf.rs>>[init]
//| file: rust/viska-sat/src/cnf.rs
use crate::{assignment::Assignment, clause::Clause};
pub struct Cnf {
    pub clauses: Vec<Clause>,
    pub num_vars: usize
}

impl Cnf {
    pub fn is_satisfied_by(&self, assign: &Assignment) -> bool {
        for clause in &self.clauses {
            if !clause.is_satisfied_by(assign) {
                return false;
            }
        }
        return true;
    }
}
// ~/~ end
