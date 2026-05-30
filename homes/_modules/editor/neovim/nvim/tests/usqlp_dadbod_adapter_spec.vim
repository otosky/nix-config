set rtp^=~/.local/share/nvim/lazy/vim-dadbod
set rtp^=homes/_modules/editor/neovim/nvim
runtime autoload/db/adapter/usqlp.vim

function! s:assert_equal(expected, actual) abort
  if a:expected !=# a:actual
    throw 'expected ' . string(a:expected) . ', got ' . string(a:actual)
  endif
endfunction

call s:assert_equal('usqlp:local_postgres', db#adapter#usqlp#canonicalize('usqlp:local_postgres'))
call s:assert_equal('usqlp:conn%20name', db#adapter#usqlp#canonicalize('usqlp:conn%20name'))
call s:assert_equal('sql', db#adapter#usqlp#input_extension())
call s:assert_equal('csv', db#adapter#usqlp#output_extension())
call s:assert_equal(['usqlp', 'local_postgres', '--csv', '-f', '/tmp/query.sql'], db#adapter#usqlp#input('usqlp:local_postgres', '/tmp/query.sql'))
call s:assert_equal(['usqlp', 'conn name', '--csv', '-f', '/tmp/query.sql'], db#adapter#usqlp#input('usqlp:conn%20name', '/tmp/query.sql'))
