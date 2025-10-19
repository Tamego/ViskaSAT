// ~/~ begin <<rust/viska-sat/src/basic_types.typ#rust/viska-sat/src/assignment.rs>>[init]
//| file: rust/viska-sat/src/assignment.rs
#[derive(Clone)]
pub struct Assignment {
    pub values: Vec<Option<bool>>
}

impl Assignment {
    pub fn is_full(&self) -> bool {
        for val in &self.values {
            if val.is_none() {
                return false;
            }
        }
        return true;
    }
}
// ~/~ end
