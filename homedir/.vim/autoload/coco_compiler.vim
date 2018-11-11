" Language:    Coco
" Maintainer:  satyr
" URL:         http://github.com/satyr/vim-coco
" License:     WTFPL

if exists('current_compiler')
  finish
endif

let current_compiler = 'co'
" Pattern to check if coco is the compiler
let s:pat = '^' . current_compiler

" Path to Coco compiler
if !exists('coco_compiler')
  let coco_compiler = 'coco'
endif

if !exists('coco_make_options')
  let coco_make_options = ''
endif

" Get a `makeprg` for the current filename. This is needed to support filenames
" with spaces and quotes, but also not break generic `make`.
function! s:GetMakePrg()
  return g:coco_compiler . ' -c ' . g:coco_make_options . ' $* '
  \                      . fnameescape(expand('%'))
endfunction

" Set `makeprg` and return 1 if coffee is still the compiler, else return 0.
function! s:SetMakePrg()
  if &l:makeprg =~ s:pat
    let &l:makeprg = s:GetMakePrg()
  elseif &g:makeprg =~ s:pat
    let &g:makeprg = s:GetMakePrg()
  else
    return 0
  endif

  return 1
endfunction

" Set a dummy compiler so we can check whether to set locally or globally.
CompilerSet makeprg=coco
call s:SetMakePrg()

CompilerSet errorformat=%EFailed\ at:\ %f,
                       \%ECan't\ find:\ %f,
                       \%CSyntaxError:\ %m\ on\ line\ %l,
                       \%CError:\ Parse\ error\ on\ line\ %l:\ %m,
                       \%C,%C\ %.%#

" Compile the current file.
command! -bang -bar -nargs=* CocoMake make<bang> <args>

" Set `makeprg` on rename since we embed the filename in the setting.
augroup CocoUpdateMakePrg
  autocmd!

  " Update `makeprg` if coco is still the compiler, else stop running this
  " function.
  function! s:UpdateMakePrg()
    if !s:SetMakePrg()
      autocmd! CocoUpdateMakePrg
    endif
  endfunction

  " Set autocmd locally if compiler was set locally.
  if &l:makeprg =~ s:pat
    autocmd BufFilePost,BufWritePost <buffer> call s:UpdateMakePrg()
  else
    autocmd BufFilePost,BufWritePost          call s:UpdateMakePrg()
  endif
augroup END
