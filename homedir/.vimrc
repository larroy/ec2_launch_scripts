filetype plugin on
"let g:pydiction_location = '~/.vim/complete-dict'
if has("syntax") && (&t_Co > 2 || has("gui_running"))
  syntax on     
  set bg=dark
  set hlsearch
  set ignorecase
  set autoindent
  set smarttab
" for nokia
"  set noexpandtab
  set expandtab
  set textwidth=100
  set tabstop=4
  set softtabstop=4
  set shiftwidth=4
  set laststatus=2
  let python_highlight_all = 1

" backups
	set backup
	set writebackup

endif


" Tab completion
set complete=.,k,w,b,u,t
function! Tab_Or_Complete()
    if col('.')>1 && strpart( getline('.'), col('.')-2, 3 ) =~ '^\w'
        "return "\<C-X>\<C-O>"
        return "\<C-N>"
    else
        return "\<Tab>"
    endif
endfunction
:inoremap <Tab> <C-R>=Tab_Or_Complete()<CR>
":inoremap <C-A> <C-R>=Tab_Or_Complete()<CR>
:inoremap <C-A> <C-R>="\<C-X>\<C-O>"<CR>



au BufNewFile,BufRead SCons* set filetype=scons
"set mouse=a
"  -saf: space after for
"  -sai: space after if
"  -saw: space after while
"  -bap: blank lines after procedure
"  -nbfda: don't break function decl args
"  -npsl: don't break procedure type
"  -cs: space after cast
"  -br: braces on if line
"  -ce: cuddle else and }
"  -ut: use tabs
"  -ts2: tab size to 2 spaces
"  -st: standard output
"  -nbbo: no break before boolean
"		Break of function definition with one indentation level
"  -nlp: no line-up parentheses
"  -ci2: continuation indentation to 2spaces => one tab
"map f :%!indent -saf -sai -saw -bap -nbfda -npsl -cs -br -ce -ut -ts2 -st -nbbo -nlp -ci2 -npcs -cli2<CR>
"map f :%!indent -saf -sai -saw -bap -nbfda -npsl -cs -br -ce -nut -ts2 -st -nbbo -nlp -ci2 -npcs -cli2 -i4<CR>
"map f :!indent -saf -sai -saw -bap -prs -di8 -nbfda -npsl -cs -br -ce -nut -ts2 -st -nbbo -nlp -ci2 -npcs -cli2 -i4<CR>
"map <C-m> :%!flip -u -b -<CR>
"map c :tn<CR>
"map x :tp<CR>
set incsearch
"noremap ; :%s:::cg<Left><Left><Left><Left>
"noremap ; :s/^/\/\/e/<CR>
"map ; :source cammel.vim<CR>

map <C-F> i{<CR>}<C-O>O
map <C-B> <ESC>:%s/\s\+$//<CR>

map _ ebi"ea"
"map _ F(istatic_cast<<ESC>ldlt)ldli><ESC>
"map _ i'hi');
"map _ a');hhhi'
"map <F1> :e
"map <F1> <Esc>:w<CR>:perl $e = `./error.pl`; my ($f,$l,@w) = split(":",$e); my $w=join(":",@w); $curwin->Cursor($l,0); VIM::Msg($w);<CR>
"map <F1> ]c
map <F1> :diffget<CR>
map <F2> :wincmd w<CR>
map <F3> :wincmd s<CR>
map <F4> :wincmd v<CR>
map <F5> :w<CR>
map <F6> :q<CR>
map <F7> :wincmd -<CR>
map <F8> :wincmd +<CR>
map <F9> :wincmd <<CR>
map <F10> :wincmd ><CR>
"map h :wincmd h<CR>
"map j :wincmd j<CR>
"map k :wincmd k<CR>
"map l :wincmd l<CR>

