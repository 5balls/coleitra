" Vim syntax file
" Language:	NUWEB
" Maintainer:	Florian Pesth <fpesth@gmx.de>
" Last Change:  08.01.2021

" For version 5.x: Clear all syntax items
" For version 6.x: Quit when a syntax file was already loaded
if version < 600
  syntax clear
elseif exists("b:current_syntax")
  finish
endif

runtime! syntax/tex.vim
unlet b:current_syntax

syntax include @TeX syntax/tex.vim
unlet b:current_syntax

syntax region nuwebWriteFile matchgroup=nuwebCommand start="@o" start="@O" keepend end="\%#=2\(\a\|_\)\+\.\&\(\a\|_\)\+" end="\zeCMakeLists" containedin=@TeX contains=@nuweb fold
syntax region nuwebSnippet matchgroup=nuwebCommand start="@d" keepend end="@}" containedin=@TeX contains=@nuweb fold
 
highlight nuwebWriteFile cterm=italic ctermfg=lightred
highlight nuwebCommand cterm=bold,italic ctermfg=lightblue
highlight nuwebSnippet cterm=bold,italic ctermfg=lightblue
highlight nuwebBrace cterm=bold ctermfg=red

syntax include @CPP syntax/cpp.vim
syntax region cppScrap matchgroup=nuwebBrace start="cpp -d\n@{" start="h -d\n@{" keepend end="\n@}" containedin=@TeX contains=@CPP fold
unlet b:current_syntax

syntax include @json syntax/json.vim
syntax region jsonScrap matchgroup=nuwebBrace start="json\n@{" keepend end="\n@}" containedin=@TeX contains=@json fold
unlet b:current_syntax

syntax include @cmake syntax/cmake.vim
syntax region cmakeScrap matchgroup=nuwebBrace start="CMakeLists.txt\n@{" keepend end="@}" containedin=@TeX contains=@cmake fold
unlet b:current_syntax

syntax include @Python syntax/python.vim
syntax region cmakeScrap matchgroup=nuwebBrace start="py\n@{" keepend end="@}" containedin=@TeX contains=@Python fold
unlet b:current_syntax

syntax include @Dockerfile syntax/dockerfile.vim
syntax region cmakeScrap matchgroup=nuwebBrace start="Dockerfile\n@{" keepend end="@}" containedin=@TeX contains=@Dockerfile fold
unlet b:current_syntax


syntax region nuwebMacro matchgroup=nuwebBrace start="@<" keepend end="@>" containedin=cppScrap,cmakeScrap,nuwebSnippet,nuwebSnippetContent,@TeX contains=@nuweb fold
highlight nuwebMacro cterm=bold ctermfg=green
syntax region nuwebArgument matchgroup=nuwebBrace start="@'" keepend end="@'" containedin=nuwebMacro,nuwebSnippet contains=@nuweb
highlight nuwebArgument cterm=bold ctermfg=blue
syntax region nuwebSnippetContent matchgroup=nuwebBrace start="@{" keepend end="@}" containedin=@TeX,nuwebSnippet contains=@cmake,@CPP,@Python,@Dockerfile fold
syntax keyword nuwebSnippetArguments contained @1 @2 @3 @4 @5
highlight nuwebSnippetArguments cterm=bold ctermfg=blue


let b:current_syntax = "nuweb (Literate Programming)"

