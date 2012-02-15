"
" Send to plugin for vimfiler
"
" Version: 0.0.6
" Author:  Masashi Iizuka (@uochan)
"

let s:save_cpo = &cpo
set cpo&vim

let s:unite_sources = { 'name' : 'sendto', 'hooks' : {} }

" ワイルドカードが存在するか
function! s:has_wildcard(command)
    let has_wildcard = 0
    for s in ['%d', '%p', '%f', '%F', '%*', '%#']
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
    " ワイルドカードがなければ末尾にファイル名を付加する
    if ! s:has_wildcard(a:command)
        let cmd = cmd . ' %f'
    endif

    let cmd = substitute(cmd, '%d', b:vimfiler.current_dir, 'g')
    let cmd = substitute(cmd, '%p', a:filepath, 'g')

    if !empty(a:filepath) && (stridx(cmd, '%f') != -1 || stridx(cmd, '%F') != -1)
        let filename = fnamemodify(a:filepath, ':t')
        let cmd = substitute(cmd, '%f', filename, 'g')
        " 拡張子を抜いたファイル名
        let cmd = substitute(cmd, '%F', fnamemodify(filename, ':r'), 'g')
    endif

    " ignorecaseの設定を戻す
    if ignorecase
        set ignorecase
    endif

    return cmd
endfunction

" マークされたファイルリストをワイルドカードとして展開する
"   %* : マークされたファイルのファイル名をスペース区切りで展開
"   %# : マークされたファイルのフルパスをスペース区切りで展開
function! s:expand_filelist(command, marked_files)
    let cmd = a:command
    let files = map(a:marked_files, 'v:val.action__path')
    let names = map(copy(files), 'fnamemodify(v:val, ":t")')
    let cmd = substitute(cmd, '%[#]', join(files, ' '), 'g')
    let cmd = substitute(cmd, '%[*]', join(names, ' '), 'g')
    " マークされたファイルの全展開があれば
    " 先頭のマークファイルのファイル名でワイルドカード展開する
    if s:has_wildcard(cmd)
        let cmd = s:replace_subwildcard(cmd, files[0])
    endif

    return cmd
endfunction

" コマンド文字列を実行可能な形式に変換
function! s:make_command(command)
    let cmd = a:command
    let cursor_linenr = get(a:000, 0, line('.'))
    let vimfiler = vimfiler#get_current_vimfiler()
    let sep = has('win32') ? ' &' : ';'
    " 別プロセスで実行するかどうか(windowsはどちらにしても別プロセスだから無視)
    let is_bgrun = stridx(cmd, '&') != -1 && !has('win32')
    " ワイルドカード展開の邪魔にならないよう一時的に削除しておく
    let cmd = substitute(cmd, '&', '', 'g')

    " マークされているファイルリストを取得
    " マークがない場合はカーソルのあたっているファイルを選択
    let marked_files = vimfiler#get_marked_files()
    if empty(marked_files)
        let marked_files = [ vimfiler#get_file(cursor_linenr) ]
    endif

    if stridx(cmd, '%*') != -1 || stridx(cmd, '%#') != -1
        let command_list = [ s:expand_filelist(cmd, marked_files) ]
    else
        let command_list = map(marked_files, '
\           s:replace_subwildcard(cmd, v:val.action__path)
\       ')
    endif

    let cmd = '!' . join(command_list, sep . ' ')
    let cmd = cmd . (is_bgrun ? '&' : '')
    return cmd
endfunction

" unite.vimの候補を生成
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

