"
" Send to plugin for vimfiler
"
" Version: 0.0.2
" Author:  Masashi Iizuka (@uochan)
"

let s:save_cpo = &cpo
set cpo&vim

let s:unite_sources = { 'name' : 'sendto' }

" ワイルドカードが存在するか
function! s:has_wildcard(command)
    let has_wildcard = 0
    for s in ['%d', '%f', '%n', '%N']
        if stridx(a:command, s) != -1
            let has_wildcard = 1
        endif
    endfor

    return has_wildcard
endfunction

" リストの最後の値を返す
function! s:last(arr)
    return a:arr[len(a:arr) - 1]
endfunction

" ファイル名から拡張子を除く
function! s:except_extention(filename)
    if(stridx(a:filename, '.') == -1)
        return a:filename
    else
        let name = split(a:filename, '[.]')
        return join(name[0:len(name) - 2], '.')
    endif
endfunction

" ファイルパスからファイル名への変換
function! s:filepath_to_filename(filepath)
    let sep = has('win32') ? '\' : '/'
    return s:last(split(a:filepath, sep))
endfunction

" サブのワイルドカードを変換
"   %d : カレントディレクトリ
"   %f : マークされたファイルのフルパス
"   %n : マークされたファイルのファイル名
"   %N : マークされたファイルの拡張子を除いたファイル名
function! s:replace_subwildcard(command, filepath)
    " ワイルドカードの大文字小文字を区別したいので一時的に noignorecase にする
    let ignorecase = &ignorecase
    set noignorecase

    let cmd = a:command
    if ! s:has_wildcard(a:command)
        let cmd = cmd . ' %f'
    endif

    let cmd = substitute(cmd, '%d', b:vimfiler.current_dir, 'g')
    let cmd = substitute(cmd, '%f', a:filepath, 'g')

    if !empty(a:filepath) && (stridx(cmd, '%n') != -1 || stridx(cmd, '%N') != -1)
        let filename = s:filepath_to_filename(a:filepath)
        let cmd = substitute(cmd, '%n', filename, 'g')
        let cmd = substitute(cmd, '%N', s:except_extention(filename), 'g')
    endif

    " ignorecaseの設定を戻す
    if ignorecase
        set ignorecase
    endif

    return cmd
endfunction

" コマンド文字列を実行可能な形式に変換
"   %* : マークされたファイルをスペース区切りで展開
function! s:make_command(command)
    let cursor_linenr = get(a:000, 0, line('.'))
    let vimfiler = vimfiler#get_current_vimfiler()
    let marked_files = vimfiler#get_marked_files()
    if empty(marked_files)
        let marked_files = [ vimfiler#get_file(cursor_linenr) ]
    endif

    if stridx(a:command, '%*') != -1
        " マークされたファイルの全展開があればファイル毎のワイルドカード展開はしない
        let files = join(map(marked_files, 'v:val.action__path'), ' ')
        let command_list = [ s:replace_subwildcard(substitute(a:command, '%[*]', files, 'g'), '') ]
    else
        let command_list = map(marked_files, '
\           s:replace_subwildcard(a:command, v:val.action__path)
\       ')
    endif

    return '!' . join(command_list, '; ') . ' &'
endfunction

" unite.vimのソースを生成
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