"map <F5> :wincmd o<CR>
"map <F6> :sball<CR>
"map <F7> :wq<CR>
"map <F8> :wincmd q<CR>
"map <F9> :wincmd -<CR>
"map <F10> :wincmd +<CR>
"map <F11> :wincmd <<CR>
"map <F12> :wincmd ><CR>
"map <C-m> :%s/\r\n/\n/g<CR>
ab copyc <ESC>:set paste<CR>i/*<CR> * Copyright 2007 Pedro Larroy Tovar<CR> *<CR> * This file is subject to the terms and conditions<CR> * defined in file 'LICENSE.txt', which is part of this source<CR> * code package.<CR> */<CR><ESC>:set nopaste<CR>
ab copyp <ESC>:set paste<CR>i# Copyright 2007 Pedro Larroy Tovar<CR>#<CR># This file is subject to the terms and conditions<CR># defined in file 'LICENSE.txt', which is part of this source<CR># code package.<CR>#<CR><ESC>:set nopaste<CR>
ab #e *******************************************************/
ab #b /*******************************************************
ab #\ ###########################################
ab cpph #include <iostream><CR>#include <string><CR>#include <cstdlib><CR>#include <cassert><CR>#include <vector><CR>#include <stdexcept><CR>using namespace std;<CR>int main(int argc, char *argv[])<CR>{
ab perlh #!/usr/bin/perl<CR>use strict;<CR>use warnings;<CR>
"ab pyh <ESC>:set paste<CR>i#!/usr/bin/env python<CR>import os<CR>import sys<CR>def main():<CR><TAB>return<CR>if __name__ == '__main__':<CR><TAB>main()<CR><ESC>:set nopaste<CR>
ab pyh <ESC>:set paste<CR>i#!/usr/bin/env python<CR># -*- coding: utf-8 -*-<CR>"""Description"""<CR><CR>__author__ = 'Pedro Larroy'<CR>__version__ = '0.1'<CR><CR>import os<CR>import sys<CR>import subprocess<CR><CR>def usage():<CR>    sys.stderr.write('usage: {0}\n'.format(sys.argv[0]))<CR><CR>def xsystem(args):<CR>    if subprocess.call(args) != 0:<CR>        raise RuntimeError('check_exit failed, while executing:', ' '.join(args))<CR><CR>def xcall(args):<CR>    p = subprocess.Popen(args, stdout=subprocess.PIPE, stderr=subprocess.PIPE)<CR>    (stdout, stderr) = p.communicate()<CR>    ret = p.returncode<CR>    return (stdout, stderr, ret)<CR><CR>def main():<CR><CR>    return 1<CR><CR>if __name__ == '__main__':<CR>    sys.exit(main())<CR><ESC>:set nopaste<CR>
ab chdr #include <stdio.h><CR>#include <sys/types.h><CR>#include <unistd.h><CR>#include <stdlib.h><CR>#include <sys/stat.h><CR>#include <sys/wait.h><CR>#include <string.h><CR>int main(int argc, char *argv[])<CR>{

ab nokcopy <ESC>:set paste<CR>i// -------------------------------------------------------------------------------------------------<CR>//<CR>// Copyright (C) 2007-2011, Nokia gate5 GmbH Berlin<CR>//<CR>// These coded instructions, statements, and computer programs contain<CR>// unpublished proprietary information of Nokia gate5 GmbH Berlin, and are copy<CR>// protected by law. They may not be disclosed to third parties or copied<CR>// or duplicated in any form, in whole or in part, without the specific,<CR>// prior written permission of Nokia gate5 GmbH Berlin.<CR>//<CR>#pragma once


ab picopy <ESC>:set paste<CR>i/**<CR> * Copyright (C) 2012, Pedro Larroy Tovar<CR> */<CR><CR>#pragma once

ab picopy <ESC>:set paste<CR>i/**<CR> * Copyright (C) 2012, Pedro Larroy Tovar<CR> */<CR><CR>#pragma once  

ab xhtmlhdr <?xml version="1.0" encoding="UTF-8"?><CR><!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"><CR><html xmlns="http://www.w3.org/1999/xhtml"><CR>	<head><CR>	<title></title><CR><link href="style.css" rel="STYLESHEET" type="text/css"><CR></head>
"ab loop for ( ::iterator i = .begin(); i != .end(); ++i) {
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" CSCOPE settings for vim
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"
" This file contains some boilerplate settings for vim's cscope interface,
" plus some keyboard mappings that I've found useful.
"
" USAGE:
" -- vim 6:     Stick this file in your ~/.vim/plugin directory (or in a
"               'plugin' directory in some other directory that is in your
"               'runtimepath'.
"
" -- vim 5:     Stick this file somewhere and 'source cscope.vim' it from
"               your ~/.vimrc file (or cut and paste it into your .vimrc).
"
" NOTE:
" These key maps use multiple keystrokes (2 or 3 keys).  If you find that vim
" keeps timing you out before you can complete them, try changing your timeout
" settings, as explained below.
"
" Happy cscoping,
"
" Jason Duell       jduell@alumni.princeton.edu     2002/3/7
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


