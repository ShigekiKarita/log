---
title: "LinuxでMS Gothicのアンチエイリアスを無効化する"
summary: ""
categories: ["linux"]
tags: ["linux"]
draft: false
date: 2023-12-12T13:38:03+09:00
author: "Shigeki Karita"
isCJKLanguage: true
markup: "md"
---

私はMSゴシック系のフォントをコーディングで使うのが好きなのですが、Linuxのアプリではデフォルトでアンチエイリアスが効きまくっておりWindowsのそれとは全然見た目が違います。
そもそもビットマップフォントなので幅などがめちゃくちゃになってしまうこともあります。
アンチエイリアス無効化をアプリごとに個別に設定するのもダルいしそもそもできないことが多いので、fontconfigを使ってOSレベルで設定するといいです。
ArchWikiに全部書いてありますが、膨大なので抜粋すると 

- [アンチエイリアス](https://wiki.archlinux.jp/index.php/%E3%83%95%E3%82%A9%E3%83%B3%E3%83%88%E8%A8%AD%E5%AE%9A#.E3.82.A2.E3.83.B3.E3.83.81.E3.82.A8.E3.82.A4.E3.83.AA.E3.82.A2.E3.82.B9)
- [マッチテスト](https://wiki.archlinux.jp/index.php/%E3%83%95%E3%82%A9%E3%83%B3%E3%83%88%E8%A8%AD%E5%AE%9A#.E3.83.9E.E3.83.83.E3.83.81.E3.83.86.E3.82.B9.E3.83.88)

といった項目を参照すると良いです。

```xml
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <match target="font">
    <test qual="any" name="family">
      <string>MS Gothic</string>
    </test>
    <edit name="antialias" mode="assign">
      <bool>false</bool>
    </edit>
  </match>
</fontconfig>
```

こんな感じで `/etc/fonts/conf.d/20-msgothic.conf` とかに保存するとちゃんとWindowsとかで見る感じになります。

![after](https://github.com/ShigekiKarita/log/assets/6745326/b79e2b64-b673-4d42-9c7c-069c6479ba3b)
