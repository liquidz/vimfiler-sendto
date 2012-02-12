"
" Send to plugin for vimfiler
"
" Version: 0.0.1
" Author:  Masashi Iizuka (@uochan)
"

let s:save_cpo = &cpo
set cpo&vim

let s:unite_sources = { 'name' : 'sendto' }

function! s:make_command(command)
    let cursor_linenr = get(a:000, 0, line('.'))
    let vimfiler = vimfiler#get_current_vimfiler()
    let marked_files = vimfiler#get_marked_files()
    if empty(marked_files)
        let marked_files = [ vimfiler#get_file(cursor_linenr) ]
    endif

    let command_list = map(marked_files, '
\       a:command . " " . v:val.action__path'
\   )

    return '!' . join(command_list, '; ')
endfunction

function! s:unite_sources.gather_candidates(args, context)
    let sendto = copy(g:vimfiler_sendto)
    return map(keys(sendto), '{
\       "word" : v:val
\     , "source" : "sendto"
\     , "kind" : "command"
\     , "action__command" : s:make_command(sendto[v:val])
\   }')
endfunction

function! unite#sources#sendto#define()
    return s:unite_sources
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

