// ~/~ begin <<rust/viska-sat/tests/tests.typ#rust/viska-sat/tests/dpll_solver.rs>>[init]
//| file: rust/viska-sat/tests/dpll_solver.rs
mod common;
use common::solve_with_logging;
use viska_sat::{dpll::DpllSolver, solver::Solver};

#[test]
fn dpll_with_logging() {
    for i in 0..=1 {
        solve_with_logging(DpllSolver::make_solver, i);
    }
}
// ~/~ end
