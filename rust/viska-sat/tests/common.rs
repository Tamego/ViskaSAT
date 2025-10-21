// ~/~ begin <<rust/viska-sat/tests/tests.typ#rust/viska-sat/tests/common.rs>>[init]
//| file: rust/viska-sat/tests/common.rs
use viska_sat::{clause::Clause, cnf::Cnf, event_handler::EventHandler, lit::Lit, solver::{SatResult, Solver}};
use std::fmt::Debug;
use std::marker::PhantomData;
use std::time::{Duration, Instant};
// ~/~ begin <<rust/viska-sat/tests/tests.typ#vst_run-solver>>[init]
//| id: vst_run-solver
fn run_solver<S, H, F>(cnf: Cnf, handler: H, make_solver: F) -> (Result<SatResult, S::Error>, Duration)
where
    S: Solver,
    H: EventHandler,
    F: FnOnce(Cnf, H) -> S
{
    let mut solver = make_solver(cnf, handler);
    let start = Instant::now();
    let result = solver.solve();
    let elapsed = start.elapsed();
    (result, elapsed)
}
// ~/~ end
// ~/~ begin <<rust/viska-sat/tests/tests.typ#vst_logger-handler>>[init]
//| id: vst_logger-handler
pub struct LoggerHandler<E: Debug> {
    _marker: PhantomData<E>
}

impl<E: Debug> LoggerHandler<E> {
    fn new() -> Self {
        Self {
            _marker: PhantomData
        }
    }
}

impl<E: Debug> EventHandler for LoggerHandler<E> 
{
    type Event = E;
    type Error = ();

    fn handle_event(&mut self, event: Self::Event) -> Result<(), Self::Error> {
        println!("{:?}", event);
        Ok(())
    }
}
// ~/~ end
// ~/~ begin <<rust/viska-sat/tests/tests.typ#vst_solve-with-logging>>[init]
//| id: vst_solve-with-logging
pub fn solve_with_logging<S, F>(make_solver: F, test_num: usize)
where
    S: Solver,
    S::Event: Debug,
    F: FnOnce(Cnf, LoggerHandler<S::Event>) -> S
{
    // ~/~ begin <<rust/viska-sat/tests/tests.typ#vst_sample-cnf>>[init]
    //| id: vst_sample-cnf
    let sample_cnfs = vec![
        Cnf {
            num_vars: 3,
            clauses: vec![
                Clause { lits: vec![
                    Lit { var_id: 0, negated: false },
                    Lit { var_id: 1, negated: false },
                    Lit { var_id: 2, negated: false },
                ], meta: () },
                Clause { lits: vec![
                    Lit { var_id: 0, negated: true },
                    Lit { var_id: 1, negated: true },
                ], meta: () },
                Clause { lits: vec![
                    Lit { var_id: 0, negated: false },
                    Lit { var_id: 1, negated: true },
                    Lit { var_id: 2, negated: true },
                ], meta: () },
            ],
        },
    ];
    // ~/~ end
    let cnf = sample_cnfs[test_num].clone();
    println!("problem: {:?}", test_num);
    let handler = LoggerHandler::<S::Event>::new();
    let (_result, elapsed) = run_solver(cnf, handler, make_solver);
    println!("time: {:?}", elapsed);
}
// ~/~ end
// ~/~ begin <<rust/viska-sat/tests/tests.typ#vst_solve-many-small>>[init]
//| id: vst_solve-many-small
// ~/~ end
// ~/~ begin <<rust/viska-sat/tests/tests.typ#vst_solve-many-large>>[init]
//| id: vst_solve-many-large
// ~/~ end
// ~/~ end
