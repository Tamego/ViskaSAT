#import "js.typ": *

#show: js

#maketitle(
  title: "ViskaSAT",
  authors: "Tamego",
  date: [],
)

= アルゴリズム
#include "../rust/viska-sat/src/lib.typ"
#include "../rust/viska-sat/src/basic_types.typ"
#include "../rust/viska-sat/src/solver.typ"
#include "../rust/viska-sat/src/solver_communicator.typ"
#include "../rust/viska-sat/src/event_handler.typ"
= Godot
#include "../rust/godot-rust/src/lib.typ"
= テスト
#include "../rust/godot-rust/src/tests/tests.typ"
#include "../rust/godot-rust/src/tests/thread_channel_communication.typ"
