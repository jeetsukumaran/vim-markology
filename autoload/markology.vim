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

" Compatibility Guard {{{1
" ============================================================================
" avoid line continuation issues (see ':help user_41.txt')
let s:save_cpo = &cpo
set cpo&vim
" }}}1

" Script Variables {{{1
" ============================================================================

" This is the default, and used in MarkologySetup to set up info for any
" possible mark (not just those specified in the possibly user-supplied list
" of marks to show -- it can be changed on-the-fly).
let s:all_marks = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.'`^<>[]{}()\""

unlockvar s:marks_names
unlockvar s:marks_count
unlockvar s:marks_nlist
let s:marks_names = 'abcdefghijklmnopqrstuvwxyz'
let s:marks_nlist = split(s:marks_names, '\zs')
let s:marks_count = strlen(s:marks_names)
lockvar s:marks_names
lockvar s:marks_nlist
lockvar s:marks_count

if !exists('g:lmarks_names')
    " let g:lmarks_names = 'abcdefghijklmnopqrstuvwxyz''.'
    let g:lmarks_names = 'abcdefghijklmnopqrstuvwxyz'
endif

if !exists('g:gmarks_names')
    let g:gmarks_names = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
endif

unlockvar s:lmarks_nlist
unlockvar s:gmarks_nlist
let s:lmarks_nlist = split(g:lmarks_names, '\zs')
let s:gmarks_nlist = split(g:gmarks_names, '\zs')
lockvar s:lmarks_nlist
lockvar s:gmarks_nlist


" }}}1

" Highlighting {{{1
" Highlighting: Setup some nice colours to show the mark positions.
hi default MarkologyHLl ctermfg=green ctermbg=black cterm=bold guifg=green guibg=black
hi default MarkologyHLLine cterm=underline gui=undercurl guisp=#007777
hi default MarkologyHLu ctermfg=green ctermbg=black cterm=bold guifg=green guibg=black
hi default MarkologyHLo ctermfg=green ctermbg=black cterm=bold guifg=green guibg=black
hi default MarkologyHLm ctermfg=green ctermbg=black cterm=bold guifg=green guibg=black
" }}}1

" Private Functions {{{1

" (ShowMarks) {{{2

" Function: GetMarkLine()
" Authors: Easwy Yang
" Description: This function will return the line number where the mark
" placed. In VIM 7.0 and later, function line() always returns line number but
" not 0 in case an uppercase mark or number mark is placed. However, in VIM 6,
" it only returns 0 when the uppercase mark isn't placed in current file.
fun! s:GetMarkLine(mark)
    if v:version < 700
        let lnum = line(a:mark)
    else
        let pos = getpos(a:mark)
        let lnum = pos[1]
        if pos[0] && bufnr("%") != pos[0]
            let lnum = 0
        endif
    endif
    return lnum
endf

" Function: IncludeMarks()
" Description: This function returns the list of marks (in priority order) to
" show in this buffer.  Each buffer, if not already set, inherits the global
" setting; if the global include marks have not been set; that is set to the
" default value.
fun! s:IncludeMarks()
    if exists('b:markology_include') && exists('b:markology_previous_include') && b:markology_include != b:markology_previous_include
        " The user changed the marks to include; hide all marks; change the
        " included mark list, then show all marks.  Prevent infinite
        " recursion during this switch.
        if exists('s:use_previous_include')
            " Recursive call from MarkologyHideAll()
            return b:markology_previous_include
        elseif exists('s:use_new_include')
            " Recursive call from Markology()
            return b:markology_include
        else
            let s:use_previous_include = 1
            call markology#MarkologyHideAll()
            unlet s:use_previous_include
            let s:use_new_include = 1
            call markology#Markology()
            unlet s:use_new_include
        endif
    endif

    if !exists('g:markology_include')
        let g:markology_include = s:all_marks
    endif
    if !exists('b:markology_include')
        let b:markology_include = g:markology_include
    endif

    " Save this include setting so we can detect if it was changed.
    let b:markology_previous_include = b:markology_include

    return b:markology_include
endf

