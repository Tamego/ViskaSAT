// ~/~ begin <<rust/viska-sat/src/basic_types.typ#rust/viska-sat/src/cnf.rs>>[init]
//| file: rust/viska-sat/src/cnf.rs
use crate::{assignment::Assignment, clause::Clause, lit::Lit};
pub struct Cnf {
    pub clauses: Vec<Clause>,
    pub num_vars: usize
}

// ~/~ begin <<rust/viska-sat/src/dpll.typ#cnf_unit-clause>>[init]
//| id: cnf_unit-clause
pub struct UnitClause {
    pub clause_id: usize,
    pub lit: Lit
}
// ~/~ end

impl Cnf {
    pub fn is_satisfied_by(&self, assign: &Assignment) -> bool {
        for clause in &self.clauses {
            if !clause.is_satisfied_by(assign) {
                return false;
            }
        }
        return true;
    }

    // ~/~ begin <<rust/viska-sat/src/dpll.typ#cnf_collect-unit-clauses>>[init]
    //| id: cnf_collect-unit-clauses
    pub fn collect_unit_clauses(&self, assign: &Assignment) -> Vec<UnitClause> {
        let mut unit_clauses = vec![];
        for i in 0..self.clauses.len() {
            if let Some(lit) = self.clauses[i].unit_literal(assign) {
                unit_clauses.push(UnitClause{
                    clause_id: i,
                    lit
                });
            }
        }
        return unit_clauses;
    }
    // ~/~ end
}
// ~/~ end
