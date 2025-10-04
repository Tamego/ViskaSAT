#import "js.typ": *

#show: js

#maketitle(
  title: "ViskaSAT",
  authors: "Tamego",
  date: [],
)

= アルゴリズム
#include "../rust/viska-sat/src/lib.typ"
= Godot
#include "../rust/godot-rust/src/lib.typ"
= テスト
#include "../rust/godot-rust/src/tests/tests.typ"
#include "../rust/godot-rust/src/tests/thread_channel_communication.typ"
