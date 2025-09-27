// ~/~ begin <<rust/src/lib.md#rust/src/lib.rs>>[init]
// ~/~ begin <<rust/src/lib.md#l_godot-rust-module>>[init]
use godot::prelude::*;
// ~/~ end

// ~/~ begin <<rust/src/lib.md#l_gdextension-entry-point>>[init]
struct ViskaSATExtension;

#[gdextension]
unsafe impl ExtensionLibrary for ViskaSATExtension {}
// ~/~ end
// ~/~ end