" Function: NameOfMark()
" Paramaters: mark - Specifies the mark to find the name of.
" Description: Convert marks that cannot be used as part of a variable name to
" something that can be. i.e. We cannot use [ as a variable-name suffix (as
" in 'placed_['; this function will return something like 63, so the variable
" will be something like 'placed_63').
" 10 is added to the mark's index to avoid colliding with the numeric marks
" 0-9 (since a non-word mark could be listed in markology_include in the
" first 10 characters if the user overrides the default).
" Returns: The name of the requested mark.
fun! s:NameOfMark(mark)
    let name = a:mark
    if a:mark =~# '\W'
        let name = stridx(s:all_marks, a:mark) + 10
    endif
    return name
endf

" Function: VerifyText()
" Paramaters: which - Specifies the variable to verify.
" Description: Verify the validity of a markology_text{upper,lower,other} setup variable.
" Default to ">" if it is found to be invalid.
fun! s:VerifyText(which)
    if strlen(g:markology_text{a:which}) == 0 || strlen(g:markology_text{a:which}) > 2
        echohl ErrorMsg
        echo "Markology: text".a:which." must contain only 1 or 2 characters."
        echohl None
        let g:markology_text{a:which}=">"
    endif
endf

" Function: MarkologySetup()
" Description: This function sets up the sign definitions for each mark.
" It uses the markology_textlower, markology_textupper and markology_textother
" variables to determine how to draw the mark.
fun! s:MarkologySetup()
    " Make sure the textlower, textupper, and textother options are valid.
    call s:VerifyText('lower')
    call s:VerifyText('upper')
    call s:VerifyText('other')

    let n = 0
    let s:maxmarks = strlen(s:all_marks)
    while n < s:maxmarks
        let c = strpart(s:all_marks, n, 1)
        let nm = s:NameOfMark(c)
        let text = '>'.c
        let lhltext = ''
        if c =~# '[a-z]'
            if strlen(g:markology_textlower) == 1
                let text=c.g:markology_textlower
            elseif strlen(g:markology_textlower) == 2
                let t1 = strpart(g:markology_textlower,0,1)
                let t2 = strpart(g:markology_textlower,1,1)
                if t1 == "\t"
                    let text=c.t2
                elseif t2 == "\t"
                    let text=t1.c
                else
                    let text=g:markology_textlower
                endif
            endif
            let s:MarkologyDLink{nm} = 'MarkologyHLl'
            if g:markology_hlline_lower
                " let lhltext = 'linehl='.s:MarkologyDLink{nm}.nm
                let lhltext = 'linehl=MarkologyHLLine'
            else
                let lhltext = 'linehl=Normal'
            endif
        elseif c =~# '[A-Z]'
            if strlen(g:markology_textupper) == 1
                let text=c.g:markology_textupper
            elseif strlen(g:markology_textupper) == 2
                let t1 = strpart(g:markology_textupper,0,1)
                let t2 = strpart(g:markology_textupper,1,1)
                if t1 == "\t"
                    let text=c.t2
                elseif t2 == "\t"
                    let text=t1.c
                else
                    let text=g:markology_textupper
                endif
            endif
            let s:MarkologyDLink{nm} = 'MarkologyHLu'
            if g:markology_hlline_upper
                " let lhltext = 'linehl='.s:MarkologyDLink{nm}.nm
                let lhltext = 'linehl=MarkologyHLLine'
            endif
        else " Other signs, like ', ., etc.
            if strlen(g:markology_textother) == 1
                let text=c.g:markology_textother
            elseif strlen(g:markology_textother) == 2
                let t1 = strpart(g:markology_textother,0,1)
                let t2 = strpart(g:markology_textother,1,1)
                if t1 == "\t"
                    let text=c.t2
                elseif t2 == "\t"
                    let text=t1.c
                else
                    let text=g:markology_textother
                endif
            endif
            let s:MarkologyDLink{nm} = 'MarkologyHLo'
            if g:markology_hlline_other == 1
                " let lhltext = 'linehl='.s:MarkologyDLink{nm}.nm
                let lhltext = 'linehl=MarkologyHLLine'
            endif
        endif

        " Define the sign with a unique highlight which will be linked when placed.
        exe 'sign define ShowMark'.nm.' '.lhltext.' text='.text.' texthl='.s:MarkologyDLink{nm}.nm
        let b:MarkologyLink{nm} = ''
        let n = n + 1
    endw
