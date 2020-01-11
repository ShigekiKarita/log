---
title: "Windows CUI環境における VST3 開発"
summary: ""
categories: ["VST3", "C++"]
tags: ["VST3"]
draft: true
date: 2020-01-12T02:24:12+09:00
author: "Shigeki Karita"
isCJKLanguage: true
markup: "md"
---

あけましておめでとうございます、今年こそはWindowsにも慣れていこうと思います。

今回はVST3開発環境構築と簡単なプロジェクトの作り方のメモです。私は以前、[Dplug](https://github.com/AuburnSounds/Dplug)を使って[D言語でVSTを作っていたとき](https://qiita.com/kari_tech/items/ef47d792b4aae047b42c)はVST2を使ってました。しかしVST2の開発サポートが終わってしまったので、そろそろVST3に移行したいです。具体的なゴールとしてはVST3で登場したMIDIエフェクトが作りたいです。まず仕組みを知るために、公式のC++から入ります。ちなみにDplugではすでにVST3が[サポート](https://github.com/AuburnSounds/Dplug/tree/master/vst3/dplug/vst3)されています。

問題点としては、いつもメインのWin開発環境はMSYS2なのでgccを使いたいのですが、CMakeのスクリプトやC++のプリプロセッサなどを見る限りWindowsではVS前提に書かれていました (`cmake -G "MSYS Makefiles"` で動くようにするのは、理解の浅い現時点ではハードルが高いです)。さらに私にとってネットによくあるVSとCMakeのGUIを使った開発が無理だったので、最低限シェル内で完結して開発する方法を模索しました。

## cmakeとVS2019 (VC compiler + Win10 SDK) で、VST3 SDKビルド

[公式サイト How to use cmake for Building VST 3 Plug-ins](https://steinbergmedia.github.io/vst3_doc/vstinterfaces/cmakeUse.html)

全体のながれ

- [CMake公式](https://cmake.org/download/)からビルド済みバイナリzipをDLしPATHを通す。ちなみにpacmanのcmakeはVSをサポートしてない
- [Visual Studio 2019 Installer](https://visualstudio.microsoft.com/ja/thank-you-downloading-visual-studio/?sku=Community&rel=16) で "C++によるデスクトップ開発" > "MSVC v142" および "Windows 10 SDK" にチェックをいれてインストールします。これが最小構成
- VS2019 でインストールされたMSBuild.exeとcl.exeにCMakeが見つけられるようPATHを通す
- [VST3 Audio Plug-Ins SDK](https://www.steinberg.net/vst3sdk)をDLして、CUIからビルド

PATHの通し方はこんな感じです。

```bash
VS_ROOT="/c/Program Files (x86)/Microsoft Visual Studio/2019/Community"
export PATH="${VS_ROOT}/MSBuild/Current/Bin":$PATH
export PATH="${VS_ROOT}/VC/Tools/MSVC/14.24.28314/bin/Hostx64/x64":$PATH
export PATH=$HOME/Documents/cmake-3.16.2-win64-x64/bin:$PATH
```

最後にSDKをビルドします。versionは [3.6.14_build-24_2019-11-29](https://github.com/steinbergmedia/vst3sdk/commit/0908f475f52af56682321192d800ef25d1823dd2) でした。VST2と違ってVST3はgithubにあるのが良いですね。[公式ドキュメント](https://steinbergmedia.github.io/vst3_doc/vstinterfaces/cmakeUse.html)を参考にCUIからビルド:

```bash
cd "<解凍先>/VST SDK"

# vstsdk.sln を生成
mkdir build
cd build
cmake  -G "Visual Studio 16 2019" -A x64 ../VST3_SDK

# VSを使ってビルド
MSBuild.exe vstsdk.sln
```

なお MSBuild.exe のログが日本語になって文字化けしていると思いますが、 `$ chcp 850` と打てば英語になってくれます。筆者の環境ではビルド完了まで1分ほどかかりました。

```bash
# ビルドした検証ツールとVSTサンプルをテスト
./bin/Debug/validator.exe ./VST3/Debug/adelay.vst3
```

一通りビルド成功していれば、`VST3/Debug` 以下に[VSTプラグインのサンプル](https://github.com/steinbergmedia/vst3_public_sdk/tree/master/samples/vst)も一緒にビルドされていますので、動作確認に `bin/Debug` 以下にビルドされた[VSTホストサンプルの検証ツール](https://github.com/steinbergmedia/vst3_public_sdk/tree/master/samples/vst-hosting/validator)を使えるはずです。以上で環境構築は終わりです。


## 新しいVST3プラグインを書く

[公式サイト How to add/create your own VST 3 Plug-ins](https://steinbergmedia.github.io/vst3_doc/vstinterfaces/addownplugs.html)

主にプロジェクト立ち上げ時に必ずやることとしては、

1. 自分のプラグイン置き場にhelloworldをコピーする
2. 置き場のCMakeList.txtに新しいサブディレクトリを追加
3. 新しいプラグイン名でhelloworld/HelloWorldを置換
4. 新しいuidで`include/plugid.h`を更新
5. 新しいプラグイン名で`include/version.h`を更新
6. 新しいプラグイン名で`resource/info.plist`を更新

これ毎回やるの地獄だな...と思ったので、初期プロジェクトの構築を[シェルスクリプト化](https://github.com/ShigekiKarita/vst3-tools/blob/master/init-plugin.sh)してみました(要bash)。使い方は

```bash
cd "<自作プラグイン置き場>"
git clone --recursive https://github.com/ShigekiKarita/vst3-tools
./vst3-tools/init-plugin.sh FooBar

# copyrightなどの情報を更新
emacs FooBar/include/version.h
```

これでFooBarというディレクトリとFooBarという表示名のfoobar.vst3が生成されるプロジェクトができます。`include/version.h`には著者名などを書き込む欄もありますので、忘れずに更新してください。ちなみに実装をすすめる際は次のようなステップがあるとのこと:

- plugcontroller.cpp にパラメータ追加
- plugprocessor.cpp にアルゴリズム追加
- plugprocessor.cpp に永続化を実装
- UI実装 ([このへんのサンプル](https://github.com/steinbergmedia/vst3_public_sdk/tree/bb0e864a336bbe9cc8d6dce1b9f47430d81ee84f/samples/vst/pitchnames/source)が参考になりそう?)

そして新しいプラグインを作ったときのビルド方法:

```bash
# このbuildディレクトリは自作プラグイン置き場の外に作らないといけない
mkdir build
cd build

cmake -DSMTG_ADD_VST3_PLUGINS_SAMPLES=OFF \
      -DSMTG_ADD_VST3_HOSTING_SAMPLES=OFF \
	  -DSMTG_MYPLUGINS_SRC_PATH="<自作プラグイン置き場>" \
	  -G "Visual Studio 16 2019" \
	  -A x64 \
	  "<解凍先>/VST_SDK/VST3_SDK"

# VSを使ってビルド
MSBuild.exe vstsdk.sln
```

この例でもビルドに30秒かかるので、毎回新しいプラグインやファイル作るたびにSDKと全自作プラグインがビルドし直しなのは嫌ですね。ただし、モジュールのない時代のC++にビルド設定で深入りするのも面倒ですし、SDK側もそこそこな頻度でアップデートあるからそういうものかと無理やり納得しています。

## おわりに

今回は環境構築で力尽きましたが、次回は作りたかったMIDIエフェクト、もしくはdplugでのVST3出力をやっていこうと思います。
