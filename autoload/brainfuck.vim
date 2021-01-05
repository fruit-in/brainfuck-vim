function! brainfuck#Run() abort "{{{
  call s:Init()

  while s:bf_cmdpointer < len(s:bf_commands)
    if s:bf_commands[s:bf_cmdpointer] == 62
      call s:IncreasePointer()
    elseif s:bf_commands[s:bf_cmdpointer] == 60
      call s:DecreasePointer()
    elseif s:bf_commands[s:bf_cmdpointer] == 43
      call s:IncreaseValue()
    elseif s:bf_commands[s:bf_cmdpointer] == 45
      call s:DecreaseValue()
    elseif s:bf_commands[s:bf_cmdpointer] == 46
      call s:Output()
    elseif s:bf_commands[s:bf_cmdpointer] == 44
      call s:Input()
    elseif s:bf_commands[s:bf_cmdpointer] == 91
      call s:JumpForward()
    elseif s:bf_commands[s:bf_cmdpointer] == 93
      call s:JumpBackward()
    else
      throw 'unknown command'
    endif

    let s:bf_cmdpointer += 1
  endwhile

  echo list2str(s:bf_output)
endfunction "}}}

function! s:Init() abort "{{{
  if !exists("g:bf_array_size") "{{{
    let g:bf_array_size = 30000
  elseif g:bf_array_size <= 0
    throw 'g:bf_array_size should be a positive integer'
  endif
  if !exists("g:bf_array_mode")
    let g:bf_array_mode = 0
  elseif g:bf_array_mode < 0 || g:bf_array_mode > 2
    throw 'the range of g:bf_array_mode is from 0 to 2'
  endif
  if !exists("g:bf_value_type")
    let g:bf_value_type = 0
  elseif g:bf_value_type < 0 || g:bf_value_type > 6
    throw 'the range of g:bf_value_type is from 0 to 6'
  endif
  if !exists("g:bf_value_mode")
    let g:bf_value_mode = 0
  elseif g:bf_value_mode < 0 || g:bf_value_mode > 2
    throw 'the range of g:bf_value_mode is from 0 to 2'
  endif "}}}

  if g:bf_value_type == 0 "{{{
    let s:bf_value_max = 255
    let s:bf_value_min = 0
  elseif g:bf_value_type == 1
    let s:bf_value_max = 127
    let s:bf_value_min = -128
  elseif g:bf_value_type == 2
    let s:bf_value_max = 65535
    let s:bf_value_min = 0
  elseif g:bf_value_type == 3
    let s:bf_value_max = 32767
    let s:bf_value_min = -32768
  elseif g:bf_value_type == 4
    let s:bf_value_max = 4294967295
    let s:bf_value_min = 0
  elseif g:bf_value_type == 5
    let s:bf_value_max = 2147483647
    let s:bf_value_min = -2147483648
  elseif !exists("g:bf_value_max")
    throw 'you did not give the value of g:bf_value_max'
  elseif !exists("g:bf_value_min")
    throw 'you did not give the value of g:bf_value_min'
  elseif g:bf_value_max < 0
    throw 'g:bf_value_max should be >= 0'
  elseif g:bf_value_min > 0
    throw 'g:bf_value_min should be <= 0'
  else
    let s:bf_value_max = g:bf_value_max
    let s:bf_value_min = g:bf_value_min
  endif "}}}

  let s:bf_commands = []
  let s:bf_cmdpointer = 0
  for curr_line in getline(1, line('$'))
    for curr_char in str2list(curr_line)
      if curr_char == 32
        continue
      elseif index([43, 44, 45, 46, 60, 62, 91, 93], curr_char) != -1
        call add(s:bf_commands, curr_char)
      else
        break
      endif
    endfor
  endfor

  let s:bf_array = repeat([0], g:bf_array_size)
  let s:bf_pointer = 0
  let s:bf_output = []
endfunction "}}}

