// ~/~ begin <<rust/viska-sat/tests/tests.typ#rust/viska-sat/tests/simple_cdcl_solver.rs>>[init]
//| file: rust/viska-sat/tests/simple_cdcl_solver.rs
mod common;
use common::solve_with_logging;
use viska_sat::simple_cdcl::SimpleCdclSolver;

#[test]
fn simple_cdcl_with_logging() {
    for i in 0..=1 {
        solve_with_logging(|cnf, handler| SimpleCdclSolver{ cnf, handler }, i);
    }
}
// ~/~ end
