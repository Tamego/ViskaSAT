// ~/~ begin <<rust/viska-sat/tests/tests.typ#rust/viska-sat/tests/brute_force_solver.rs>>[init]
//| file: rust/viska-sat/tests/brute_force_solver.rs
mod common;
use common::solve_with_logging;
use viska_sat::{brute_force::BruteForceSolver, solver::Solver};

#[test]
fn brute_force_solver_with_logging() {
    for i in 0..=1 {
        solve_with_logging(BruteForceSolver::make_solver, i);
    }
}
// ~/~ end
