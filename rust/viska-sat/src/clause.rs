// ~/~ begin <<rust/viska-sat/src/basic_types.typ#rust/viska-sat/src/clause.rs>>[init]
//| file: rust/viska-sat/src/clause.rs
use crate::lit::Lit;
pub struct Clause<Meta=()> {
    pub lits: Vec<Lit>,
    pub meta: Meta,
}
// ~/~ end
