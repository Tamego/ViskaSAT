// ~/~ begin <<rust/godot-rust/src/dashboard.typ#rust/godot-rust/src/dashboard.rs>>[init]
//| file: rust/godot-rust/src/dashboard.rs
use godot::prelude::*;
use godot::classes::{Label, TabContainer, ITabContainer, Control, Button};
use viska_sat::brute_force::{BruteForceSolver, BruteForceSolverEvent};
use viska_sat::cnf::Cnf;
use viska_sat::{lit::Lit, clause::Clause};
use viska_sat::dpll::{DpllSolver, DpllSolverEvent};
use viska_sat::simple_cdcl::{SimpleCdclSolver, SimpleCdclSolverEvent};
use viska_sat::solver_runner::SolverRunnerEventHandler;

use std::rc::Rc;
use std::cell::RefCell;
use std::marker::PhantomData;

use crate::force_directed_graph::FdgWrapper;
use viska_sat::{solver::Solver, solver_runner::SolverRunner};

struct ControlNodeGroup {
    start: Gd<Button>
}

struct StateNodeGroup {
    state_title: Gd<Label>,
}

// ~/~ begin <<rust/godot-rust/src/dashboard.typ#dshb_visualizer>>[init]
//| id: dshb_visualizer
trait Visualizer {
    type Solver: Solver;
    fn new() -> Self;
    fn update(&mut self, solver_runner: &SolverRunner<Self::Solver>);
}

// ~/~ begin <<rust/godot-rust/src/dashboard.typ#dshbv_brute-force-visualizer>>[init]
//| id: dshbv_brute-force-visualizer
struct BruteForceVisualizer;
impl Visualizer for BruteForceVisualizer {
    type Solver = BruteForceSolverForRunner;
    fn new() -> Self {
        BruteForceVisualizer
    }

    fn update(&mut self, runner: &SolverRunner<Self::Solver>) {
        if let Ok(Some(received)) = runner.try_recv_event() {
            godot_print!("{:?}", received);
        }
    }
}
// ~/~ end
// ~/~ end
// ~/~ begin <<rust/godot-rust/src/dashboard.typ#dshb_dashboard>>[init]
//| id: dshb_dashboard
struct Dashboard<S: Solver, E, B: Visualizer> {
    visualizer: B,
    solver_runner: Option<SolverRunner<S>>,
    state_node_group: StateNodeGroup,
    control_node_group: ControlNodeGroup,
    graph_wrapper: FdgWrapper,
    cnf: Cnf,
    _marker: PhantomData<E>
}

