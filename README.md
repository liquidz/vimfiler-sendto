# sendto plugin for vimfiler

vimfilerにエクスプローラの「送る」のような機能を提供するプラグインです。

デフォルトでも!コマンドで外部コマンドを実行できますが、
毎回入力するのが面倒なのでunite.vimのIF上で選択できるようにしました。

## インストール

    NeoBundle 'git://github.com/liquidz/vimfiler-sendto.git'

## .vimrc 設定

    let g:vimfiler_sendto = {
    \   'unzip' : 'unzip'
    \ , 'Inkscape ベクターグラフィックエディタ' : 'inkspace'
    \ , 'GIMP 画像エディタ' : 'gimp'
    \ , 'gedit' : 'gedit'
    \ }

まだUbuntu上でしか確認していませんが、Windows環境でラベルとパスを
別々に定義したい状況がありそうなので辞書型での定義としています。

## vimfiler上での操作

起動

    :Unite sendto

ファイルがマークされていればそのファイルを、
マークされていなければカーソルのあたっているファイルを選択したコマンドで実行します
