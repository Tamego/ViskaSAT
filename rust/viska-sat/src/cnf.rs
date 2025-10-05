// ~/~ begin <<rust/viska-sat/src/basic_types.typ#rust/viska-sat/src/cnf.rs>>[init]
//| file: rust/viska-sat/src/cnf.rs
use crate::clause::Clause;
pub struct Cnf {
    pub clauses: Vec<Clause>,
    pub num_vars: usize
}
// ~/~ end