endf

" Function: MarkologyStart
" Description: Enable markology, and show them now.
function! s:SetMarkologyStatus(state)
    if a:state
        let g:markology_enable = 1
        call markology#Markology()
        aug Markology
            au!
            autocmd CursorHold * call markology#Markology()
            autocmd BufNewFile,Bufread * call markology#Markology()
        aug END
        echo "Markology enabled"
    else
        let g:markology_enable = 0
        call markology#MarkologyHideAll()
        aug Markology
            au!
            autocmd BufEnter * call markology#MarkologyHideAll()
        aug END
        echo "Markology disabled"
    endif
endfunction!

" }}}2

" (vim-mark-tools) {{{2

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Following is hacked in from vim-mark-tools
" Toggle and navigate bookmarks
" Last Change: $HGLastChangedDate$
" URL:	http://www.vim.org/scripts/script.php?script_id=2929
"	https://bitbucket.org/khorser/vim-mark-tools
"	https://github.com/khorser/vim-mark-tools
" Maintainer:  Sergey Khorev <sergey.khorev@gmail.com>

function! s:LocalMarkList()
    return map(copy(s:marks_nlist), '[v:val, line("''" . v:val)]')
endfunction

function! s:MarksAt(pos)
  return join(map(filter(s:LocalMarkList(), 'v:val[1]==' . a:pos), 'v:val[0]'), '')
endfunction

function! s:UsedMarks()
  return join(map(s:LocalMarkList(), '(v:val[1]>0 ? v:val[0] : " ")'),'')
endfunction

function! s:NextLocalMark(pos)
    let l:mark = ''
    let l:pos = 0
    let l:dist = 0
    for m in s:LocalMarkList()
        if m[1] > a:pos && (l:pos == 0 || m[1] - a:pos < l:dist)
            let l:mark = m[0]
            let l:pos = m[1]
            let l:dist = m[1] - a:pos
        endif
    endfor
    return l:mark
endfunction

function! s:PrevLocalMark(pos)
    let l:mark = ''
    let l:pos = 0
    let l:dist = 0
    for m in s:LocalMarkList()
        if m[1] > 0 && m[1] < a:pos && (l:pos == 0 || a:pos - m[1] < l:dist)
            let l:mark = m[0]
            let l:pos = m[1]
            let l:dist = a:pos - m[1]
        endif
    endfor
    return l:mark
endfunction

function! s:NextLocalMarkAlpha(mark)
    let l:index = char2nr(a:mark) - char2nr(s:marks_names[0])
    for m in s:LocalMarkList()[l:index + 1:]
        if m[1] > 0
            return m[0]
        endif
    endfor
    return ''
endfunction

function! s:PrevLocalMarkAlpha(mark)
    let l:index = char2nr(s:marks_names[s:marks_count-1]) - char2nr(a:mark)
    for m in reverse(s:LocalMarkList())[l:index + 1:]
        if m[1] > 0
            return m[0]
        endif
    endfor
    return ''
endfunction

function! s:GetWrapSearch()
    let l:wrap = 1
    if exists('w:markology_local_marks_wrap_search')
        let l:wrap = w:markology_local_marks_wrap_search
    elseif exists('b:markology_local_marks_wrap_search')
        let l:wrap = b:markology_local_marks_wrap_search
    elseif exists('g:markology_local_marks_wrap_search')
        let l:wrap = g:markology_local_marks_wrap_search
    end
    if l:wrap < 0
        return &wrapscan
    elseif l:wrap == 0
        return 0
    else
        return 1
    endif
endfunction

function! s:CreateMarkEntry(mark)
    let [buf, lnum, col, off] = getpos("'" . a:mark)
    let lines = getbufline(buf, lnum)
    if buf == 0
        return {'lnum': 0}
    else
        return {'bufnr': buf, 'lnum': lnum, 'col': col, 'type': 'M',
                    \'text': a:mark . ': ' . (empty(lines) ? '' : lines[0])}
    endif
endfunction

" function! g:NonMarkQFEntries()
"     return filter(getqflist(), 'v:val.type !=? "m"')
" endfunction

" function! g:NonMarkLocEntries(winnr)
"     return filter(getloclist(a:winnr), 'v:val.type !=? "m"')
" endfunction

