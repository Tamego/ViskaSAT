== エントリーポイント

godot-rust APIの主要部分を読み込む。

```rust
//| id: l_godot-rust-api
use godot::prelude::*;
```

ファイル分割して記述したモジュールを読み込む。

```rust
//| id: l_modules
mod tests;
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
<<l_godot-rust-api>>
<<l_modules>>

<<l_gdextension-entry-point>>
```
