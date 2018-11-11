" Language:    Coco
" Maintainer:  satyr
" URL:         http://github.com/satyr/vim-coco
" License:     WTFPL

if exists('b:current_syntax') && b:current_syntax == 'coco'
  finish
endif

let b:current_syntax = "co"

" Highlight long strings.
syntax sync minlines=100

setlocal iskeyword=48-57,A-Z,$,a-z,_

syntax match coIdentifier /[$A-Za-z_]\%(\k\|-\a\)*/
highlight default link coIdentifier Identifier

" These are 'matches' rather than 'keywords' because vim's highlighting priority
" for keywords (the highest) causes them to be wrongly highlighted when used as
" dot-properties.
syntax match coStatement
\ /\<\%(return\|break\|continue\|throw\)\%(\k\|-\a\)\@!/
highlight default link coStatement Statement

syntax match coRepeat
\ /\<\%(for\%( own\| ever\)\?\|while\|until\)\%(\k\|-\a\)\@!/
highlight default link coRepeat Repeat

syntax match coConditional
\ /\<\%(if\|else\|unless\|switch\|case\|default\)\%(\k\|-\a\)\@!/
highlight default link coConditional Conditional

syntax match coException
\ /\<\%(try\|catch\|finally\)\%(\k\|-\a\)\@!/
highlight default link coException Exception

syntax match coKeyword
\ /\%(n\%(ew\|ot\)\|i\%(s\|n\%(stanceof\)\?\|mp\%(ort\%( all\)\?\|lements\)\)\|t\%(hen\|ypeof\|o\|il\)\|d\%(o\|e\%(lete\|bugger\)\)\|e\%(x\%(tends\|port\)\|val\)\|f\%(unction\|allthrough\|rom\)\|c\%(lass\|onst\)\|o[fr]\|and\|let\|with\|var\|super\|by\)\%(\k\|-\a\)\@!/
highlight default link coKeyword Keyword

syntax match coBoolean /\<\%(true\|false\|null\|void\)\%(\k\|-\a\)\@!/
highlight default link coBoolean Boolean

" Matches context variables.
syntax match coContext
\ /\<\%(th\%(is\|at\)\|arguments\|it\|constructor\|prototype\|superclass\|e\)\%(\k\|-\a\)\@!/
highlight default link coContext Type

" Displays an error for future reserved words.
syntax match coFutureReserved
\ /\<\%(enum\|interface\|p\%(ackage\|ublic\|r\%(ivate\|otected\)\)\|static\|yield\)\%(\k\|-\a\)\@!/
highlight default link coFutureReserved Error

" Keywords reserved by the language
syntax cluster coReserved contains=coStatement,coRepeat,coConditional
\                                 ,coException,coOperator,coKeyword,coBoolean
\                                 ,coFutureReserved

" Matches ECMAScript 5 built-in globals.
syntax match coGlobal /\<\%(Array\|Boolean\|Date\|Function\|JSON\|Math\|Number\|Object\|RegExp\|String\|\%(Syntax\|Type\|URI\)\?Error\|is\%(NaN\|Finite\)\|parse\%(Int\|Float\)\|\%(en\|de\)codeURI\%(Component\)\?\)\%(\k\|-\a\)\@!/
highlight default link coGlobal Structure

syntax region coString start=/"/ skip=/\\\\\|\\"/ end=/"/ contains=@coInterpString
syntax region coString start=/'/ skip=/\\\\\|\\'/ end=/'/ contains=@coSimpleString
highlight default link coString String

" Matches decimal/floating-point numbers like 10.42e-8.
syntax match coFloat
\ /\<\d[0-9_]*\%(\.\d[0-9_]*\)\?\%(e[+-]\?\d[0-9_]*\)\?\k*/
\ contains=coNumberComment
highlight default link coFloat Float
syntax match coNumberComment /\d\+\zs\%(e[+-]\?\d\)\@!\k*/ contained
highlight default link coNumberComment Comment
" Matches hex numbers like 0xfff, 0x000.
syntax match coNumber /\<0x\x[0-9A-Fa-f_]*/
" Matches N radix numbers like 2r1010.
syntax match coNumber
\ /\<\%([2-9]\|[12]\d\|3[0-6]\)r[0-9A-Za-z][0-9A-Za-z_]*/
highlight default link coNumber Number

syntax keyword coTodo TODO FIXME XXX contained
highlight default link coTodo Todo

syntax match  coComment /#.*/                   contains=@Spell,coTodo
syntax region coComment start=/\/\*/ end=/\*\// contains=@Spell,coTodo
highlight default link coComment Comment

syntax match coEmbed /\(`\+\)\_.\{-}\1/
highlight default link coEmbed Special

syntax region coInterpolation matchgroup=coInterpDelim
\                                 start=/\#{/ end=/}/
\                                 contained contains=TOP
highlight default link coInterpDelim Delimiter

" Matches escape sequences like \000, \x00, \u0000, \n.
syntax match coEscape /\\\d\d\d\|\\x\x\{2\}\|\\u\x\{4\}\|\\./ contained
highlight default link coEscape SpecialChar

syntax match coVarInterpolation
\ /#\%([$A-Za-z_]\%(\k\|-a\)*\|[@&]\|<>\)/ contained
highlight default link coVarInterpolation Identifier

" What is in a non-interpolated string
syntax cluster coSimpleString contains=@Spell,coEscape
" What is in an interpolated string
syntax cluster coInterpString contains=@coSimpleString,
\                                      coInterpolation,coVarInterpolation

syntax region coRegex start=/\%(\%()\|\i\@<!\d\)\s*\|\i\)\@<!\/\*\@!/
\                     skip=/\[[^]]\{-}\/[^]]\{-}\]/
\                     end=|/[igmy$]\{,4}|
\                     oneline contains=coEscape
syntax region coHeregex
\ start=|//| end=|//[igmy$?]\{,4}|
\ contains=coEscape,coInterpolation,coVarInterpolation,coHeregexComment fold
syntax region coHeregex
\ start=|///| end=|///[igmy$?]\{,4}|
\ contains=coEscape,coInterpolation,coVarInterpolation,coHeregexComment fold
syntax match coHeregexComment /\s#[{$A_Za-z_]\@!.*/
\ contains=@Spell,coTodo contained
highlight default link coRegex          String
highlight default link coHeregex        String
highlight default link coHeregexComment Comment

syntax region coHeredoc start=/"""/ end=/"""/ contains=@coInterpString fold
syntax region coHeredoc start=/'''/ end=/'''/ contains=@coSimpleString fold
highlight default link coHeredoc String

syntax match coWord /\\\S[^ \t\r,;)}\]]*/
highlight default link coWord String

syntax region coWords start=/<\[/ end=/\]>/ contains=fold
highlight default link coWords String

" Reserved words can be used as property names.
syntax match coProp /[$A-Za-z_]\%(\k\|-\a\)*[ \t]*:[:=]\@!/
highlight default link coProp Label

syntax match coKey
\ /\%(\.\@<!\.\%(=\?\s*\|\.\)\|[]})@?]\|::\)\zs\k\%(\k\|-\a\)*/
\ transparent
\ contains=ALLBUT,coIdentifier,coContext,coGlobal,@coReserved

if !exists('b:current_syntax')
  let b:current_syntax = 'coco'
endif
