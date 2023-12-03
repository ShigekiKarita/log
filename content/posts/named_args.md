---
title: "D言語における名前付き引数"
summary: ""
categories: ["D"]
tags: ["D"]
draft: false
date: 2023-12-04T04:04:03+09:00
author: "Shigeki Karita"
isCJKLanguage: true
markup: "md"
---

[D言語アドベントカレンダー2023](https://qiita.com/advent-calendar/2023/dlang) 4日目の記事です。

## DIP1030

PythonやOCamlで便利な名前付き引数(named/labeled/keyword arguments)ですが、D言語ではDIP1030により提案され三年前に採択されてます。

- 提案 https://github.com/dlang/DIPs/blob/master/DIPs/accepted/DIP1030.md
- 実装状況 https://github.com/dlang/dmd/pulls?q=named+arguments

現在templateなどが未サポートですが、最近のDMDではその機能を `-preview` フラグなどもなく試すことができます。
今回の検証環境はDMD2.106.0です。

## 関数呼び出し

それでは基本的な使い方を例に上げていきます。

```d
import std;

void f(int a, int b) {
  writeln("f(a: ", a, ", b: ", b, ")");
}

void g(int a = 0, int b) {
  f(a: a, b: b);
}

void main() {
  f(a: 1, b: 2);
  f(a: 1, 2);
  f(1, b: 2);
  1.f(b: 2);
  // f(b: 1, 2); error                                                                                                                                                           
  // 2.f(a: 1); error                                                                                                                                                            
  g(b: 2);
  // g(1); error
}
```

基本的には呼ぶ順番を自由に指定できる、名前に意味がある場合は読みやすいなどのメリットがあるでしょう。
Pythonと違ってデフォルト値ありがデフォルト値なし仮引数よりも前に宣言できたり、名前付きのあとに名前無し引数が来てもいいなど、より自由度が高いのは良いですね。

## struct/class 初期化

関数っぽいもの、といえば構造体やクラスも名前付き引数で構築することができます。

```d
struct S {
  int a;
  int b;
}

struct SS {
  S s;
  int c;
}

class C {
  this(int a, int b) {
    writeln("C(a:", a, ", b:", b, ")");
  }
}

void main() {
  S s = {a: 1, b: 2};
  writeln(s);
  // writeln(S{a:1, b:2}); // error
  writeln(S(a:1, b:2));
  SS ss = {{a: 1, b: 2}, c: 3};
  writeln(ss);
  writeln(SS(S(a: 1, b: 2), c: 3));

  C c = new C(a:1, b:2);
}
```

これまで構造体では波括弧 `{}` を使った [static initialization](https://dlang.org/spec/struct.html#static_struct_init) がありましたが、
`foo(S{a:1, b:2})` のようには書けず、一々なんらかの変数に代入して `S s = {a:1, b:2}; foo(s)` と呼ぶ煩わしさがありました、これを名前付き引数では回避できます。
さらにクラスではできなかった名前付き引数によるコンストラクタ呼び出しも可能です。

## パラダイムシフトとなるか

現在テンプレートの名前付き引数が未実装なため、この機能は告知もなく誰も知らない状況ですが、現状でも十分ライブラリ設計に変革を齎すのではないかと考えています。

例えばHTMLのように名前付きで構築することが前提のユースケースであったり

```d
string html(string lang, string inner) {
  return "<html lang=\"" ~ lang ~ "\">" ~ inner ~ "</html>";
}

string img(string src, string alt) {
  return "<img src=\"" ~ src ~ "\", alt=\"" ~ alt ~ "\" />";
}

unittest {
  html(lang: "ja", img(src: "hello.png", alt: "hello image"));
}
```

または線形代数や機械学習といった分野の関数は非常に多くの引数をもっており一部だけ変更したときなど便利です ([optax.adamの例](https://optax.readthedocs.io/en/latest/api.html#adam))

```d
void adam(float[] params, float[] states, float lr = 1e-4, float beta1 = 0.9, float beta2 = 0.999, float eps=1e-08, float eps_root=0.0);

unittest {
  adam(params, states, beta2: 0.98);
}
```

OCamlのCoreのように徹底して名前付き引数を好む設計も興味深いです https://opensource.janestreet.com/core/

参考リンク

- https://v2.ocaml.org/manual/lablexamples.html
- https://dev.realworldocaml.org/variables-and-functions.html#labeled-arguments
- https://peps.python.org/pep-3102/
