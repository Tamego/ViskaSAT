// ~/~ begin <<rust/godot-rust/src/force_directed_graph.typ#rust/godot-rust/src/force_directed_graph.rs>>[init]
//| file: rust/godot-rust/src/force_directed_graph.rs
use godot::prelude::*;
use godot::classes::{GDScript, Line2D, Label, control::GrowDirection};

use std::collections::HashMap;

// ~/~ begin <<rust/godot-rust/src/force_directed_graph.typ#fdg_wrapper>>[init]
//| id: fdg_wrapper
pub struct FdgWrapper {
    fdg_node_script: Gd<GDScript>,
    fdg_spring_script: Gd<GDScript>,
    fdg_graph_node: Gd<Node2D>,
    fdg_nodes: HashMap<usize, Gd<Node2D>>,
    fdg_spring_nodes: HashMap<usize, Vec<Gd<Line2D>>>
}

impl FdgWrapper {
    // ~/~ begin <<rust/godot-rust/src/force_directed_graph.typ#fdgw_constructor>>[init]
    //| id: fdgw_constructor
    pub fn new(parent: &mut Node) -> FdgWrapper {
        // ~/~ begin <<rust/godot-rust/src/force_directed_graph.typ#fdgw_load-scripts>>[init]
        //| id: fdgw_load-scripts
        let fdg_graph_script = try_load::<GDScript>("uid://b4hv0bkllrrj3").unwrap();
        let fdg_node_script = try_load::<GDScript>("uid://dsdxhi5k3341a").unwrap();
        let fdg_spring_script = try_load::<GDScript>("uid://8co5qevg864t").unwrap();
        // ~/~ end

        // ~/~ begin <<rust/godot-rust/src/force_directed_graph.typ#fdgw_init-graph-node>>[init]
        //| id: fdgw_init-graph-node
        let mut fdg_graph_node = Node2D::new_alloc();
        fdg_graph_node.set_script(&fdg_graph_script.to_variant());
        parent.add_child(&fdg_graph_node);
        // ~/~ end

        FdgWrapper {
            fdg_node_script,
            fdg_spring_script,
            fdg_graph_node,
            fdg_nodes: HashMap::new(),
            fdg_spring_nodes: HashMap::new()
        }
    }
    // ~/~ end

    // ~/~ begin <<rust/godot-rust/src/force_directed_graph.typ#fdgw_add-node>>[init]
    //| id: fdgw_add-node
    pub fn add_node(&mut self, id: usize, label_text: GString) {
        let mut fdg_node = Node2D::new_alloc();
        fdg_node.set_script(&self.fdg_node_script.to_variant());
        fdg_node.set("draw_point", &true.to_variant());
        fdg_node.set("point_color", &Color::from_html("ccd0da").unwrap().to_variant());
        // fdg_node.set("min_distance", &51.to_variant());
        fdg_node.set_position(Vector2::new(
            godot::global::randf() as f32, godot::global::randf() as f32
        ));

        let mut label_node = Label::new_alloc();
        label_node.set_text(&label_text);
        label_node.set_h_grow_direction(GrowDirection::BOTH);
        label_node.set_v_grow_direction(GrowDirection::BOTH);

        fdg_node.add_child(&label_node);

        self.fdg_graph_node.add_child(&fdg_node);

        if self.fdg_nodes.contains_key(&id) {
            panic!("this id is already used");
        }
        self.fdg_nodes.insert(id, fdg_node);

        self.fdg_graph_node.call("update_graph_simulation", &[]);
    }
    // ~/~ end

    // ~/~ begin <<rust/godot-rust/src/force_directed_graph.typ#fdgw_add-edge>>[init]
    //| id: fdgw_add-edge
    pub fn add_edge(&mut self, start: usize, end: usize) {
        let mut fdg_node = Line2D::new_alloc();
        fdg_node.set_script(&self.fdg_spring_script.to_variant());
        fdg_node.set("node_start", &self.fdg_nodes[&start].to_variant());
        fdg_node.set("node_end", &self.fdg_nodes[&end].to_variant());
        fdg_node.set("length", &300.to_variant());
        fdg_node.set_default_color(Color::from_html("4c4f69").unwrap());
        fdg_node.set_width(8.0);

        self.fdg_nodes.get_mut(&start).unwrap().add_child(&fdg_node);

        self.fdg_spring_nodes.entry(end).or_insert(vec![]).push(fdg_node);

        self.fdg_graph_node.call("update_graph_simulation", &[]);
    }
    // ~/~ end
}
// ~/~ end
// ~/~ end
