""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
""  Markology
""
""  Mark visualization, navigation, and management.
""
""  Copyright 2014 Jeet Sukumaran.
""
""  This program is free software; you can redistribute it and/or modify
""  it under the terms of the GNU General Public License as published by
""  the Free Software Foundation; either version 3 of the License, or
""  (at your option) any later version.
""
""  This program is distributed in the hope that it will be useful,
""  but WITHOUT ANY WARRANTY; without even the implied warranty of
""  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
""  GNU General Public License <http://www.gnu.org/licenses/>
""  for more details.
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Reload Guard {{{1
if exists( "loaded_markology" )
    finish
endif
let loaded_markology = 1
" }}}1

" We need signs to show signs! {{{1
if has( "signs" ) == 0
    echohl ErrorMsg
    echo "Markology requires Vim to have +signs support."
    echohl None
    finish
endif
" }}}1

" Compatibility Guard {{{1
" avoid line continuation issues (see ':help user_41.txt')
let s:save_cpo = &cpo
set cpo&vim
" }}}1

" Global Options and Deefaults {{{1
" Options: Set up some nice defaults
if !exists('g:markology_enable'      ) | let g:markology_enable       = 1    | endif
if !exists('g:markology_textlower'   ) | let g:markology_textlower    = "'\t"  | endif
if !exists('g:markology_textupper'   ) | let g:markology_textupper    = "'\t"  | endif
if !exists('g:markology_textother'   ) | let g:markology_textother    = "'\t"  | endif
if !exists('g:markology_ignore_type' ) | let g:markology_ignore_type  = "hq" | endif
if !exists('g:markology_ignore_name' ) | let g:markology_ignore_name  = ""   | endif
if !exists('g:markology_hlline_lower') | let g:markology_hlline_lower = "0"  | endif
if !exists('g:markology_hlline_upper') | let g:markology_hlline_upper = "0"  | endif
if !exists('g:markology_hlline_other') | let g:markology_hlline_other = "0"  | endif
if !exists('g:markology_set_location_list_convenience_maps') | let g:markology_set_location_list_convenience_maps = 1  | endif
" }}}1

" Commands {{{1
com! -nargs=0 MarkologyEnable                           :call markology#MarkologyEnable()
com! -nargs=0 MarkologyDisable                          :call markology#MarkologyDisable()
com! -nargs=0 MarkologyToggle                           :call markology#MarkologyToggle()
com! -nargs=0 MarkologyClearMark                        :call markology#MarkologyClearMark()
com! -nargs=0 MarkologyClearAll                         :call markology#MarkologyClearAll()
com! -nargs=0 MarkologyPlaceMark                        :call markology#MarkologyPlaceMark()
com! -nargs=0 MarkologyPlaceMarkToggle                  :call markology#MarkologyPlaceMarkToggle()
com! -nargs=0 MarkologyNextLocalMarkPos                 :call markology#MarkologyNextByPos()
com! -nargs=0 MarkologyPrevLocalMarkPos                 :call markology#MarkologyPrevByPos()
com! -nargs=0 MarkologyNextLocalMarkByAlpha             :call markology#MarkologyNextByAlpha()
com! -nargs=0 MarkologyPrevLocalMarkByAlpha             :call markology#MarkologyPrevByAlpha()
com! -nargs=0 MarkologyLocationList                     :call markology#MarkologyMarksLocationList()
com! -nargs=0 MarkologyQuickFix                         :call markology#MarkologyMarksQuickFix()
com! -nargs=0 MarkologyLineHighlightToggle              :call markology#MarkologyLineHighlightToggle()
" }}}1

" Plugs {{{1
nnoremap <silent> <Plug>MarkologyEnable                 :MarkologyEnable<CR>
nnoremap <silent> <Plug>MarkologyDisable                :MarkologyDisable<CR>
nnoremap <silent> <Plug>MarkologyToggle                 :MarkologyToggle<CR>
nnoremap <silent> <Plug>MarkologyPlaceMarkToggle        :MarkologyPlaceMarkToggle<CR>
nnoremap <silent> <Plug>MarkologyPlaceMark              :MarkologyPlaceMark<CR>
nnoremap <silent> <Plug>MarkologyClearMark              :MarkologyClearMark<CR>
nnoremap <silent> <Plug>MarkologyClearAll               :MarkologyClearAll<CR>
nnoremap <silent> <Plug>MarkologyNextLocalMarkPos       :MarkologyNextLocalMarkPos<CR>
nnoremap <silent> <Plug>MarkologyPrevLocalMarkPos       :MarkologyPrevLocalMarkPos<CR>
nnoremap <silent> <Plug>MarkologyNextLocalMarkByAlpha   :MarkologyNextLocalMarkByAlpha<CR>
nnoremap <silent> <Plug>MarkologyPrevLocalMarkByAlpha   :MarkologyPrevLocalMarkByAlpha<CR>
nnoremap <silent> <Plug>MarkologyLocationList           :MarkologyLocationList<CR>
nnoremap <silent> <Plug>MarkologyQuickFix               :MarkologyQuickFix<CR>
nnoremap <silent> <Plug>MarkologyLineHighlightToggle    :MarkologyLineHighlightToggle<CR>
" }}}1

" Default Mappings {{{1
" Set Default Mappings (NOTE: Leave the '|'s immediately following the '<cr>' so the mapping does not contain any trailing spaces!)
if !exists("g:markology_disable_mappings") || !g:markology_disable_mappings
    if !exists("g:markology_prefix_leader_on_default_mappings") || !g:markology_prefix_leader_on_default_mappings
        if !hasmapto( '<Plug>MarkologyEnable' )               |  noremap <silent> m1 :MarkologyEnable<cr>|  endif
        if !hasmapto( '<Plug>MarkologyDisable' )              |  noremap <silent> m0 :MarkologyDisable<cr>|  endif
        if !hasmapto( '<Plug>MarkologyToggle' )               |  noremap <silent> m! :MarkologyToggle<cr>|  endif
        if !hasmapto( '<Plug>MarkologyPlaceMarkToggle' )
            noremap <silent> m,       :MarkologyPlaceMarkToggle<cr>
            noremap <silent> m<SPACE> :MarkologyPlaceMarkToggle<cr>
        endif
        if !hasmapto( '<Plug>MarkologyPlaceMark' )            |  noremap <silent> m+ :MarkologyPlaceMark<cr>|  endif
        if !hasmapto( '<Plug>MarkologyClearMark' )            |  noremap <silent> m- :MarkologyClearMark<cr>|  endif
        if !hasmapto( '<Plug>MarkologyClearAll' )             |  noremap <silent> m_ :MarkologyClearAll<cr>|  endif
        if !hasmapto( '<Plug>MarkologyNextLocalMarkPos' )     |  noremap <silent> m] :MarkologyNextLocalMarkPos<cr>|  endif
        if !hasmapto( '<Plug>MarkologyPrevLocalMarkPos' )     |  noremap <silent> m[ :MarkologyPrevLocalMarkPos<cr>|  endif
        if !hasmapto( '<Plug>MarkologyNextLocalMarkByAlpha' ) |  noremap <silent> m{ :MarkologyNextLocalMarkByAlpha<cr>|  endif
        if !hasmapto( '<Plug>MarkologyPrevLocalMarkByAlpha' ) |  noremap <silent> m} :MarkologyPrevLocalMarkByAlpha<cr>|  endif
        if !hasmapto( '<Plug>MarkologyLocationList' )         |  noremap <silent> m? :MarkologyLocationList<cr>|  endif
        if !hasmapto( '<Plug>MarkologyQuickFix' )             |  noremap <silent> m^ :MarkologyQuickFix<cr>|  endif
        if !hasmapto( '<Plug>MarkologyLineHighlightToggle' )  |  noremap <silent> m* :MarkologyLineHighlightToggle<cr>|  endif
    else
        " Legacy ...
        if !hasmapto( '<Plug>MarkologyEnable' )               |  noremap <silent> <Leader>m1 :MarkologyEnable<cr>|  endif
        if !hasmapto( '<Plug>MarkologyDisable' )              |  noremap <silent> <Leader>m0 :MarkologyDisable<cr>|  endif
        if !hasmapto( '<Plug>MarkologyToggle' )               |  noremap <silent> <Leader>m! :MarkologyToggle<cr>|  endif
        if !hasmapto( '<Plug>MarkologyPlaceMarkToggle' )      |  noremap <silent> <Leader>m, :MarkologyPlaceMarkToggle<cr>|  endif
        if !hasmapto( '<Plug>MarkologyPlaceMark' )            |  noremap <silent> <Leader>m+ :MarkologyPlaceMark<cr>|  endif
        if !hasmapto( '<Plug>MarkologyClearMark' )            |  noremap <silent> <Leader>m- :MarkologyClearMark<cr>|  endif
        if !hasmapto( '<Plug>MarkologyClearAll' )             |  noremap <silent> <Leader>m_ :MarkologyClearAll<cr>|  endif
        if !hasmapto( '<Plug>MarkologyNextLocalMarkPos' )     |  noremap <silent> <Leader>m] :MarkologyNextLocalMarkPos<cr>|  endif
        if !hasmapto( '<Plug>MarkologyPrevLocalMarkPos' )     |  noremap <silent> <Leader>m[ :MarkologyPrevLocalMarkPos<cr>|  endif
        if !hasmapto( '<Plug>MarkologyNextLocalMarkByAlpha' ) |  noremap <silent> <Leader>m{ :MarkologyNextLocalMarkByAlpha<cr>|  endif
        if !hasmapto( '<Plug>MarkologyPrevLocalMarkByAlpha' ) |  noremap <silent> <Leader>m} :MarkologyPrevLocalMarkByAlpha<cr>|  endif
        if !hasmapto( '<Plug>MarkologyLocationList' )         |  noremap <silent> <Leader>m? :MarkologyLocationList<cr>|  endif
        if !hasmapto( '<Plug>MarkologyQuickFix' )             |  noremap <silent> <Leader>m^ :MarkologyQuickFix<cr>|  endif
        if !hasmapto( '<Plug>MarkologyLineHighlightToggle' )  |  noremap <silent> <Leader>m* :MarkologyLineHighlightToggle<cr>|  endif
    endif
endif
" }}}1

" Autocommands {{{1
if g:markology_enable == 1
    aug Markology
        au!
        autocmd CursorHold * call markology#Markology()
        autocmd BufNewFile,Bufread * call markology#Markology()
    aug END
endif
" }}}1

" Override `m` {{{1
" noremap <silent> m :exe 'norm \sm'.nr2char(getchar())<bar>call markology#Markology()<CR>
" noremap <script> \sm m
function! s:_m_key_override()
    if &ft == "nerdtree"
        execute "normal! m"
    else
        execute 'normal! m'.nr2char(getchar())
        call markology#Markology()
    endif
endfunction
noremap <silent> m :call <SID>_m_key_override()<CR>
" }}}1

" Restore State {{{1
" restore options
let &cpo = s:save_cpo
" }}}1
