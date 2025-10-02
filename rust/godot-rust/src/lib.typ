== エントリーポイント

godot-rust *APIの*主要部分を読み込む。

```rust
//| id: l_godot-rust-module
use godot::prelude::*;
```

空の構造体 `ViskaSATExtension` を作って、
GDExtension用のエントリーポイントにする。
Godotとやりとりをする部分だから `unsafe` になっている。

```rust
//| id: l_gdextension-entry-point
struct ViskaSATExtension;

#[gdextension]
unsafe impl ExtensionLibrary for ViskaSATExtension {}
```

```rust 
//| file: rust/godot-rust/src/lib.rs
<<l_godot-rust-module>>

<<l_gdextension-entry-point>>
```
