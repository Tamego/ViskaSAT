== Force Directed Graph
ラッパーのテストをする。リアルタイムでグラフの更新ができることを確認したい。

まずは `FDGWrapper` を初期化する。
```rust
//| id: fdgt_init
fn ready(&mut self) {
    let mut binding = self.base_mut();
    let mut fdg_wrapper = FdgWrapper::new(binding.upcast_mut::<Node2D>());
    fdg_wrapper.add_node(0, "Test1".into());
    fdg_wrapper.add_node(1, "Test2".into());
    fdg_wrapper.add_node(2, "Test3".into());
    fdg_wrapper.add_node(3, "Test4".into());
    fdg_wrapper.add_node(4, "Test5".into());
    fdg_wrapper.add_node(5, "Test6".into());
    fdg_wrapper.add_edge(0, 1);
    fdg_wrapper.add_edge(0, 2);
    fdg_wrapper.add_edge(1, 3);
    fdg_wrapper.add_edge(1, 4);
    fdg_wrapper.add_edge(3, 5);
}
```

```rust
//| file: rust/godot-rust/src/tests/force_directed_graph.rs
use godot::prelude::*;
use crate::force_directed_graph::FdgWrapper;

#[derive(GodotClass)]
#[class(base=Node2D)]
struct ForcedDirectedGraphTest {
    base: Base<Node2D>
}

#[godot_api]
impl INode2D for ForcedDirectedGraphTest {
    fn init(base: Base<Node2D>) -> Self {
        Self {
           base
        }
    }

    <<fdgt_init>>
}
```