" This tests to see if vim was configured with the '--enable-cscope' option
" when it was compiled.  If it wasn't, time to recompile vim...
if has("cscope")

    """"""""""""" Standard cscope/vim boilerplate

    " use both cscope and ctag for 'ctrl-]', ':ta', and 'vim -t'
    set cscopetag

    " check cscope for definition of a symbol before checking ctags: set to 1
    " if you want the reverse search order.
    set csto=0

    " add any cscope database in current directory
    if filereadable("cscope.out")
        cs add cscope.out
    " else add the database pointed to by environment variable
    elseif $CSCOPE_DB != ""
        cs add $CSCOPE_DB
    endif

    " show msg when any other cscope db added
    set cscopeverbose


    """"""""""""" My cscope/vim key mappings
    "
    " The following maps all invoke one of the following cscope search types:
    "
    "   's'   symbol: find all references to the token under cursor
    "   'g'   global: find global definition(s) of the token under cursor
    "   'c'   calls:  find all calls to the function name under cursor
    "   't'   text:   find all instances of the text under cursor
    "   'e'   egrep:  egrep search for the word under cursor
    "   'f'   file:   open the filename under cursor
    "   'i'   includes: find files that include the filename under cursor
    "   'd'   called: find functions that function under cursor calls
    "
    " Below are three sets of the maps: one set that just jumps to your
    " search result, one that splits the existing vim window horizontally and
    " diplays your search result in the new window, and one that does the same
    " thing, but does a vertical split instead (vim 6 only).
    "
    " I've used CTRL-\ and CTRL-@ as the starting keys for these maps, as it's
    " unlikely that you need their default mappings (CTRL-\'s default use is
    " as part of CTRL-\ CTRL-N typemap, which basically just does the same
    " thing as hitting 'escape': CTRL-@ doesn't seem to have any default use).
    " If you don't like using 'CTRL-@' or CTRL-\, , you can change some or all
    " of these maps to use other keys.  One likely candidate is 'CTRL-_'
    " (which also maps to CTRL-/, which is easier to type).  By default it is
    " used to switch between Hebrew and English keyboard mode.
    "
    " All of the maps involving the <cfile> macro use '^<cfile>$': this is so
    " that searches over '#include <time.h>" return only references to
    " 'time.h', and not 'sys/time.h', etc. (by default cscope will return all
    " files that contain 'time.h' as part of their name).


    " To do the first type of search, hit 'CTRL-\', followed by one of the
    " cscope search types above (s,g,c,t,e,f,i,d).  The result of your cscope
    " search will be displayed in the current window.  You can use CTRL-T to
    " go back to where you were before the search.
    "

    nmap <C-\>s :cs find s <C-R>=expand("<cword>")<CR><CR>
    nmap <C-\>g :cs find g <C-R>=expand("<cword>")<CR><CR>
    nmap <C-\>c :cs find c <C-R>=expand("<cword>")<CR><CR>
    nmap <C-\>t :cs find t <C-R>=expand("<cword>")<CR><CR>
    nmap <C-\>e :cs find e <C-R>=expand("<cword>")<CR><CR>
    nmap <C-\>f :cs find f <C-R>=expand("<cfile>")<CR><CR>
    nmap <C-\>i :cs find i ^<C-R>=expand("<cfile>")<CR>$<CR>
    nmap <C-\>d :cs find d <C-R>=expand("<cword>")<CR><CR>


    " Using 'CTRL-spacebar' (intepreted as CTRL-@ by vim) then a search type
    " makes the vim window split horizontally, with search result displayed in
    " the new window.
    "
    " (Note: earlier versions of vim may not have the :scs command, but it
    " can be simulated roughly via:
    "    nmap <C-@>s <C-W><C-S> :cs find s <C-R>=expand("<cword>")<CR><CR>

    nmap <C-@>s :scs find s <C-R>=expand("<cword>")<CR><CR>
    nmap <C-@>g :scs find g <C-R>=expand("<cword>")<CR><CR>
    nmap <C-@>c :scs find c <C-R>=expand("<cword>")<CR><CR>
    nmap <C-@>t :scs find t <C-R>=expand("<cword>")<CR><CR>
    nmap <C-@>e :scs find e <C-R>=expand("<cword>")<CR><CR>
    nmap <C-@>f :scs find f <C-R>=expand("<cfile>")<CR><CR>
    nmap <C-@>i :scs find i ^<C-R>=expand("<cfile>")<CR>$<CR>
    nmap <C-@>d :scs find d <C-R>=expand("<cword>")<CR><CR>


    " Hitting CTRL-space *twice* before the search type does a vertical
    " split instead of a horizontal one (vim 6 and up only)
    "
    " (Note: you may wish to put a 'set splitright' in your .vimrc
    " if you prefer the new window on the right instead of the left

    nmap <C-@><C-@>s :vert scs find s <C-R>=expand("<cword>")<CR><CR>
    nmap <C-@><C-@>g :vert scs find g <C-R>=expand("<cword>")<CR><CR>
    nmap <C-@><C-@>c :vert scs find c <C-R>=expand("<cword>")<CR><CR>
    nmap <C-@><C-@>t :vert scs find t <C-R>=expand("<cword>")<CR><CR>
    nmap <C-@><C-@>e :vert scs find e <C-R>=expand("<cword>")<CR><CR>
    nmap <C-@><C-@>f :vert scs find f <C-R>=expand("<cfile>")<CR><CR>
    nmap <C-@><C-@>i :vert scs find i ^<C-R>=expand("<cfile>")<CR>$<CR>
    nmap <C-@><C-@>d :vert scs find d <C-R>=expand("<cword>")<CR><CR>


    """"""""""""" key map timeouts
    "
    " By default Vim will only wait 1 second for each keystroke in a mapping.
    " You may find that too short with the above typemaps.  If so, you should
    " either turn off mapping timeouts via 'notimeout'.
    "
    "set notimeout
    "
    " Or, you can keep timeouts, by uncommenting the timeoutlen line below,
    " with your own personal favorite value (in milliseconds):
    "
    "set timeoutlen=4000
    "
    " Either way, since mapping timeout settings by default also set the
    " timeouts for multicharacter 'keys codes' (like <F1>), you should also
    " set ttimeout and ttimeoutlen: otherwise, you will experience strange
    " delays as vim waits for a keystroke after you hit ESC (it will be
    " waiting to see if the ESC is actually part of a key code like <F1>).
    "
    "set ttimeout
    "
    " personally, I find a tenth of a second to work well for key code
    " timeouts. If you experience problems and have a slow terminal or network
    " connection, set it higher.  If you don't set ttimeoutlen, the value for
    " timeoutlent (default: 1000 = 1 second, which is sluggish) is used.
    "
    "set ttimeoutlen=100

