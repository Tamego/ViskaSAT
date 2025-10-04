// ~/~ begin <<rust/godot-rust/src/lib.typ#rust/godot-rust/src/lib.rs>>[init]
//| file: rust/godot-rust/src/lib.rs
// ~/~ begin <<rust/godot-rust/src/lib.typ#l_godot-rust-api>>[init]
//| id: l_godot-rust-api
use godot::prelude::*;
// ~/~ end
// ~/~ begin <<rust/godot-rust/src/lib.typ#l_modules>>[init]
//| id: l_modules
mod tests;
// ~/~ end

// ~/~ begin <<rust/godot-rust/src/lib.typ#l_gdextension-entry-point>>[init]
//| id: l_gdextension-entry-point
struct ViskaSATExtension;

#[gdextension]
unsafe impl ExtensionLibrary for ViskaSATExtension {}
// ~/~ end
// ~/~ end