function! s:IncreasePointer() abort "{{{
  let s:bf_pointer += 1

  if s:bf_pointer >= g:bf_array_size
    if g:bf_array_mode == 0
      throw 'pointer overflow'
    elseif g:bf_array_mode == 1
      let s:bf_pointer = g:bf_array_size - 1
    elseif g:bf_array_mode == 2
      let s:bf_pointer = 0
    endif
  endif
endfunction "}}}

function! s:DecreasePointer() abort "{{{
  let s:bf_pointer -= 1

  if s:bf_pointer < 0
    if g:bf_array_mode == 0
      throw 'pointer underflow'
    elseif g:bf_array_mode == 1
      let s:bf_pointer = 0
    elseif g:bf_array_mode == 2
      let s:bf_pointer = g:bf_array_size - 1
    endif
  endif
endfunction "}}}

function! s:IncreaseValue() abort "{{{
  let s:bf_array[s:bf_pointer] += 1

  if s:bf_array[s:bf_pointer] > s:bf_value_max
    if g:bf_value_mode == 0
      throw 'value overflow'
    elseif g:bf_value_mode == 1
      let s:bf_array[s:bf_pointer] = s:bf_value_max
    elseif g:bf_value_mode == 2
      let s:bf_array[s:bf_pointer] = s:bf_value_min
    endif
  endif
endfunction "}}}

function! s:DecreaseValue() abort "{{{
  let s:bf_array[s:bf_pointer] -= 1

  if s:bf_array[s:bf_pointer] < s:bf_value_min
    if g:bf_value_mode == 0
      throw 'value underflow'
    elseif g:bf_value_mode == 1
      let s:bf_array[s:bf_pointer] = s:bf_value_min
    elseif g:bf_value_mode == 2
      let s:bf_array[s:bf_pointer] = s:bf_value_max
    endif
  endif
endfunction "}}}

function! s:Output() abort "{{{
  call add(s:bf_output, s:bf_array[s:bf_pointer])
endfunction "}}}

function! s:Input() abort "{{{
  echo 'Please enter a character: '
  let s:bf_array[s:bf_pointer] = getchar()

  if s:bf_array[s:bf_pointer] > s:bf_value_max
    if g:bf_value_mode == 0
      throw 'input overflow'
    elseif g:bf_value_mode == 1
      let s:bf_array[s:bf_pointer] = s:bf_value_max
    elseif g:bf_value_mode == 2
      let s:bf_array[s:bf_pointer] = (s:bf_array[s:bf_pointer] - s:bf_value_min)
        \% (s:bf_value_max - s:bf_value_min + 1) + s:bf_value_min
    endif
  elseif s:bf_array[s:bf_pointer] < s:bf_value_min
    if g:bf_value_mode == 0
      throw 'input underflow'
    elseif g:bf_value_mode == 1
      let s:bf_array[s:bf_pointer] = s:bf_value_min
    elseif g:bf_value_mode == 2
      let s:bf_array[s:bf_pointer] = s:bf_value_max
        \- (s:bf_value_max - s:bf_array[s:bf_pointer]) % (s:bf_value_max - s:bf_value_min + 1)
    endif
  endif
endfunction "}}}

function! s:JumpForward() abort "{{{
  let l:count = 1

  if s:bf_array[s:bf_pointer] == 0
    while l:count > 0
      let s:bf_cmdpointer += 1
      if s:bf_cmdpointer >= len(s:bf_commands)
        throw 'cannot find matching ]'
      elseif s:bf_commands[s:bf_cmdpointer] == 91
        let l:count += 1
      elseif s:bf_commands[s:bf_cmdpointer] == 93
        let l:count -= 1
      endif
    endwhile
  endif
endfunction "}}}

function! s:JumpBackward() abort "{{{
  let l:count = 1

  if s:bf_array[s:bf_pointer] != 0
    while l:count > 0
      let s:bf_cmdpointer -= 1
      if s:bf_cmdpointer < 0
        throw 'cannot find matching ['
      elseif s:bf_commands[s:bf_cmdpointer] == 91
        let l:count -= 1
      elseif s:bf_commands[s:bf_cmdpointer] == 93
        let l:count += 1
      endif
    endwhile
  endif
endfunction "}}}
