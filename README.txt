
Markology provides for the visualization, navigation, and management of Vim's
(marks).  Visualization is through use of Vim's 'sign' feature, and so use of
this plugin requires that Vim be compiled with the 'sign' option.

Markology displays marks associated with the current line in the sign column or
gutter of the window displaying the buffer (with the entire line highlighted
in a different color, if so desired).  You can easily add ('\m+'), delete
('\m-'), or toggle ('\m=') marks associated with the current line.  You can
easily jump through the sequence of all the local marks in the buffer, either
spatially ('\m]' and '\m[') or lexicographically ('\m}' and '\m{').  You can
also easily display all current marks in the location list window ('\ml') or
the quickfix window ('\mq').

Detailed usage description given in the help file, which can be viewed on-line
here:

    http://github.com/jeetsukumaran/vim-markology/blob/master/doc/markology.txt

Source code repository can be found here:

    http://github.com/jeetsukumaran/vim-markology

Markology is a Frankenstein-ian beast that cobbles together:

    1.  ShowMarks

            ShowMarks - Visually show the location of marks
            Version 2.2 (2004-08-06)
            http://www.vim.org/scripts/script.php?script_id=152
            By Anthony Kruize <trandor@labyrinth.net.au>
            Michael Geddes <michaelrgeddes@optushome.com.au>

    2.  The patch for the above, as given here:

            http://easwy.com/blog/archives/advanced-vim-skills-advanced-move-method/

        which fixes the issue of global marks showing up in files in which they
        were *not* declared.

    3. Mark_Tools

            mark_tools : Toggle and navigate marks
            Sergey Khorev <sergey.khorev@gmail.com>

            http://www.vim.org/scripts/script.php?script_id=2929
            https://bitbucket.org/khorser/vim-mark-tools
            https://github.com/khorser/vim-mark-tools

Like "ShowMarks", Markology provides visual representation of |marks| local to a
buffer by placing a |sign| in the leftmost column of the buffer indicating the
label of the mark and its location.

Markology is activated by the |CursorHold| |autocommand| which is triggered
every |updatetime| milliseconds.  This is set to 4000(4 seconds) by default.
If this is too slow, setting it to a lower value will make it more responsive.

Like "Mark_Tools", Markology provides commands and keymaps for navigating
between |marks| and listing/viewing  |marks| .

Note: This plugin requires Vim 6.x compiled with the |+signs| feature.