" }}}2

" }}}1

" Public Functions {{{1

" (ShowMarks) {{{2

" Function: MarkologyEnable
" Description: Enable markology, and show them now.
fun! markology#MarkologyEnable()
    call <sid>SetMarkologyStatus(1)
endf

" Function: MarkologyDisable
" Description: Disable markology and hide signs.
fun! markology#MarkologyDisable()
    call <sid>SetMarkologyStatus(0)
endf

" Function: MarkologyToggle()
" Description: This function toggles whether marks are displayed or not.
fun! markology#MarkologyToggle()
    if g:markology_enable
        call <sid>SetMarkologyStatus(0)
    else
        call <sid>SetMarkologyStatus(1)
    endif
endf

" Function: Markology()
" Description: This function runs through all the marks and displays or
" removes signs as appropriate. It is called on the CursorHold autocommand.
" We use the marked_{ln} variables (containing a timestamp) to track what marks
" we've shown (placed) in this call to Markology; to only actually place the
" first mark on any particular line -- this forces only the first mark
" (according to the order of markology_include) to be shown (i.e., letters
" take precedence over marks like paragraph and sentence.)
fun! markology#Markology()
    if g:markology_enable == 0
        return
    endif

    if   ((match(g:markology_ignore_type, "[Hh]") > -1) && (&buftype    == "help"    ))
    \ || ((match(g:markology_ignore_type, "[Qq]") > -1) && (&buftype    == "quickfix"))
    \ || ((match(g:markology_ignore_type, "[Pp]") > -1) && (&pvw        == 1         ))
    \ || ((match(g:markology_ignore_type, "[Rr]") > -1) && (&readonly   == 1         ))
    \ || ((match(g:markology_ignore_type, "[Mm]") > -1) && (&modifiable == 0         ))
        return
    endif

    let n = 0
    let s:maxmarks = strlen(s:IncludeMarks())
    while n < s:maxmarks
        let c = strpart(s:IncludeMarks(), n, 1)
        let nm = s:NameOfMark(c)
        let id = n + (s:maxmarks * winbufnr(0))
        "let ln = line("'".c)
        let ln = s:GetMarkLine("'".c)

        if ln == 0 && (exists('b:placed_'.nm) && b:placed_{nm} != ln)
            exe 'sign unplace '.id.' buffer='.winbufnr(0)
        elseif ln >= 1 || c !~ '[a-zA-Z]'
            " Have we already placed a mark here in this call to Markology?
            if exists('mark_at'.ln)
                " remove old sign if there is one
                if exists('b:placed_'.nm)
                    exe 'sign unplace '.id.' buffer='.winbufnr(0)
                    unlet b:placed_{nm}
                endif

                " Already placed a mark, set the highlight to multiple
                if c =~# '[a-zA-Z]' && b:MarkologyLink{mark_at{ln}} != 'MarkologyHLm'
                    let b:MarkologyLink{mark_at{ln}} = 'MarkologyHLm'
                    exe 'hi link '.s:MarkologyDLink{mark_at{ln}}.mark_at{ln}.' '.b:MarkologyLink{mark_at{ln}}
                endif
            else
                if !exists('b:MarkologyLink'.nm) || b:MarkologyLink{nm} != s:MarkologyDLink{nm}
                    let b:MarkologyLink{nm} = s:MarkologyDLink{nm}
                    exe 'hi link '.s:MarkologyDLink{nm}.nm.' '.b:MarkologyLink{nm}
                endif
                let mark_at{ln} = nm
                if !exists('b:placed_'.nm) || b:placed_{nm} != ln
                    exe 'sign unplace '.id.' buffer='.winbufnr(0)
                    if ln != 0
                        exe 'sign place '.id.' name=ShowMark'.nm.' line='.ln.' buffer='.winbufnr(0)
                        let b:placed_{nm} = ln
                    else
                        if exists('b:placed_'.nm)
                            unlet b:placed_{nm}
                        endif
                    endif
                endif
            endif
        endif
        let n = n + 1
    endw
endf

