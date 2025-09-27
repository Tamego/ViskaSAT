# エントリーポイント

godot-rust API の主要部分を読み込む。

```{.rust #l_godot-rust-module}
use godot::prelude::*;
```

空の構造体 `ViskaSATExtension` を作って、
GDExtension 用のエントリーポイントにする。
Godot とやりとりをする部分だから `unsafe` になっている。

```{.rust #l_gdextension-entry-point}
struct ViskaSATExtension;

#[gdextension]
unsafe impl ExtensionLibrary for ViskaSATExtension {}
```

```{.rust file=rust/godot-rust/src/lib.rs}
<<l_godot-rust-module>>

<<l_gdextension-entry-point>>
```
