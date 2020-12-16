if exists("b:current_syntax")
  finish
endif

syntax match bfMove    "[<>]"
syntax match bfData    "[+-]"
syntax match bfIO      "[.,]"
syntax match bfLoop    "[[\]]"
syntax match bfComment "[^<>+-.,[\]].*"

highlight def link bfMove    Identifier
highlight def link bfData    Normal
highlight def link bfIO      Function
highlight def link bfLoop    Boolean
highlight def link bfComment Comment

let b:current_syntax = "brainfuck"
