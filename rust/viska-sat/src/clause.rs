// ~/~ begin <<rust/viska-sat/src/basic_types.typ#rust/viska-sat/src/clause.rs>>[init]
//| file: rust/viska-sat/src/clause.rs
use crate::{assignment::Assignment, lit::Lit};
#[derive(Debug, Clone)]
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

    // ~/~ begin <<rust/viska-sat/src/dpll.typ#cla_unit-literal>>[init]
    //| id: cla_unit-literal
    pub fn unit_literal(&self, assign: &Assignment) -> Option<Lit> {
        let mut candidate: Option<Lit> = None;
        for lit in &self.lits {
            match assign.values[lit.var_id] {
                Some(val) if val ^ lit.negated => return None,
                Some(_) => continue,
                None => {
                    if candidate.is_some() {
                        return None;
                    }
                    candidate = Some(lit.clone());
                }
            }
        }
        candidate
    }
    // ~/~ end
}
// ~/~ end
