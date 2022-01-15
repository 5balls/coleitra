syntax on
set expandtab
set shiftwidth=4
set background=dark
set foldmethod=syntax
colorscheme gruvbox
imap <tab> <C-n>
autocmd BufRead ~/src/own/coleitra/doc/*.w nnoremap <F5> :!pdflatex coleitra.tex<cr>
autocmd BufRead ~/src/own/coleitra/doc/*.w nnoremap <F6> :make -C ../build/x64/<cr>
autocmd BufRead ~/src/own/coleitra/doc/*.w nnoremap <F7> :Termdebug ../build/x64/coleitra<cr>
autocmd BufRead ~/src/own/coleitra/doc/*.w nnoremap <F8> :Termdebug! ../build/x64/coleitra<cr>
autocmd BufRead ~/src/own/coleitra/doc/*.w nnoremap <F12> :!nuweb -lr coleitra.w<cr>
autocmd BufRead ~/src/own/coleitra/doc/*.w packadd termdebug
 
