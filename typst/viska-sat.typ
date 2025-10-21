#import "js.typ": *

#show: js

#maketitle(
  title: "ViskaSAT",
  authors: "Tamego",
  date: [],
)

#outline()

= 共通インターフェース
#include "../rust/viska-sat/src/lib.typ"
#include "../rust/viska-sat/src/basic_types.typ"
#include "../rust/viska-sat/src/solver.typ"
#include "../rust/viska-sat/src/solver_communicator.typ"
#include "../rust/viska-sat/src/event_handler.typ"
#include "../rust/viska-sat/src/solver_runner.typ"
= アルゴリズム
#include "../rust/viska-sat/src/brute_force.typ"
#include "../rust/viska-sat/src/dpll.typ"
= Godot
#include "../rust/godot-rust/src/lib.typ"
= テスト
#include "../rust/godot-rust/src/tests.typ"
#include "../rust/godot-rust/src/tests/thread_channel_communication.typ"
#include "../rust/godot-rust/src/tests/solver_trait.typ"
#include "../rust/godot-rust/src/tests/solver_communicator.typ"
#include "../rust/godot-rust/src/tests/solver_runner.typ"
#include "../rust/viska-sat/tests/tests.typ"
