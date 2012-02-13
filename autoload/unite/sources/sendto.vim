"
" Send to plugin for vimfiler
"
" Version: 0.0.3
" Author:  Masashi Iizuka (@uochan)
"

let s:save_cpo = &cpo
set cpo&vim

let s:unite_sources = { 'name' : 'sendto', 'hooks' : {} }

" ワイルドカードが存在するか
function! s:has_wildcard(command)
    let has_wildcard = 0
    for s in ['%d', '%p', '%f', '%F']
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
"   %p : マークされたファイルのフルパス
"   %f : マークされたファイルのファイル名
"   %F : マークされたファイルの拡張子を除いたファイル名
function! s:replace_subwildcard(command, filepath)
    " ワイルドカードの大文字小文字を区別したいので一時的に noignorecase にする
    let ignorecase = &ignorecase
    set noignorecase

    let cmd = a:command
    if ! s:has_wildcard(a:command)
        let cmd = cmd . ' %f'
    endif

    let cmd = substitute(cmd, '%d', b:vimfiler.current_dir, 'g')
    let cmd = substitute(cmd, '%p', a:filepath, 'g')

    if !empty(a:filepath) && (stridx(cmd, '%f') != -1 || stridx(cmd, '%F') != -1)
        let filename = s:filepath_to_filename(a:filepath)
        let cmd = substitute(cmd, '%f', filename, 'g')
        let cmd = substitute(cmd, '%F', s:except_extention(filename), 'g')
    endif

    " ignorecaseの設定を戻す
    if ignorecase
        set ignorecase
    endif

    return cmd
endfunction

" コマンド文字列を実行可能な形式に変換
"   %* : マークされたファイルのファイル名をスペース区切りで展開
"   %# : マークされたファイルのフルパスをスペース区切りで展開
function! s:make_command(command)
    let cursor_linenr = get(a:000, 0, line('.'))
    let vimfiler = vimfiler#get_current_vimfiler()
    let marked_files = vimfiler#get_marked_files()
    if empty(marked_files)
        let marked_files = [ vimfiler#get_file(cursor_linenr) ]
    endif

    if stridx(a:command, '%*') != -1 || stridx(a:command, '%#') != -1
        let files = map(marked_files, 'v:val.action__path')
        let names = map(copy(files), 's:filepath_to_filename(v:val)')
        let command_str = substitute(a:command, '%[#]', join(files, ' '), 'g')
        let command_str = substitute(command_str, '%[*]', join(names, ' '), 'g')
        " マークされたファイルの全展開があれば先頭のマークファイルのファイル名でワイルドカード展開する
        if s:has_wildcard(command_str)
            let command_str = s:replace_subwildcard(command_str, files[0])
        endif

        let command_list = [ command_str ]
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

function! s:unite_sources.hooks.on_init(args, context)
    " カレントディレクトリをvimfilerに合わせる
    execute 'lcd ' . b:vimfiler.current_dir
endfunction

function! unite#sources#sendto#define()
    return s:unite_sources
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