impl<S, E, B> Dashboard<S, E, B>
where
    B: Visualizer<Solver=S> + 'static,
    S: Solver<Event = E, Handler = SolverRunnerEventHandler<E>> + Send + 'static,
    E: Send + 'static,
    S::Error: Send + 'static,
{
    // ~/~ begin <<rust/godot-rust/src/dashboard.typ#dshb_constructor>>[init]
    //| id: dshb_constructor
    fn new(tab_name: String, parent: &mut Control) -> Rc<RefCell<Dashboard<S, E, B>>> {
        // ~/~ begin <<rust/godot-rust/src/dashboard.typ#dshb_instantiate-scene>>[init]
        //| id: dshb_instantiate-scene
        let dashboard_packed_scene = load::<PackedScene>("uid://dqcqwojp3jsu5");
        let mut dashboard_node = dashboard_packed_scene.instantiate_as::<Control>();
        dashboard_node.set_name(&tab_name);
        parent.add_child(&dashboard_node);
        // ~/~ end
        // ~/~ begin <<rust/godot-rust/src/dashboard.typ#dshb_graph-view>>[init]
        //| id: dshb_graph-view
        let mut graph_view_node = dashboard_node.get_node_as::<Node>("%GraphView");
        let graph_wrapper = FdgWrapper::new(&mut graph_view_node);
        // ~/~ end
        // ~/~ begin <<rust/godot-rust/src/dashboard.typ#dshb_state-node>>[init]
        //| id: dshb_state-node
        let state_node_group = StateNodeGroup {
            state_title: dashboard_node.get_node_as::<Label>("%CurrentState")
        };
        // ~/~ end
        // ~/~ begin <<rust/godot-rust/src/dashboard.typ#dshb_control-node>>[init]
        //| id: dshb_control-node
        let control_node_group = ControlNodeGroup {
            start : dashboard_node.get_node_as::<Button>("%Start")
        };
        // ~/~ end
        // ~/~ begin <<rust/godot-rust/src/dashboard.typ#dshb_setup-dashboard>>[init]
        //| id: dshb_setup-dashboard
        let dashboard = Rc::new(RefCell::new( Dashboard::<S, E, B> {
            visualizer: B::new(),
            solver_runner: None,
            state_node_group,
            control_node_group,
            graph_wrapper,
            cnf: Cnf {
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
            _marker: PhantomData
        } ));
        // ~/~ end
        // ~/~ begin <<rust/godot-rust/src/dashboard.typ#dshb_control-connect-signal>>[init]
        //| id: dshb_control-connect-signal
        let dashboard_start_signal = dashboard.clone();
        dashboard.borrow().control_node_group.start.signals().pressed().connect(
            move || {
                dashboard_start_signal.borrow_mut().on_start_pressed();
            }
        );
        // ~/~ end
        dashboard
    }
    // ~/~ end
    // ~/~ begin <<rust/godot-rust/src/dashboard.typ#dshb_update>>[init]
    //| id: dshb_update
    fn update(&mut self) {

        if let Some(ref mut runner) = self.solver_runner {
            self.visualizer.update(runner);
        }
    }
    // ~/~ end
    // ~/~ begin <<rust/godot-rust/src/dashboard.typ#dshb_on-start-pressed>>[init]
    //| id: dshb_on-start-pressed
    fn on_start_pressed(&mut self) {
        self.control_node_group.start.set_disabled(true);
        let cnf = self.cnf.clone();
        self.solver_runner = Some(SolverRunner::start_solver(
            |handler| {
                S::make_solver(cnf, handler)
            }
        ));
    }
    // ~/~ end
}
// ~/~ end

type BruteForceSolverForRunner = BruteForceSolver<SolverRunnerEventHandler<BruteForceSolverEvent>>;
type DpllSolverForRunner = DpllSolver<SolverRunnerEventHandler<DpllSolverEvent>>;
type SimpleCdclSolverForRunner = SimpleCdclSolver<SolverRunnerEventHandler<SimpleCdclSolverEvent>>;

// ~/~ begin <<rust/godot-rust/src/dashboard.typ#dshb_displayer>>[init]
//| id: dshb_displayer
#[derive(GodotClass)]
#[class(base=TabContainer)]
struct DashboardDisplayer {
    brute_force_dashboard: Option<Rc<RefCell<Dashboard<BruteForceSolverForRunner, BruteForceSolverEvent, BruteForceVisualizer>>>>,
    base: Base<TabContainer>
}

#[godot_api]
impl ITabContainer for DashboardDisplayer {
    fn init(base: Base<TabContainer>) -> Self {
        Self {
            brute_force_dashboard: None,
           base
        }
    }

    // ~/~ begin <<rust/godot-rust/src/dashboard.typ#dshbd_ready>>[init]
    //| id: dshbd_ready
    fn ready(&mut self) {
        let dashboard = Dashboard::new(
            "全探索".into(),
            &mut self.base_mut()
        );
        self.brute_force_dashboard = Some(dashboard);
        // Dashboard::<DpllSolverForRunner>::new(
        //     "DPLL".into(),
        //     &mut self.base_mut()
        // );
        // Dashboard::<SimpleCdclSolverForRunner>::new(
        //     "CDCL".into(),
        //     &mut self.base_mut()
        // );
    }
    // ~/~ end
    // ~/~ begin <<rust/godot-rust/src/dashboard.typ#dshbd_process>>[init]
    //| id: dshbd_process
    fn process(&mut self, _delta: f32) {
        if let Some(ref mut dashboard) = self.brute_force_dashboard {
            dashboard.borrow_mut().update();
        }
    }
    // ~/~ end
}
// ~/~ end
// ~/~ end
