---
title: "dpp: C/C++ライブラリをD言語から楽に使う"
summary: ""
categories: ["Programming", "D"]
tags: ["D"]
draft: false
date: 2019-12-15T00:00:00+09:00
author: "Shigeki Karita"
isCJKLanguage: true
markup: "md"
---

これは [D言語Advent Calendar](https://qiita.com/advent-calendar/2019/dlang)，16日目の記事です．

## はじめに

筆者は常々，D言語の唯一(?)の欠点はコミュニティの小ささ ≒ ライブラリの少なさだと思っていました．しかし今やdppの登場で，莫大な C/C++ コミュニティのライブラリを全自動で再利用できるため，人気の言語に負けない規模の財産を得たのです．本記事はとくにC/C++から段階的に移行したい読者にとって，D言語を始める良い機会になればと思います．

## D言語と C/C++ の互換性

D言語にはCおよびC++(!!)との互換性があるので， `extern (C)` または `extern (C++)` で修飾子した型や関数を宣言(bind)して，ビルド済みのC/C++ライブラリをリンクすれば自由に呼び出すことが可能です．

- [Interfacing to C](https://dlang.org/spec/interfaceToC.html)
- [Interfacing to C++](https://dlang.org/spec/cpp_interface.html)

D言語の標準ライブラリ(ランタイム)にある `core.stdc` と `core.stdcpp` は，それぞれC/C++標準ライブラリをbindしています．最近では `std::vector` のような大作も入っています．

- https://github.com/dlang/druntime/tree/v2.089.0/src/core/stdc
- https://github.com/dlang/druntime/tree/v2.089.0/src/core/stdcpp

ただし，bindを人手で書くので間違えたりするとリンクエラーになったり，巨大なライブラリだと記述量が多くて面倒です (人手で頑張っている [deimos](https://github.com/D-Programming-Deimos)や, [derelict](https://github.com/DerelictOrg)とその置き換えである[bindbc](https://github.com/BindBC) などのプロジェクトもあります)．

そこで登場したのが dpp です．

https://github.com/atilaneves/dpp

dpp は C/C++ コンパイラのフロントエンド API (libclang) を内部で使うことで，includeしたC/C++ヘッダーから自動的にD言語用の宣言を生成してビルドします．たとえばPythonやJuliaといった巨大なプロジェクトのCヘッダーでさえ，自動でbindできる完成度の高いツールです．

## インストール

Debian系のOSなら以下のように環境構築できます．

```bash
# libclang のインストール
sudo apt-get install libclang-6.0-dev

# D言語コンパイラのインストール
source $(curl https://dlang.org/install.sh | bash -s -- ldc-1.18.0 -a)

# dpp のビルド
dub fetch dpp --version=0.4.0
dub run dpp -- --help
```

## 基本的な使い方

D言語のソースコード中に `#include <C/C++ヘッダー名>` を記載した dpp ファイルをコンパイルできます．

```bash
dub run dpp -- (オプション) ファイル名.dpp
```

以下のオプションが便利です

- `--compiler` dmd や ldc2 などコンパイラを指定
- `--include-path` C/C++ライブラリヘッダーのパスを指定
- `--parse-as-cpp` includeしたヘッダーをC++の文脈で解釈
- `--keep-d-files` 自動で生成したD bindingヘッダーを出力
- `--preprocess-only` 上記のヘッダーを出力だけしてコンパイルせず終了

## 例1: 単一のファイル

D言語はビルドがはやく楽に記述できるのでスクリプトとして単一のファイルを使うことも多いでしょう．
今回は未だDerelictからBindBC化されず悲しいOpenCLを題材に，GPUなどのデバイス情報を表示してみましょう．
なおOpenCLのインストール方法は利用しているハードウェアに依存するので読者の課題とします．

```opencl_test.d
#include <CL/cl.h>

import std.stdio : writeln;

void main()
{
    // get first platform and device
    cl_platform_id platform;
    cl_device_id device;
    clGetPlatformIDs(1, &platform, null);
    clGetDeviceIDs(platform, CL_DEVICE_TYPE_DEFAULT, 1, &device, null);

    // print device info
    foreach (q; [CL_DEVICE_NAME, CL_DEVICE_VERSION, CL_DRIVER_VERSION])
    {
        cl_ulong len;
        clGetDeviceInfo(device, q, 0, null, &len);
        auto cs = new char[len];
        clGetDeviceInfo(device, q, len, cs.ptr, null);
        writeln(cs);
    }
}

```

以下を実行すると，ハードウェア情報が表示されるはずです．

``` console
$ dub run dpp -- --compiler=ldc2 opencl_test.dpp -L-lOpenCL
$ ./opencl_test
Intel(R) Gen9 HD Graphics NEO
OpenCL 2.1 NEO 
19.26.13286
```

ちなみにdmdを使うとコンパイラのバグで異常終了します(!?)．


## 例2: DUB との連携

現状，簡単にDUBと連携する方法はないです．ただしdppは中間のD言語ヘッダーを出力できるので，preBuildCommandsを使って追加設定をするなど連携できます

- dub.json の `preBuildCommands` で dpp をインストールし・ヘッダーを自動生成
- `libs` にリンクするライブラリを指定
- (オプション) source 以外の場所に生成した場合 dub.json の `sourcePaths` `importPaths` に追加

```dub.json
{
    "preBuildCommands": [
        "dub fetch dpp --version=0.4.0",
        "dub run dpp -- --preprocess-only source/opencl.dpp"
    ],
    "libs": ["OpenCL"],
    "authors": ["karita"],
    "copyright": "Copyright © 2019, karita",
    "description": "dpp demo for OpenCL",
    "license": "BSL-1.0",
    "name": "dpp-opencl"
}
```

以下のコマンドで私の用意したプロジェクトがビルド出来るはずです

```bash
$ git clone https://github.com/ShigekiKarita/dpp-opencl
$ cd dpp-opencl
$ dub run --compiler=ldc2
```

プロジェクトはGitHubに公開してます https://github.com/ShigekiKarita/dpp-opencl


それでは皆さん，より一層快適なD言語生活を!
