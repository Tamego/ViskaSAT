// ~/~ begin <<rust/viska-sat/tests/tests.typ#rust/viska-sat/tests/brute_force_solver.rs>>[init]
//| file: rust/viska-sat/tests/brute_force_solver.rs
mod common;
use common::solve_with_logging;
use viska_sat::brute_force::BruteForceSolver;

#[test]
fn brute_force_solver_with_logging() {
    solve_with_logging(|cnf, handler| BruteForceSolver{ cnf, handler });
}
// ~/~ end