" Function: MarkologyClearMark()
" Description: This function hides the mark at the current line.
" It simply moves the mark to line 1 and removes the sign.
" Only marks a-z and A-Z are supported.
fun! markology#MarkologyClearMark()
    let ln = line(".")
    let n = 0
    let s:maxmarks = strlen(s:IncludeMarks())
    while n < s:maxmarks
        let c = strpart(s:IncludeMarks(), n, 1)
        "if c =~# '[a-zA-Z]' && ln == line("'".c)
        if c =~# '[a-zA-Z]' && ln == s:GetMarkLine("'".c)
            let nm = s:NameOfMark(c)
            let id = n + (s:maxmarks * winbufnr(0))
            exe 'sign unplace '.id.' buffer='.winbufnr(0)
            " Easwy, we can really remove marks in VIM 7.0 and later
            if v:version >= 700
                exe 'delm '.c
            else
                exe '1 mark '.c
            endif
            echo "Mark '" . c . "' removed from line " . string(line("."))
            " Easwy, end
            let b:placed_{nm} = 1
        endif
        let n = n + 1
    endw
endf

" Function: MarkologyClearAll()
" Description: This function clears all marks in the buffer.
" It simply moves the marks to line 1 and removes the signs.
" Only marks a-z and A-Z are supported.
fun! markology#MarkologyClearAll()
    let n = 0
    let s:maxmarks = strlen(s:IncludeMarks())
    while n < s:maxmarks
        let c = strpart(s:IncludeMarks(), n, 1)
        if c =~# '[a-zA-Z]'
            let nm = s:NameOfMark(c)
            let id = n + (s:maxmarks * winbufnr(0))
            exe 'sign unplace '.id.' buffer='.winbufnr(0)
            " Easwy, we can really remove marks in VIM 7.0 and later
            if v:version >= 700
                exe 'delm '.c
            else
                exe '1 mark '.c
            endif
            " Easwy, end
            let b:placed_{nm} = 1
        endif
        let n = n + 1
    endw
    echo "All marks cleared"
endf

" Function: MarkologyHideAll()
" Description: This function hides all marks in the buffer.
" It simply removes the signs.
fun! markology#MarkologyHideAll()
    let n = 0
    let s:maxmarks = strlen(s:IncludeMarks())
    while n < s:maxmarks
        let c = strpart(s:IncludeMarks(), n, 1)
        let nm = s:NameOfMark(c)
        if exists('b:placed_'.nm)
            let id = n + (s:maxmarks * winbufnr(0))
            exe 'sign unplace '.id.' buffer='.winbufnr(0)
            unlet b:placed_{nm}
        endif
        let n = n + 1
    endw
endf

" Function: MarkologyPlaceMark()
" Description: This function will place the next unplaced mark (in priority
" order) to the current location. The idea here is to automate the placement
" of marks so the user doesn't have to remember which marks are placed or not.
" Hidden marks are considered to be unplaced.
" Only marks a-z are supported.
fun! markology#MarkologyPlaceMark()
    " Find the first, next, and last [a-z] mark in markology_include (i.e.
    " priority order), so we know where to "wrap".
    let first_alpha_mark = -1
    let last_alpha_mark  = -1
    let next_mark        = -1

    if !exists('b:previous_auto_mark')
        let b:previous_auto_mark = -1
    endif

    " Find the next unused [a-z] mark (in priority order); if they're all
    " used, find the next one after the previously auto-assigned mark.
    let n = 0
    let s:maxmarks = strlen(s:IncludeMarks())
    while n < s:maxmarks
        let c = strpart(s:IncludeMarks(), n, 1)
        if c =~# '[a-z]'
            "if line("'".c) <= 1
            if s:GetMarkLine("'".c) <= 1
                " Found an unused [a-z] mark; we're done.
                let next_mark = n
                break
            endif

            if first_alpha_mark < 0
                let first_alpha_mark = n
            endif
            let last_alpha_mark = n
            if n > b:previous_auto_mark && next_mark == -1
                let next_mark = n
            endif
        endif
        let n = n + 1
    endw

    if next_mark == -1 && (b:previous_auto_mark == -1 || b:previous_auto_mark == last_alpha_mark)
        " Didn't find an unused mark, and haven't placed any auto-chosen marks yet,
        " or the previously placed auto-chosen mark was the last alpha mark --
        " use the first alpha mark this time.
        let next_mark = first_alpha_mark
    endif

    if (next_mark == -1)
        echohl WarningMsg
        echo 'No marks in [a-z] included! (No "next mark" to choose from)'
        echohl None
        return
    endif

    let c = strpart(s:IncludeMarks(), next_mark, 1)
    let b:previous_auto_mark = next_mark
    exe 'mark '.c
    echo "Mark '" . c . "' placed at line " . string(line("."))
    call markology#Markology()
