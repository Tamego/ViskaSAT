// ~/~ begin <<rust/godot-rust/src/lib.typ#rust/godot-rust/src/lib.rs>>[init]
//| file: rust/godot-rust/src/lib.rs
// ~/~ begin <<rust/godot-rust/src/lib.typ#grl_godot-rust-api>>[init]
//| id: grl_godot-rust-api
use godot::prelude::*;
// ~/~ end
// ~/~ begin <<rust/godot-rust/src/lib.typ#grl_modules>>[init]
//| id: grl_modules
mod tests;
mod force_directed_graph;
// ~/~ end

// ~/~ begin <<rust/godot-rust/src/lib.typ#grl_gdextension-entry-point>>[init]
//| id: grl_gdextension-entry-point
struct ViskaSATExtension;

#[gdextension]
unsafe impl ExtensionLibrary for ViskaSATExtension {}
// ~/~ end
// ~/~ end
