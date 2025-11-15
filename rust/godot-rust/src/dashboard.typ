== ダッシュボード
ソルバの内部動作を可視化するダッシュボードを作る。以下の要素から構成される：
/ グラフ: 探索木や含意グラフを表示する。
/ 現在の状態: 今何の操作をしているかを表示する（決定・単位伝播など）。
/ 入力: 解く問題を指定する。
/ 制御盤: ソルバの開始・一時停止・ステップなどを操作できる。

構造体 `Dashboard` を定義して、各ソルバに固有な部分（イベントの反映）はジェネリクスによって実装する。

=== 共通部
==== 初期化
まず構造体 Dashboard を定義する。ジェネリクスを使っていることに注意。
```rust
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
    <<dshb_constructor>>
    <<dshb_update>>
    <<dshb_on-start-pressed>>
}
```
コンストラクタを用意する。`parent` を取って、ダッシュボードのシーンを追加する。また、タブ名も引数として取る。
```rust
//| id: dshb_constructor
fn new(tab_name: String, parent: &mut Control) -> Rc<RefCell<Dashboard<S, E, B>>> {
    <<dshb_instantiate-scene>>
    <<dshb_graph-view>>
    <<dshb_state-node>>
    <<dshb_control-node>>
    <<dshb_setup-dashboard>>
    <<dshb_control-connect-signal>>
    dashboard
}
```
シーンのファイルを読み込んで `parent` の子として追加する。
```rust
//| id: dshb_instantiate-scene
let dashboard_packed_scene = load::<PackedScene>("uid://dqcqwojp3jsu5");
let mut dashboard_node = dashboard_packed_scene.instantiate_as::<Control>();
dashboard_node.set_name(&tab_name);
parent.add_child(&dashboard_node);
```
グラフのビジュアライザをシーンの特定の場所に追加する。
```rust
//| id: dshb_graph-view
let mut graph_view_node = dashboard_node.get_node_as::<Node>("%GraphView");
let graph_wrapper = FdgWrapper::new(&mut graph_view_node);
```
State部分で必要なノードをフィールドで保持する。
```rust
//| id: dshb_state-node
let state_node_group = StateNodeGroup {
    state_title: dashboard_node.get_node_as::<Label>("%CurrentState")
};
```
Control部分で必要なノードをフィールドで保持する。
```rust
//| id: dshb_control-node
let control_node_group = ControlNodeGroup {
    start : dashboard_node.get_node_as::<Button>("%Start")
};
```
これで `Dashboard` を初期化することができる。このとき、シグナルのクロージャに渡す用に所有権と可変性のうんぬんをうまく処理できるように `Rc<RefCell<_>>` で包む。これで上手くいく理由はよく分かっていない。
```rust
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
```

そしてシグナルを接続する。
```rust
//| id: dshb_control-connect-signal
let dashboard_start_signal = dashboard.clone();
dashboard.borrow().control_node_group.start.signals().pressed().connect(
    move || {
        dashboard_start_signal.borrow_mut().on_start_pressed();
    }
);
```

==== シグナル

次にControl部分のシグナルを受けて呼ばれるメソッドたちを定義していく。

スタートボタンが押されたら `SolverRunner` を開始させ、スタートボタン以外を有効化し、スタートボタンを無効化する。
```rust
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
```

=== 情報のやりとり
ソルバから情報を受け取って情報を更新する。
```rust
//| id: dshb_update
fn update(&mut self) {

    if let Some(ref mut runner) = self.solver_runner {
        self.visualizer.update(runner);
    }
}
```

=== ソルバごとの動作
各ソルバごとにどのようにビジュアライズするかが異なるので、`Vizualizer` というトレイトを実装する構造体を持って、それぞれ実装する。
```rust
//| id: dshb_visualizer
trait Visualizer {
    type Solver: Solver;
    fn new() -> Self;
    fn update(&mut self, solver_runner: &SolverRunner<Self::Solver>);
}

<<dshbv_brute-force-visualizer>>
```
==== `BruteForceSolver`
`BruteForceSolver` に対応する `BruteForceVisualizer` を宣言する。
```rust
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
```

=== ダッシュボードの表示
ここまで作ってきたダッシュボードを `TabContainer` によって表示する。
```rust
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
```
そして `process` 内で更新を掛ける。
```rust
//| id: dshbd_process
fn process(&mut self, _delta: f32) {
    if let Some(ref mut dashboard) = self.brute_force_dashboard {
        dashboard.borrow_mut().update();
    }
}
```

```rust
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

    <<dshbd_ready>>
    <<dshbd_process>>
}
```

```rust
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

<<dshb_visualizer>>
<<dshb_dashboard>>

type BruteForceSolverForRunner = BruteForceSolver<SolverRunnerEventHandler<BruteForceSolverEvent>>;
type DpllSolverForRunner = DpllSolver<SolverRunnerEventHandler<DpllSolverEvent>>;
type SimpleCdclSolverForRunner = SimpleCdclSolver<SolverRunnerEventHandler<SimpleCdclSolverEvent>>;

<<dshb_displayer>>
```
