---
title: "給付金でNAS組んだ"
summary: ""
categories: ["Hardware"]
tags: ["Hardware"]
draft: false
date: 2020-08-23T00:47:25+09:00
author: "Shigeki Karita"
isCJKLanguage: true
markup: "md"
---

コロナ給付金を突っ込んでNASを組みました。3ヶ月運用してなんの問題もなかったので記録しておきます。ずっと前からNASは欲しかったのですが、もっと早く組んでいれば良かったです。

## 構成

- OS: [XigmaNAS](https://www.xigmanas.com/), 無料
- PC: HP ProLiant MicroServer N54L HDD無し, 8k円, ヤフオクで中古品を購入
- HDD: WD Red 5400rpm 10TB 2本セット, 53k円, 新品をイートレンドで購入
- RAM: ECCつきDDR3 16GB, 8k円, ヤフオクで中古品を購入
- OS用のUSBメモリ: ICASSPで貰った4GBのやつ

価格は2020年5月のもの。 [XigmaNASの動作要件](https://www.xigmanas.com/wiki/doku.php?id=documentation:setup_and_user_guide:hardware_requirements) によるとRAMは最小8GBという贅沢仕様ですが、ZFSの仕様上RAMが多ければ多いほど速いらしい。しかしながら初期PCに付属していた4GBでも、重い処理が同時に走っていなければ普通に動くので、後から買い足してもいいです。

メーカー製PCを土台としているのは単純に8k円で、より良い構成ができる気がしなかったからです。型番は古いですが、コロナのせいか企業が予備として保存していた未使用品が格安で入手できるのでオススメ。

![proliant-usb](https://pbs.twimg.com/media/EW570uRUwAE0GGD.jpg)

OS入れるストレージは、XigmaNASは起動時にRAM上に展開されるため重要ではないので、適当に転がってたUSBメモリに入れましたが、中にUSBポートがあるのでUSBメモリが出っ張るみたいなことがないのも最高です。

![proliant2](https://pbs.twimg.com/media/EW53kSbU8AAJOrM.jpg)

扉の裏側に冬場の岩の裏みたいにびっしりとHDD用ネジとレンチがついてるので便利。

![red](https://pbs.twimg.com/media/EW5xP9eU4AEtngc.jpg)

WD Redは何度も買ってますが、こんな耐湿パックに入ってるのは初めて見た。NASを組む上でWD Red 10TBにしたのは、いままで一度も故障したことがない銘柄ということ (GreenとかSeagateは何度も壊れた), WDなど各社が廉価モデルのプラッタをCMRからSMRに切り替えており、Red 8TB以上が最もコスパの良いCMR方式のNAS向けHDDだったためです。[^wd]

[^wd]: WD公式のプラッタ方式リスト https://blog.westerndigital.com/wd-red-nas-drives/

## XigmaNASについて

いままでZFSを使ったことがなかったので対応しているOSであること、今手元にBSD系の環境がないので丁度よかったのでNAS4FreeあらためXigmaNASを選びました。

ブラウザで設定できるので正直とくに詰まるところはありませんでしたが、ProLiantが冗長化用に2つネットワークカードを持っていたのと、我が家ではやや特殊なIPアドレス割当を行っていたので、そこだけD-SUBで画面を繋いで本体から設定しました。ZFSは基本的に、 [このへん](https://ameblo.jp/purplesounds/entry-12425869820.html
) を見ながらシンプルにRAID1で組みました。Redの上にRAID1なので大分安心感あります。SMART値を確認して初期不良品ではないかのチェックも忘れずに。

ZFSは初めてでしたが、普段使ってるbtrfsと概念的な対応があるので( [この比較表](https://dev.to/rkeene/btrfs-zfs-and-more-22jg) がわかりやすい?)、本番の構成組む前に色々試すといいです。個人的にはパーティションごとに各種権限や容量上限を設定できたり、ほとんどの設定が後から変更可能な点が優しいと思いました。

## 難点

![proliant1](https://pbs.twimg.com/media/EW-mVoBVcAAKsIp.jpg)

唯一の難点はProliantファンがマジでうるさいということです。ファンを交換しようかと思いましたが、とりあえずクローゼット内に置いて隔離しています。夏場の一番暑い時期ですが、意外と温度は問題ありませんでした。3ヶ月間一度も止めていなくて心配になってさっき再起動してみましたが、管理ページ起動まで数分かかるのも微妙です。

## 今後

HDDは現在2枚ですが、空きスロットにあと2枚、そして光学ディスク用のSATAもあるのでまだ3枚追加できます。WDから18TBの新製品も出たので、
次にHDD追加するときが楽しみです。[^wd18]

[^wd18]: https://akiba-pc.watch.impress.co.jp/docs/price/monthly_repo/1267880.html
