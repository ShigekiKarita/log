---
title: "Hello Hugo"
date: 2019-04-29T12:56:42+09:00
draft: false
tags: ["D", "Hugo", "Travis CI", "gh-pages"]
isCJKLanguage: true
categories: ["Programming"]
---

3度目の正直で，最後のブログを始めました...．前は org-mode を使って構築したのですが，記事が多くなり1ページだと読みづらいし，カテゴリ分けやパーマリンク的な仕組みが欲しくなってしまいました．

> 以前のページ https://shigekikarita.github.io/journal.html

## Hugo への移行

巷ではHugoというGo言語製の静的サイト生成ツールが流行っていて，見た目もイケていて動作が軽いという噂でした．Go言語にも興味があったし，ox-hugoというツールを使えば org-mode から Hugo 用の markdown へ変換できて，公式に org-mode 自体もサポートされている (`markup="org"`) ということもあり移行を決めました．

> ox-hugo https://ox-hugo.scripter.co/

> https://gohugo.io/content-management/formats/

そんなわけで，Hugoには期待していたのですが，当HPのメインコンテンツ(?)であるD言語のコードブロックにシンタックスハイライトがなくガッカリしまいました．とはいえハイライトをするChromaというツールのソースコードがびっくりするほど綺麗だったので，Go言語は全く知識がなかったのですが，その日のうちにPRを送ってみました．

> https://github.com/alecthomas/chroma/pull/249

驚くほどすぐマージされました...！そのうち新バージョンがリリースされて Hugo 本家にもアップデートされると思いますが、とりあえずHugoをforkしてアップデートしてみました。

```d
// D language
module app;

import std.stdio;

/++ This is template +/
template A(T) {
    enum A = T.stringof;
}

/** This is main **/
void main() {
    writeln("Hello");
}
```

適当に作った割にはちゃんとハイライトされてますね．

## Travis CI

このサイトはgh-pages上でホストしているのですが，

https://shigekikarita.github.io/log/

```yaml
sudo: false
language: go
script:
  # install hugo
  - INIT_DIR=$(pwd)
  - mkdir $HOME/src
  - cd $HOME/src
  - git clone https://github.com/ShigekiKarita/hugo --depth 1 -b dlang
  - cd hugo
  - go install
  - cd $INIT_DIR
  # build page
  - $GOPATH/bin/hugo
  - touch public/.nojekyll

deploy:
  provider: pages
  skip_cleanup: true
  github_token: $GITHUB_TOKEN # Set in travis-ci.org dashboard
  local_dir: public
  on:
    branch: master
```

こんな風にTravisを設定してデプロイしたのがこのページできます．

- https://docs.travis-ci.com/user/deployment/pages/
- https://github.com/ShigekiKarita/hugo-test/blob/master/.travis.yml

それか，私が作ったLinux用バイナリを使うなら

```yaml
sudo: false
language: bash
script:
  - wget https://github.com/ShigekiKarita/hugo/releases/download/dlang-v1/hugo.tar.xz
  - tar -xvf hugo.tar.xz
  - ./hugo
  - touch public/.nojekyll

deploy:
  provider: pages
  skip_cleanup: true
  github_token: $GITHUB_TOKEN # Set in travis-ci.org dashboard
  local_dir: public
  on:
    branch: master
```

これで2分かかっていた Hugo 自体のビルド時間がなくなり，バイナリのDLだけになったので 30 sec 程度で markdown の push からサイトがビルドされました．以前、Jekyllを使っていたがどうもサイトの生成が遅かったので Hugo は素晴らしいですね．いまだに markdown よりも org-mode が好きなので，恋しくなったら ox-hugo 使ってみようと思いますが，結構手軽に書けるのでこのままでも良いかなと思ってます．

## Hugo の追加設定

Hugo の公式ドキュメントわかりにくい...けど有志の how-to が多くていいですね．

- Mathjax https://gohugo.io/content-management/formats/#enable-mathjax
- 選んだテーマ https://themes.gohugo.io/hugo-kiera/
- Google Analytics https://gohugo.io/templates/internal/#google-analytics
- 日本語情報 https://maku77.github.io/hugo/


\begin{align}
f(x) = x^2
\end{align}
