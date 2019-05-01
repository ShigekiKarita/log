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
- tags のようなリスト値は `#+tags: foo bar** みたいな書き方

といった具合．文法はマニュアルを見てみたけど，いまいち細かいことはわからない．
https://orgmode.org/manual/Property-Syntax.html#Property-Syntax

Hugo 側で独自に解釈しているところもあるっぽい．

## こまかい話

具体的な書き方として， **一番役に立ったのはこの人のブログだ．**  とにかく沢山の記事がある．

- ソース https://github.com/hiroakit/blog
- 解説など https://www.hiroakit.com/2018/03/hugo-with-netlify/

この記事や手元の挙動を見ていると幾つか注意点として

- markdown と違って org-mode の baseURL 的な解釈はうまくいってないようだ．
- 例えばローカルの画像ファイルなどは記事ディレクトリを作り直下に置いて相対パスで指定するのがよい，その際に記事は `index.org` というファイル名に書く
- そもそも mustache 的なテンプレートは効かない?
- シンタックスハイライトは `#+begin_src perl` のような小文字ではダメで `#+BEGIN_SRC perl` としなければならない


```org
# content/posts/foo/index.org という org ファイルを作ると
# {{ baseURL }}/posts/foo/index.html として生成される

# 大文字じゃないとダメ
#+BEGIN_SRC d
void main() {}
#+END_SRC

# 画像 content/posts/foo/bar.png というファイル
[[file:./bar.png]]
```


## 余談: D言語で実行時リフレクション

[mustache](http://mustache.github.io/)テンプレートエンジンといえば，Front Matterなんかは `.Name` とか明らかに Go っぽいフィールドにアクセスしていて，どうやってるのかなと色々調べたら， Go 言語にはリフレクションの公式パッケージがあるようだ．これは結構 Web 系のフレームワーク作りやすい気がする．

https://golang.org/pkg/reflect/#Value.FieldByName

エラー処理など真面目に作ると大変そうだが (Goでも既に大変そう)，D言語にもコンパイル時リフレクションがあるので実行時の文字列で与えられるフィールドにアクセスすることはできる．ちょっと書いてみた．

```d
import std.stdio;
import std.variant;

struct Hoge {
	int N;
    string S;
}

auto maxFieldSize(T)() {
    ulong size = 0;
    foreach (m; T.init.tupleof) {
        if (size < m.sizeof) size = m.sizeof;
    }
    return size;
}

auto fieldByName(T)(ref T x, string attr) {
    VariantN!(maxFieldSize!T) v;
    foreach (a; __traits(allMembers, T)){ 
        if (a == attr) {
            v = __traits(getMember, x, a);
            break;
        }
    }
    return v;
}

void main(string[] args) {
    const Hoge h = {10, "aa"};

    auto v = h.tupleof[0];
    auto name = __traits(allMembers, Hoge)[0];

    assert(h.fieldByName(name) == v);
    assert(h.fieldByName("N") == 10);
    assert(h.fieldByName("S") == "aa");
    // 元の Go のコード https://kwmt27.net/index.php/2013/10/02/get-field-value-of-struct-with-reflect-golang/
    // v := reflect.ValueOf(h) //Value
    // t := v.Type()           //Type
    // name := t.Field(0).Name
    // fmt.Println(name) //フィールド：N
    // fmt.Println(v.FieldByName(name).Interface()) //h.Nの値
}
```
やはりD言語の `__traits` 関係は何でも出来て最高．返り値を `std.variant.VariantN` で型消去してます． https://dlang.org/phobos/std_variant.html

そうえいばD言語でもちゃんとしたテンプレートエンジンがある，DでHugoみたいなやつ作ってみようかな? https://qiita.com/repeatedly/items/300041d55fd5b45b69e1

あとさっき twitter でD言語で実行時リフレクションライブラリがでてきたという話をみた． http://code.dlang.org/packages/hunt-reflection

## 最後に

org-mode のサポートは未だ experimental な機能っぽいので(ドキュメントにもあまりでてこない)，不完全な部分もある．たとえばこの記事は markdown で書いているので PAGE CONTENT という目次がページ上部にちゃんとでていると思うが， org-mode で書いた記事には目次がでてこない．この辺はテーマのせいかもしれないし，切り分けが面倒なので今後の課題にしよう．次からは org-mode で記事を書こうと思う．私は markdown と org-mode どちらも良いものだと思っているので，両方使えるのは本当に良い．

それにしてもGo言語にはorg-modeのパーサー実装 (https://github.com/chaseadamsio/goorgeous) があるなんて，すごいコミュニティだと思った．やはりRuss Coxを始めパーサーやコンパイラ界隈の人々が多い気がする．