endf

" }}}2

" (vim-mark-tools) {{{2

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Following is hacked in from vim-mark-tools
" Toggle and navigate bookmarks
" Last Change: $HGLastChangedDate$
" URL:	http://www.vim.org/scripts/script.php?script_id=2929
"	https://bitbucket.org/khorser/vim-mark-tools
"	https://github.com/khorser/vim-mark-tools
" Maintainer:  Sergey Khorev <sergey.khorev@gmail.com>

function! markology#MarkologyNextByPos()
    let l:mark = s:NextLocalMark(line('.'))
    if empty(l:mark) && s:GetWrapSearch()
        let l:mark = s:NextLocalMark(0)
    endif
    if !empty(l:mark)
        exec ':''' . l:mark
    endif
endfunction

function! markology#MarkologyPrevByPos()
    let l:mark = s:PrevLocalMark(line('.'))
    if empty(l:mark) && s:GetWrapSearch()
        let l:mark = s:PrevLocalMark(line('$')+1)
    endif
    if !empty(l:mark)
        exec ':''' . l:mark
    endif
endfunction

function! markology#MarkologyNextByAlpha()
    let l:marks_here = s:MarksAt(line('.'))
    if !empty(l:marks_here)
        let l:mark = s:NextLocalMarkAlpha(l:marks_here[strlen(l:marks_here)-1])
        if empty(l:mark) && s:GetWrapSearch()
            let l:mark = s:NextLocalMarkAlpha(nr2char(char2nr(s:marks_names[0])-1))
        endif
        if !empty(l:mark)
            exec ':''' . l:mark
        endif
    endif
endfunction

function! markology#MarkologyPrevByAlpha()
    let l:marks_here = s:MarksAt(line('.'))
    if !empty(l:marks_here)
        let l:mark = s:PrevLocalMarkAlpha(l:marks_here[0])
        if empty(l:mark) && s:GetWrapSearch()
            let l:mark = s:PrevLocalMarkAlpha(nr2char(char2nr(s:marks_names[s:marks_count-1])+1))
        endif
        if !empty(l:mark)
            exec ':''' . l:mark
        endif
    endif
endfunction

function! markology#MarkologyPlaceMarkToggle()
  let l:marks_here = s:MarksAt(line('.'))
  if !empty(l:marks_here)
      call markology#MarkologyClearMark()
  else
      call markology#MarkologyPlaceMark()
  endif
endfunction

function! markology#MarkologyMarksQuickFix()
    call setqflist(
                \filter(
                \map(
                \copy(s:gmarks_nlist), 's:CreateMarkEntry(v:val)'),
                \'v:val.lnum > 0'))
    copen
endfunction

function! markology#MarkologyMarksLocationList()
    call setloclist(0,
                \filter(
                \map(
                \copy(s:lmarks_nlist),
                \'{"bufnr": bufnr("%"), "lnum": line("''" . v:val), "col": col("''" . v:val),
                \"type": "m", "text": v:val . ": " . getline(line("''" . v:val))}'),
                \'v:val.lnum > 0'))
    lopen
    if !exists("g:markology_set_location_list_convenience_maps") || g:markology_set_location_list_convenience_maps
        nnoremap <buffer> <silent> q        :q<CR>
        noremap  <buffer> <silent> <ESC>    :q<CR>
        noremap  <buffer> <silent> <ENTER>  <CR>:lcl<CR>
    endif
endfunction


" }}}2

" Other {{{2
function! markology#MarkologyLineHighlightToggle()
    let g:markology_hlline_lower = !g:markology_hlline_lower
    call s:MarkologySetup()
endfunction
" }}}2

" }}}1

" Setup {{{1
" Set things up
call s:MarkologySetup()
" }}}1

" Restore State {{{1
" ============================================================================
" restore options
let &cpo = s:save_cpo
" }}}1
