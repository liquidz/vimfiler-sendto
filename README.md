# sendto plugin for vimfiler

vimfilerにエクスプローラの「送る」のような機能を提供するプラグインです。

デフォルトでも!コマンドで外部コマンドを実行できますが、
毎回入力するのが面倒なのでunite.vimのIF上で選択できるようにしました。

## インストール

    NeoBundle 'git://github.com/liquidz/vimfiler-sendto.git'

## .vimrc 設定

    let g:vimfiler_sendto = {
    \ , 'unzip' : 'unzip %f'
    \ , 'zip' : 'zip -r %F.zip %*'
    \ , 'Inkscape ベクターグラフィックエディタ' : 'inkspace'
    \ , 'GIMP 画像エディタ' : 'gimp %*'
    \ , 'gedit' : 'gedit'
    \ }

まだUbuntu上でしか確認していませんが、Windows環境でラベルとパスを
別々に定義したい状況がありそうなので辞書型での定義としています。

## .vimrc 設定で使えるワイルドカード

    %p : マークされたファイルのフルパス
    %d : カレントディレクトリ
    %f : マークされたファイルのファイル名
    %F : マークされたファイルの拡張子を除くファイル名
    %* : マークされたファイルのファイル名(スペース区切り)
    %# : マークされたファイルのフルパス(スペース区切り)

%*, %# を使用するかどうかでコマンドの展開のされ方が変わります

 - 指定あり
    gedit %* => !gedit foo.txt bar.txt &

 - 指定なし
    gedit %f => !gedit foo.txt; gedit bar.txt &

なお %*, %# を指定すると %f, %n, %N などファイル個別のワイルドカードは
最初にマークされたファイルで展開されます。

## vimfiler上での操作

起動

    :Unite sendto

ファイルがマークされていればそのファイルを、
マークされていなければカーソルのあたっているファイルを選択したコマンドで実行します
