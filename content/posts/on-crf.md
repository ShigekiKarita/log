---
title: "条件付き確率場について"
summary: ""
categories: ["machine learning"]
tags: ["CRF"]
draft: true
date: 2019-05-01T13:43:57+09:00
author: "Shigeki Karita"
isCJKLanguage: true
markup: "md"
---

## tl;dr

条件付き確率場 (CRF) を勉強して実装して，他のグラフィカルモデルと比較した

## はじめに

大学生の頃，一昔前の教科書 ([PRML](https://www.microsoft.com/en-us/research/uploads/prod/2006/01/Bishop-Pattern-Recognition-and-Machine-Learning-2006.pdf)とか[PrinceのCV](http://web4.cs.ucl.ac.uk/staff/s.prince/book/book.pdf)) で確率モデルを学んだ．私にとってグラフィカルモデルといえば隠れマルコフモデル(HMM)やマルコフ確率場(MRF)あたりでストップしていて，その次に流行した条件付き確率場(CRF)のことはよく知らないまま，ニューラルネットワーク(NN)とかが流行っていた．ふとCRFと，HMM/MRFそしてNNはどこまでで似てて何が違うのか知りたくなったので，ここにメモしておく．


CRFの参考になる文献

> Lafferty, John, Andrew McCallum, and Fernando CN Pereira. "Conditional random fields: Probabilistic models for segmenting and labeling sequence data." (2001). https://www.seas.upenn.edu/~strctlrn/bib/PDF/crf.pdf

最初に提案されたときの論文．

>  坪井祐太, 鹿島久嗣, 工藤拓, "言語処理における識別モデルの発展 - HMM から CRF まで," 自然言語処理学会, (2007).  http://2boy.org/~yuta/publications/nlp2006-revised-20070227.pdf

HMM との比較がされている．学習のアルゴリズムなどは省かれているが，問題設定などわかりやすい．

>  岡崎 直観, "条件付き確率場の理論と実践," 統計数理, (2016).  https://www.ism.ac.jp/editsec/toukei/pdf/64-2-179.pdf

素性 (feature) の作り方とか，動的計画法による学習アルゴリズムなど書かれていてわかりやすい．

> Charles Sutton, Andrew McCallum, "An introduction to conditional random fields,"  Foundations and Trends in Machine Learning 4 (4), (2012).  https://homepages.inf.ed.ac.uk/csutton/publications/crftut-fnt.pdf

とりあえず英語読めるならコレ読んだら大体実装できそう．

## 問題設定

本稿では，簡単のため一貫して系列識別の問題を扱う．実際にはこれらのモデルは木構造だったり，グリッドだったり様々な構造を扱えるけど，煩雑なのでやめる．ここで系列識別の問題とは多次元実数ベクトルの入力系列 $x_1, x_2, \dots, x_T \in \mathbb{R}^N$ を観測した時，各時刻における出力ラベル(状態ラベルとも言う) $y_1, y_2, \dots, y_T \in \mathbb{Y}$ が得られる条件付き確率 $p(y|x)$ を推定する問題です．ここでHMM/MRF/CRFのようなモデルが扱える出力ラベルの集合 $\mathbf{Y}$ は識別IDとか，たとえば品詞推定タスクでは品詞IDのようなスカラーの離散値に限定されていることに注意．出力で実数値を扱うにはカルマンフィルタなど別の手法が必要．

一方で入力は実数ベクトルだけど，離散値を1-hotベクトルなど様々なヒューリスティックで「特徴量」として実数ベクトル化して離散値を扱うことも多い．自然言語処理における離散値データから実数ベクトルを作るテクニックは下記の文献が詳しい．

> 岡崎 直観, "条件付き確率場の理論と実践," 統計数理, 2016  https://www.ism.ac.jp/editsec/toukei/pdf/64-2-179.pdf

## 系列モデルの定義と実装

### 隠れマルコフモデル

<!-- HMMは $y\_t$ が $y\_{t-1}$ によって生成されているという制限を加えた確率モデルです． -->
まず HMM や MRF/CRF といったグラフィカルモデルでは，各時刻で観測した入力データ $x_t$ の $y$ に対する条件付き独立を仮定します．条件付き独立とは数式で表すと各時刻 $t$ における確率の積
<div>
\begin{align}
p(x, y) = \prod_t p(x_t | y) p(y)
\end{align}
</div>
で表せると仮定します．

さらに， HMM では出力(状態)系列にもマルコフ性を仮定しており，こちらも各時刻の積で表せるとします．
<div>
\begin{align}
p(x, y) = \prod_t p(x_t | y) p(y) = \prod_t p(x_t | y_t ) p( y_{t} | y_{t-1} )
\end{align}
</div>


### 条件付き確率場

### CTCとの関係

CTCも系列ラベリングなどでよく使われるやつです．HMMの亜種的な扱いですが，実は CRF と同じで事後確率 $p(y|x)$ を最尤推定してます．それでは何が違うのでしょうか?


## 実験

### 人工データ

### 品詞タグ付け

## まとめ

今後の学習課題として，一般的なグラフ構造を持つ HMM/CRF はまぁまぁ面倒くさそうだけど，グラフ理論とかでてきて面白そうなので継続して既存の実装など見ていきたいですね．
