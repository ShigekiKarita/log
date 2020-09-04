---
title: "C++17以降の機能をD言語で"
summary: ""
categories: ["D"]
tags: ["D"]
draft: false
date: 2020-09-04T10:06:03+09:00
author: "Shigeki Karita"
isCJKLanguage: true
markup: "md"
---


## default 三方演算子 (three-way operator)

https://cpprefjp.github.io/lang/cpp20/consistent_comparison.html

C++20の `auto operator<=>() = default;` を模倣しました。D言語だと `opCmp` が三方演算子に相当します。Dには tupleof があるので構造体の要素を再帰的に辿って比較続けることは容易です。

```d
/// C++20 like default opCmp implementation
auto defaultOpCmp(T)(T a, T b) {
  static if (__traits(compiles, a.opCmp(b))) return a.opCmp(b);
  static if (__traits(compiles, a.tupleof)) {
    int c;
    foreach (i, x; a.tupleof) {
      c = defaultOpCmp(x, b.tupleof[i]);
      if (c != 0) return c;
    }
    return c;
  }
  else return (a < b) ? -1 : (a > b) ? 1 : 0;
}

/// Usage of defaultOpCmp
version (unittest) {
  struct A { int opCmp(A that) const { return 0; } }
  struct B {}
  struct S {
    int i; double d; A a;
    alias opCmp = defaultOpCmp;
  }
}
unittest {
  assert(S(1, 2) == S(1, 2));
  assert(S(1, 2) < S(3, 4));
  assert(S(1, 2) < S(3, 0));
}
```

## 構造化束縛

https://cpprefjp.github.io/lang/cpp17/structured_bindings.html

C++17の機能で一番良いなぁと思ってるのがこの機能です。D言語では with 文で `foo.bar` のような識別子に `with (foo) { bar; }` としてアクセスできること、 `tuple!("foo", "bar")(1, 2)` のようにタプルのフィールド名を指定できることを組み合わせると、変数のように束縛できます。

```d
import std.meta : aliasSeqOf;
import std.typecons : isTuple, tuple, Tuple;

/// Flatten nested tuple (a, (b, c)) to (a, b, c).
auto flatten(Ts ...)(Ts ts) {
  static if (isTuple!(Ts[0]))
    static if (ts.length == 1) return flatten(ts[0].expand);
    else return tuple(flatten(ts[0].expand).expand,
                      flatten(ts[1..$]).expand);
  else
    static if (ts.length == 1) return tuple(ts[0]);
    else return tuple(ts[0], flatten(ts[1..$]).expand);
}

/// Flatten and rename tuple fields to given names.
template bind(names...) {
  auto bind(T)(T t) {
    return tuple!(aliasSeqOf!(flatten(tuple(names))))(flatten(t).expand);
  }
}

/// Usage of bind
unittest {
  auto t = tuple(1, tuple(2.3, "foo"));
  with (t.bind!("x", tuple("y", "z"))) {
    assert(x == 1);
    assert(y == 2.3);
    assert(z == "foo");
  }
}
```

## パターンマッチ?

複数の型に対する overload をまとめて書きたい動機があり、 C++では [std::visit](https://cpprefjp.github.io/reference/variant/visit.html) があります。D言語の std.variant では [visit](https://dlang.org/phobos/std_variant.html#.visit), 継承関係のクラス群には [std.algorithm.castSwitch](https://dlang.org/phobos/std_algorithm_comparison.html#.castSwitch) がありました。ついでに tuple に対するやつは標準にないので [tupleops.overload](https://github.com/ShigekiKarita/tupleops) というやつを昔作りました。
```d
import tupleops:

alias f = overload!(
  (int i) => i.to!string,
  (int i, int j) => i + j,
  (double d) => d * 2);

auto t = tuple(1.0, 2, tuple(3, 4));
assert(map!f(t) == tuple(2.0, "2", 7));
```

さらに C++ では [inspect](http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2020/p1371r2.pdf) という値(と型)に対するパターンマッチが提案されてますが、構文が複雑すぎて入らないと思ってます。私は新しい予約語や構文を追加するよりも、D言語のように switch 文の case を定数式とれるようにするか、連想辞書リテラルを作るほうが良いと思います。個人的には OCaml や Rust のような [ML 系言語のパターンマッチ](https://doc.rust-jp.rs/book/second-edition/ch18-03-pattern-syntax.html) が構文的には理想です。
