function! brainfuck#Run() abort "{{{
  call s:Init()

  while s:bf_cmdpointer < len(s:bf_commands)
    let l:foo = s:bf_commands[s:bf_cmdpointer]
    let l:command = l:foo[0]
    let l:lnum = l:foo[1]
    let l:cnum = l:foo[2]

    if l:command == 62
      call s:IncreasePointer(l:lnum, l:cnum)
    elseif l:command == 60
      call s:DecreasePointer(l:lnum, l:cnum)
    elseif l:command == 43
      call s:IncreaseValue(l:lnum, l:cnum)
    elseif l:command == 45
      call s:DecreaseValue(l:lnum, l:cnum)
    elseif l:command == 46
      call s:Output()
    elseif l:command == 44
      call s:Input(l:lnum, l:cnum)
    elseif l:command == 91
      call s:JumpForward(l:lnum, l:cnum)
    elseif l:command == 93
      call s:JumpBackward(l:lnum, l:cnum)
    else
      throw 'Unknown command at ' . l:lnum . ':' . l:cnum
    endif

    if g:bf_run_delay
      execute s:bf_buffer_nr . 'wincmd w'
      call cursor(l:lnum, l:cnum)
      redraw
      execute 'sleep ' . g:bf_run_delay . 'm'
    endif

    let s:bf_cmdpointer += 1
  endwhile

  if g:bf_run_delay
    execute s:bf_tmp_buffer_nr . 'wincmd w'
    setlocal nomodifiable
    execute s:bf_buffer_nr . 'wincmd w'
  endif

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
    throw 'The range of g:bf_array_mode is from 0 to 2'
  endif
  if !exists("g:bf_value_type")
    let g:bf_value_type = 0
  elseif g:bf_value_type < 0 || g:bf_value_type > 6
    throw 'The range of g:bf_value_type is from 0 to 6'
  endif
  if !exists("g:bf_value_mode")
    let g:bf_value_mode = 0
  elseif g:bf_value_mode < 0 || g:bf_value_mode > 2
    throw 'The range of g:bf_value_mode is from 0 to 2'
  endif
  if !exists("g:bf_run_delay")
    let g:bf_run_delay = 0
  elseif g:bf_run_delay < 0
    throw 'g:bf_run_delay should be a positive integer'
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
    throw 'You did not give the value of g:bf_value_max'
  elseif !exists("g:bf_value_min")
    throw 'You did not give the value of g:bf_value_min'
  elseif g:bf_value_max < 0
    throw 'g:bf_value_max should be >= 0'
  elseif g:bf_value_min > 0
    throw 'g:bf_value_min should be <= 0'
  else
    let s:bf_value_max = g:bf_value_max
    let s:bf_value_min = g:bf_value_min
  endif "}}}

  let s:bf_commands = [] "{{{
  let s:bf_cmdpointer = 0
  let l:lines = getline(1, line('$'))
  for lnum in range(len(l:lines))
    let l:curr_line = str2list(l:lines[lnum])
    for cnum in range(len(l:curr_line))
      let l:curr_char = l:curr_line[cnum]
      if l:curr_char == 32
        continue
      elseif index([43, 44, 45, 46, 60, 62, 91, 93], l:curr_char) != -1
        call add(s:bf_commands, [l:curr_char, lnum + 1, cnum + 1])
      else
        break
      endif
    endfor
  endfor "}}}

  let s:bf_array = repeat([0], g:bf_array_size)
  let s:bf_pointer = 0
  let s:bf_output = []

  if g:bf_run_delay "{{{
    let s:bf_buffer_nr = winnr()
    if bufwinnr('bf_tmp') == -1
      below 20vnew +set\ nonumber\ |\ set\ cursorline\ |\ set\ buftype=nofile bf_tmp
      let b:bf_tmp_buffer = 0
      autocmd BufEnter * if (winnr('$') == 1 && exists('b:bf_tmp_buffer')) | q | endif
    endif
    let s:bf_tmp_buffer_nr = bufwinnr('bf_tmp')

    execute s:bf_tmp_buffer_nr . 'wincmd w'
    setlocal modifiable
    execute 'normal! ggdG'
    for i in range(g:bf_array_size)
      call append(i, printf('%6d: %11d', i, 0))
    endfor
    execute 'normal! ddgg'
  endif "}}}
endfunction "}}}

function! s:IncreasePointer(lnum, cnum) abort "{{{
  let s:bf_pointer += 1

  if s:bf_pointer >= g:bf_array_size
    if g:bf_array_mode == 0
      throw 'Pointer overflow at ' . a:lnum . ':' . a:cnum
    elseif g:bf_array_mode == 1
      let s:bf_pointer = g:bf_array_size - 1
    elseif g:bf_array_mode == 2
      let s:bf_pointer = 0
    endif
  endif

  if g:bf_run_delay
    execute s:bf_tmp_buffer_nr . 'wincmd w'
    execute 'normal! ' . (s:bf_pointer + 1) . 'G'
  endif
endfunction "}}}

