// ~/~ begin <<rust/viska-sat/src/basic_types.typ#rust/viska-sat/src/lit.rs>>[init]
//| file: rust/viska-sat/src/lit.rs
use crate::assignment::Assignment;

#[derive(Debug, Clone)]
pub struct Lit {
    pub var_id: usize,
    pub negated: bool
}

impl Lit {
    pub fn is_satisfied_by(&self, assign: &Assignment) -> bool {
        match assign.values[self.var_id] {
            None => panic!(),
            Some(val) => val ^ self.negated
        }
    }
}
// ~/~ end
