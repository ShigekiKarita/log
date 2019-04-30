---
title: "Hugo + Org-Mode 執筆 Tips"
summary:
categories: ["Programming"]
tags: ["D", "Hugo", "Go", "org-mode"]
draft: false
date: 2019-04-30T12:57:29+09:00
author: "Shigeki Karita"
isCJKLanguage: true
markup: "md"
---

## tl;dr

ファイル `archetypes/default.md` に自分好みのテンプレを作ってボイラープレートを減らそう．最終的な `org-mode` 用の設定はこれ 

> https://raw.githubusercontent.com/ShigekiKarita/log/master/archetypes/default.org

## はじめに

以前 Jekyll や org-mode でブログ書いてた時によく思ってたのが，タイトルとか日付といった「属性」を書くヘッダー的な部分をもっとテンプレ化しておきたいということ．移行した Hugo ではヘッダー的な部分を「Front Matter」と読んでいて，ユーザ定義もできたり無限に属性がある．

https://gohugo.io/content-management/front-matter/

Hugo といえば markdown で書いている人が多いと思うのですが，ファイル `archetypes/default.md` に自分好みのテンプレを作ってボイラープレートを減らせます．

```bash
$ hugo new posts/xxx.md
```

みたいなコマンドで新しい記事を生成するとき，そのテンプレ `archetypes/default.md` が選ばれて，その中のプレースホルダーが置き換えられるらしい．

## 課題

org-mode でのテンプレを作る方法がよくわからない．例えば markdown では `archetypes/default.md` をこんな感じで設定しています．

```md
---
title: "{{ replace .Name "-" " " | title }}"
summary: ""
categories: ["uncategorized"]
tags: []
draft: true
date: {{ .Date }}
author: "Shigeki Karita"
isCJKLanguage: true
markup: "md"
---

## tl;dr

## reference
```

Front Matter の記法についてですが，ググると yaml/toml/json 色々でてきますが，おそらく yaml (`---` で区切られる) がいまの標準っぽい．余談だが `config.xxx` は toml が標準なのでどれでも良いから統一して欲しい．

https://gohugo.io/content-management/front-matter/#front-matter-formats

## 解決

色々しらべた結果， org-mode は markdown のような区切り文字ではなく，こんな感じで `archetypes/default.org` に設定できる．

```org
#+title: {{ replace .Name "-" " " | title }}
#+summary:
#+categories: uncategorized
#+tags:
#+draft: true
#+date: {{ .Date }}
#+author: Shigeki Karita
#+isCJKLanguage: true
#+markup: org

** tl;dr

** reference
```

どうやら org-mode 独自のヘッダーのようで，Front Matter 第四の記法というわけです．主な文法としては

- 文字列を引用符でくくらない．引用符もそのまま出力されてしまう
- tags のようなリスト値は `#+tags: foo bar` みたいな書き方

といった具合．文法はマニュアルを見てみたけど，いまいち細かいことはわからない．
https://orgmode.org/manual/Property-Syntax.html#Property-Syntax

Hugo 側で独自に解釈しているところもあるっぽいので開発者(?)の具体例を見たほうが良い．
https://gitlab.com/kaushalmodi/hugo-sandbox/

このリポジトリの `content-org` というディレクトリにおいてある org-mode でかかれた記事群が参考になる．READMEによると `content` ディレクトリとは別にすべきとあるが，フォーラムによると

> You can mix all types in the same Hugo site simultaneously (either by name (*.md, *.org etc.) or by markdown=org etc. in front matter)).
> https://discourse.gohugo.io/t/how-to-use-org-mode-with-hugo/6430/6

というわけで，最新の Hugo では `content` とわける必要はないそうだ．ところで Kaushal 氏はシングルファイルの org-mode を Hugo に出力するツール ox-hugo の開発者であり，twitterなどでもときどき拾ってくれるようなので，ハマった時はフォーラムなりtwitterに投げてみようと思う．
https://twitter.com/kaushalmodi/status/1074500107846840320


## 余談

[mustache](http://mustache.github.io/)テンプレートエンジンのような記法で， `.Name` とか明らかに Go っぽいフィールドにアクセスしていて，どうやってるのかなと色々調べたら， Go 言語にはリフレクションの公式パッケージがあるようだ．これは結構 Web 系のフレームワーク作りやすい気がする．

https://golang.org/pkg/reflect/#Value.FieldByName

エラー処理など真面目に作ると大変そうだが (Goでも既に大変そう)，D言語にも静的(コンパイル時)リフレクションがあるので実行時の文字列で与えられるフィールドにアクセスすることはできる．ちょっと書いてみるとこんな感じ

```d
// D言語の構造体フィールドに実行時の名前でアクセス
import std.stdio;

struct Hoge {
	int N;
    double D;
}

auto fieldByName(T)(ref T x, string attr) {
    foreach (a; __traits(allMembers, T)) {
        if (a == attr) {
            return  __traits(getMember, x, a);
        }
    }
    assert(false, "not found: " ~ attr);
}

void main() {
    Hoge h = {10, 2.0};

    auto v = h.tupleof[0];
    auto name = __traits(allMembers, Hoge)[0];

    assert(h.fieldByName(name) == v);
    assert(h.fieldByName("N") == 10);
    assert(h.fieldByName("D") == 2.0);

    // 元の Go のコード https://kwmt27.net/index.php/2013/10/02/get-field-value-of-struct-with-reflect-golang/
    // v := reflect.ValueOf(h) //Value
    // t := v.Type()           //Type
    // name := t.Field(0).Name
    // fmt.Println(name) //フィールド：N
    // fmt.Println(v.FieldByName(name).Interface()) //h.Nの値
}
```

やはりD言語の `__traits` 関係は何でも出来て最高．ところでこの `fieldByName` 関数の返り値の型って実行時にしか決まらないと思うんだけど，ちゃんと動いていて不思議だ．色々試したけど，変にコンパイラのチェックを逃れるわけでもなさそう．

## 最後に

org-mode のサポートは未だ experimental な機能っぽいので(ドキュメントにもあまりでてこない)，不完全な部分もある．たとえばこの記事は markdown で書いているので PAGE CONTENT という目次がページ上部にちゃんとでていると思うが， org-mode で書いた記事には目次がでてこない．この辺はテーマのせいかもしれないし，切り分けが面倒なので今後の課題にしよう．次からは org-mode で記事を書こうと思う．私は markdown と org-mode どちらも良いものだと思っているので，両方使えるのは本当に良い．

それにしてもGo言語にはorg-modeのパーサー実装 (https://github.com/chaseadamsio/goorgeous) があるなんて，すごいコミュニティだと思った．やはりRuss Coxを始めパーサーやコンパイラ界隈の人々が多い気がする．

