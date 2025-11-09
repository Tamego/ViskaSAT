watch:
  #!/usr/bin/env bash
  entangled watch &
  ent_pid=$!
  typst watch typst/viska-sat.typ &
  typst watch typst/poster.typ &
  typ_pid=$!
  trap 'kill -TERM "$ent_pid" "$typ_pid"' EXIT
  wait