endif



" localrc.vim
" Set directory-wise configuration.
" Search from the directory the file is located upwards to the root for
" a local configuration file called .lvimrc and sources it.
"
" The local configuration file is expected to have commands affecting
" only the current buffer.

function SetLocalOptions(fname)
	let dirname = fnamemodify(a:fname, ":p:h")
	while "/" != dirname
		let lvimrc  = dirname . "/.lvimrc"
		if filereadable(lvimrc)
			execute "source " . lvimrc
			break
		endif
		let dirname = fnamemodify(dirname, ":p:h:h")
	endwhile
endfunction

au BufNewFile,BufRead * call SetLocalOptions(bufname("%"))

if filereadable(".lvimrc")
    execute "source .lvimrc"
endif


"au BufNewFile,BufRead *.cpp set dictionary+=~/.vim/cpp-dict
function Cppcmds()
    if &filetype == "cpp"
    "    set dictionary+=~/.vim/cpp-dict
        ":inoremap ( ()<Esc>:let leavechar=")"<CR>i
        ":inoremap [ []<Esc>:let leavechar="]"<CR>i
        ":inoremap { {<CR>}<Esc>%:let leavechar="}"<CR>o<Tab>
        :imap <C-l> <Esc>:exec "normal f" . leavechar<CR>a
        :map { [{
        :map } ]}
    endif
endfunction
au BufNewFile,BufRead * call Cppcmds() 

execute pathogen#infect()
