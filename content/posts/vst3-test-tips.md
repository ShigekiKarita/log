---
title: "VST3開発TIPS テスト編"
summary: ""
categories: ["VST3", "C++"]
tags: ["VST3", "C++"]
draft: false
date: 2020-01-13T16:53:29+09:00
author: "Shigeki Karita"
isCJKLanguage: true
markup: "md"
---

前回に引き続きCUIでVST3開発をすすめています。いくつか役立ちそうなTIPS+、とくにテスト関連をメモしています。適宜追加するかもしれません。

## 1. 情報源

- [公式ドキュメント](https://steinbergmedia.github.io/vst3_doc/)、Doxgen検索機能やリンクが割と貧弱なのでローカルでgrepすることが多いです
- [はじめてのVST3.6プラグイン作り](https://vstcpp.wpblog.jp/?page_id=1316)、公式に殆どない(リンク切れてるし...)GUI関連の情報が嬉しいです

## 2. テスト用のVSTホスト

まずVSTプラグインをつくったら、動かすにはホストが必要です。最終的には普段使っているDAWなりで検証すると思いますが、高速な開発サイクルを回すには軽量なテスト用ホストを使うと便利です。

### 公式 コマンドラインvalidator

4つあるSDK付属ホストの一つ。[公式に沿って `SMTG_ADD_VST3_HOSTING_SAMPLES=ON` で cmakeビルド](https://steinbergmedia.github.io/vst3_doc/vstinterfaces/cmakeUse.html)するとbin/Debug以下にできているはず

- [ソースコード](https://github.com/steinbergmedia/vst3_public_sdk/tree/master/samples/vst-hosting)
- [ドキュメント](https://steinbergmedia.github.io/vst3_doc/vstsdk/applications.html)

GUIは起動しないので、お手軽な感じです。実はテストランナーも備えていて、以下の公式例のように書くと呼んでくれます。ちょっと記述量が多めですが。
- [ITestを継承するテスト宣言](https://github.com/steinbergmedia/vst3_public_sdk/blob/master/samples/vst/adelay/source/factory.cpp#L72)、Factoryは[factory.cppで登録するため](https://github.com/steinbergmedia/vst3_public_sdk/blob/master/samples/vst/adelay/source/factory.cpp#L72)
- [テスト実装](https://github.com/steinbergmedia/vst3_public_sdk/blob/master/samples/vst/adelay/source/factory.cpp#L72)、リソース確保などなければrunメソッドのみ。階層的にITestを登録したければFactoryのcreateTestsで登録できる

現実的にはほとんど何もしないITest実装を作っておいて、GoogleTestなりなにか自分の好きなフレームワークをrunメソッドで呼ぶのもいいかもしれません。

### 公式 editorhost

あまり何に使うのかわかっていません。

### 公式 audiohost

JACKが必要なのでWindowsでは試してないけど、あまり選択肢がないLinuxでは便利かもしれないです。

### 公式 VST3PluginTestHost

![host](/log/img/vsthost.png)

`VST_SDK\VST3_SDK\bin\Windows 64 bit\VST3PluginTestHost_x64_Installer_2.8.0.zip`にあるインストーラで動く。若干起動が遅いのであまり使っていないですが、VST GUIエディタを使うときなど安定しているので便利そうです。Linux向けはないようです。

### JUCE AudioPluginHost

validatorの次くらいによく使っているやつです。Win/Mac/Linuxサポートされています。

https://github.com/WeAreROLI/JUCE/tree/master/extras/AudioPluginHost

JUCEはオープンソースのプラグイン開発ツールキットです、Steinberg公式よりも情報や機能が多い。これも軽くて楽です。前回のプロジェクトがプラグイン開きっぱなしの状態で開くので、開発中に一発でGUI動作確認できます。MIDI Outがないのが不満ですが...GPLのオープンソースなので改造してみました[(PRも送っています)](https://github.com/WeAreROLI/JUCE/pull/656)。

Visual Studio2019でビルドする場合はファイル`extras/AudioPluginHost/Builds/VisualStudio2019/AudioPluginHost.sln`をVSで開いて、上メニューバーの「ビルド＞ソリューションのビルド」で一発です。終われば`JUCE\extras\AudioPluginHost\Builds\VisualStudio2019\x64\Debug\App`以下に実行ファイルができている筈です。

## 3. DebugPrint 系の使い方

`#include "base/source/fdebug.h"`で使える、`SMTG_WARNING`, `SMTG_DBPRT0` .. `SMTG_DBPRT5`系の関数はprintf的なノリで使えます
```c++
#include "base/source/fdebug.h"

void foo()
{
	SMTG_ASSERT(1 + 2 == 3);
	SMTG_WARNING("invalid input!");
	SMTG_DBPRT1("%s is not found", path);
	// VERIFY系はReleaseのとき評価だけされるので注意、エラーはでない
	SMTG_VERIFY(1 + 2 == 3);
}
```
cmakeに `-DCMAKE_BUILD_TYPE=Debug` オプションを渡すと有効になり、`=Release`のとき無効になります。これがどこに表示されるのかよくわかっていないのですが、WindowsであればVisual StudioまたはgdbでVSTホストなりを起動してみるとどこかに表示されます。

例: `$ gdb AudioPluginHost.exe`

仕組みは `gDebugPrintLogger` という文字列を出力する関数ポインタを実行時にセットして呼ぶようです。デバッガの起動がだるいときはVST内で無理やりprintfなどに書き換えれば、標準出力にだしてコンソールからホストを起動していれば見れます。


## 4. C++によるファイルパス操作

これはテストとは少し違いますが、テストでファイルを扱うことは多々あるのでメモ。VSTではなんだかUTF8/16などが混在しているようですが、C++17で標準になったfilesystemを使うと`std::filesystem::path::string`や`std::filesystem::u16string`など多機能なエンコードでファイルパスを扱えますし、OSの提供するAPIに依存せずにマルチOS対応できて良いです。ちなみにC++11のUTF8や16を変換する`<codecvt>`は非推奨になったので使ってはいけません。

C++17を有効にするには、プラグインのCMakeLists.txtに以下を追記するようです。
```cmake
set_property(TARGET ${target} PROPERTY CXX_STANDARD 17)
set_property(TARGET ${target} PROPERTY CXX_STANDARD_REQUIRED ON)
```

ちなみにfilesystemの日本語解説、こちらが素晴らしいです。 https://cpprefjp.github.io/reference/filesystem.html
