" Language:    Coco
" Maintainer:  satyr
" URL:         http://github.com/satyr/vim-coco
" License:     WTFPL

if exists("b:did_ftplugin")
  finish
endif

let b:did_ftplugin = 1

setlocal formatoptions-=t formatoptions+=croql
setlocal comments=:#
setlocal commentstring=#\ %s
setlocal omnifunc=javascriptcomplete#CompleteJS

" Enable CocoMake if it won't overwrite any settings.
if !len(&l:makeprg)
  compiler co
endif

" Check here too in case the compiler above isn't loaded.
if !exists('coco_compiler')
  let coco_compiler = 'coco'
endif

" Reset the CocoCompile variables for the current buffer.
function! s:CocoCompileResetVars()
  " Compiled output buffer
  let b:coco_compile_buf = -1
  let b:coco_compile_pos = []

  " If CocoCompile is watching a buffer
  let b:coco_compile_watch = 0
endfunction

" Clean things up in the source buffer.
function! s:CocoCompileClose()
  exec bufwinnr(b:coco_compile_src_buf) 'wincmd w'
  silent! autocmd! CocoCompileAuWatch * <buffer>
  call s:CocoCompileResetVars()
endfunction

" Update the CocoCompile buffer given some input lines.
function! s:CocoCompileUpdate(startline, endline)
  let input = join(getline(a:startline, a:endline), "\n")

  " Move to the CocoCompile buffer.
  exec bufwinnr(b:coco_compile_buf) 'wincmd w'

  " Coco doesn't like empty input.
  if !len(input)
    return
  endif

  " Compile input.
  let output = system(g:coco_compiler . ' -scb 2>&1', input)

  " Be sure we're in the CocoCompile buffer before overwriting.
  if exists('b:coco_compile_buf')
    echoerr 'CocoCompile buffers are messed up'
    return
  endif

  " Replace buffer contents with new output and delete the last empty line.
  setlocal modifiable
    exec '% delete _'
    put! =output
    exec '$ delete _'
  setlocal nomodifiable

  " Highlight as JavaScript if there is no compile error.
  if v:shell_error
    setlocal filetype=
  else
    setlocal filetype=javascript
  endif

  call setpos('.', b:coco_compile_pos)
endfunction

" Update the CocoCompile buffer with the whole source buffer.
function! s:CocoCompileWatchUpdate()
  call s:CocoCompileUpdate(1, '$')
  exec bufwinnr(b:coco_compile_src_buf) 'wincmd w'
endfunction

" Peek at compiled CocoScript in a scratch buffer. We handle ranges like this
" to prevent the cursor from being moved (and its position saved) before the
" function is called.
function! s:CocoCompile(startline, endline, args)
  if !executable(g:coco_compiler)
    echoerr "Can't find CocoScript compiler `" . g:coco_compiler . "`"
    return
  endif

  " If in the CocoCompile buffer, switch back to the source buffer and
  " continue.
  if !exists('b:coco_compile_buf')
    exec bufwinnr(b:coco_compile_src_buf) 'wincmd w'
  endif

  " Parse arguments.
  let watch = a:args =~ '\<watch\>'
  let unwatch = a:args =~ '\<unwatch\>'
  let size = str2nr(matchstr(a:args, '\<\d\+\>'))

  " Determine default split direction.
  if exists('g:coco_compile_vert')
    let vert = 1
  else
    let vert = a:args =~ '\<vert\%[ical]\>'
  endif

  " Remove any watch listeners.
  silent! autocmd! CocoCompileAuWatch * <buffer>

  " If just unwatching, don't compile.
  if unwatch
    let b:coco_compile_watch = 0
    return
  endif

  if watch
    let b:coco_compile_watch = 1
  endif

  " Build the CocoCompile buffer if it doesn't exist.
  if bufwinnr(b:coco_compile_buf) == -1
    let src_buf = bufnr('%')
    let src_win = bufwinnr(src_buf)

    " Create the new window and resize it.
    if vert
      let width = size ? size : winwidth(src_win) / 2

      belowright vertical new
      exec 'vertical resize' width
    else
      " Try to guess the compiled output's height.
      let height = size ? size : min([winheight(src_win) / 2,
      \                               a:endline - a:startline + 5])

      belowright new
      exec 'resize' height
    endif

    " We're now in the scratch buffer, so set it up.
    setlocal bufhidden=wipe buftype=nofile
    setlocal nobuflisted nomodifiable noswapfile nowrap

    autocmd BufWipeout <buffer> call s:CocoCompileClose()
    " Save the cursor when leaving the CocoCompile buffer.
    autocmd BufLeave <buffer> let b:coco_compile_pos = getpos('.')

    nnoremap <buffer> <silent> q :hide<CR>

    let b:coco_compile_src_buf = src_buf
    let buf = bufnr('%')

    " Go back to the source buffer and set it up.
    exec bufwinnr(b:coco_compile_src_buf) 'wincmd w'
    let b:coco_compile_buf = buf
  endif

  if b:coco_compile_watch
    call s:CocoCompileWatchUpdate()

    augroup CocoCompileAuWatch
      autocmd InsertLeave <buffer> call s:CocoCompileWatchUpdate()
    augroup END
  else
    call s:CocoCompileUpdate(a:startline, a:endline)
  endif
endfunction

" Complete arguments for the CocoCompile command.
function! s:CocoCompileComplete(arg, cmdline, cursor)
  let args = ['unwatch', 'vertical', 'watch']

  if !len(a:arg)
    return args
  endif

  let match = '^' . a:arg

  for arg in args
    if arg =~ match
      return [arg]
    endif
  endfor
endfunction

" Don't overwrite the CoffeeCompile variables.
if !exists("s:coco_compile_buf")
  call s:CocoCompileResetVars()
endif

" Peek at compiled Coco.
command! -range=% -bar -nargs=* -complete=customlist,s:CocoCompileComplete
\        CocoCompile call s:CocoCompile(<line1>, <line2>, <q-args>)
" Run some Coco.
command! -range=% -bar CocoRun <line1>,<line2>:w !coco -sp