function! s:DecreasePointer(lnum, cnum) abort "{{{
  let s:bf_pointer -= 1

  if s:bf_pointer < 0
    if g:bf_array_mode == 0
      throw 'Pointer underflow at ' . a:lnum . ':' . a:cnum
    elseif g:bf_array_mode == 1
      let s:bf_pointer = 0
    elseif g:bf_array_mode == 2
      let s:bf_pointer = g:bf_array_size - 1
    endif
  endif

  if g:bf_run_delay
    execute s:bf_tmp_buffer_nr . 'wincmd w'
    execute 'normal! ' . (s:bf_pointer + 1) . 'G'
  endif
endfunction "}}}

function! s:IncreaseValue(lnum, cnum) abort "{{{
  let s:bf_array[s:bf_pointer] += 1

  if s:bf_array[s:bf_pointer] > s:bf_value_max
    if g:bf_value_mode == 0
      throw 'Value overflow at ' . a:lnum . ':' . a:cnum
    elseif g:bf_value_mode == 1
      let s:bf_array[s:bf_pointer] = s:bf_value_max
    elseif g:bf_value_mode == 2
      let s:bf_array[s:bf_pointer] = s:bf_value_min
    endif
  endif

  if g:bf_run_delay
    execute s:bf_tmp_buffer_nr . 'wincmd w'
    call setline(s:bf_pointer + 1, printf('%6d: %11d', s:bf_pointer, s:bf_array[s:bf_pointer]))
  endif
endfunction "}}}

function! s:DecreaseValue(lnum, cnum) abort "{{{
  let s:bf_array[s:bf_pointer] -= 1

  if s:bf_array[s:bf_pointer] < s:bf_value_min
    if g:bf_value_mode == 0
      throw 'Value underflow at ' . a:lnum . ':' . a:cnum
    elseif g:bf_value_mode == 1
      let s:bf_array[s:bf_pointer] = s:bf_value_min
    elseif g:bf_value_mode == 2
      let s:bf_array[s:bf_pointer] = s:bf_value_max
    endif
  endif

  if g:bf_run_delay
    execute s:bf_tmp_buffer_nr . 'wincmd w'
    call setline(s:bf_pointer + 1, printf('%6d: %11d', s:bf_pointer, s:bf_array[s:bf_pointer]))
  endif
endfunction "}}}

function! s:Output() abort "{{{
  call add(s:bf_output, s:bf_array[s:bf_pointer])

  if g:bf_run_delay
    echomsg nr2char(s:bf_array[s:bf_pointer])
  endif
endfunction "}}}

function! s:Input(lnum, cnum) abort "{{{
  echo 'Please enter a character: '
  let s:bf_array[s:bf_pointer] = getchar()

  if s:bf_array[s:bf_pointer] > s:bf_value_max
    if g:bf_value_mode == 0
      throw 'Input overflow at ' . a:lnum . ':' . a:cnum
    elseif g:bf_value_mode == 1
      let s:bf_array[s:bf_pointer] = s:bf_value_max
    elseif g:bf_value_mode == 2
      let s:bf_array[s:bf_pointer] = (s:bf_array[s:bf_pointer] - s:bf_value_min)
        \% (s:bf_value_max - s:bf_value_min + 1) + s:bf_value_min
    endif
  elseif s:bf_array[s:bf_pointer] < s:bf_value_min
    if g:bf_value_mode == 0
      throw 'Input underflow at ' . a:lnum . ':' . a:cnum
    elseif g:bf_value_mode == 1
      let s:bf_array[s:bf_pointer] = s:bf_value_min
    elseif g:bf_value_mode == 2
      let s:bf_array[s:bf_pointer] = s:bf_value_max
        \- (s:bf_value_max - s:bf_array[s:bf_pointer]) % (s:bf_value_max - s:bf_value_min + 1)
    endif
  endif

  if g:bf_run_delay
    execute s:bf_tmp_buffer_nr . 'wincmd w'
    call setline(s:bf_pointer + 1, printf('%6d: %11d', s:bf_pointer, s:bf_array[s:bf_pointer]))
  endif
endfunction "}}}

function! s:JumpForward(lnum, cnum) abort "{{{
  let l:count = 1

  if s:bf_array[s:bf_pointer] == 0
    while l:count > 0
      let s:bf_cmdpointer += 1
      if s:bf_cmdpointer >= len(s:bf_commands)
        throw 'Cannot find matching ] at ' . a:lnum . ':' . a:cnum
      elseif s:bf_commands[s:bf_cmdpointer][0] == 91
        let l:count += 1
      elseif s:bf_commands[s:bf_cmdpointer][0] == 93
        let l:count -= 1
      endif
    endwhile
  endif
endfunction "}}}

function! s:JumpBackward(lnum, cnum) abort "{{{
  let l:count = 1

  if s:bf_array[s:bf_pointer] != 0
    while l:count > 0
      let s:bf_cmdpointer -= 1
      if s:bf_cmdpointer < 0
        throw 'Cannot find matching [ at ' . a:lnum . ':' . a:cnum
      elseif s:bf_commands[s:bf_cmdpointer][0] == 91
        let l:count -= 1
      elseif s:bf_commands[s:bf_cmdpointer][0] == 93
        let l:count += 1
      endif
    endwhile
  endif
endfunction "}}}
