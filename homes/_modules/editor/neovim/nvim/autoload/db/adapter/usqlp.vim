if exists('g:autoloaded_db_usqlp')
  finish
endif
let g:autoloaded_db_usqlp = 1

function! s:connection(url) abort
  let parsed = db#url#parse(a:url)
  if has_key(parsed, 'opaque')
    return db#url#decode(parsed.opaque)
  elseif has_key(parsed, 'host') && parsed.host !=# ''
    return parsed.host
  endif
  throw 'DB: usqlp URL requires a connection name'
endfunction

function! db#adapter#usqlp#canonicalize(url) abort
  return 'usqlp:' . db#url#encode(s:connection(a:url))
endfunction

function! db#adapter#usqlp#input_extension() abort
  return 'sql'
endfunction

function! db#adapter#usqlp#output_extension() abort
  return 'csv'
endfunction

function! db#adapter#usqlp#input(url, in) abort
  return ['usqlp', s:connection(a:url), '--csv', '-f', a:in]
endfunction
