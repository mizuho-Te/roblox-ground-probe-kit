# Roblox Ground Probe Kit

[English](README.md) · [検証記録](TESTING.md)

自分のゲームの「床が近くにある／空中らしい」という仮説を、観測ログと純粋な判定関数に分けて確認する小さな開発者用キットです。

MIT ライセンス。Copyright (c) 2026 mizuho-Te。[LICENSE](LICENSE) を参照してください。

## できること

- 距離・法線・上向き速度・必要ヒット数を設定して判定する純粋 Luau モジュール。
- 合成フレームの記録再生と境界テスト。実際の公式 Luau 0.743 で 443 assertions 成功。 2026-10-21 の [GitHub Actions](https://github.com/mizuho-Te/roblox-ground-probe-kit/actions/runs/39575296068) でも 443 件、静的解析、Studio スクリプトの構文コンパイルが成功しました。CI では Studio 本体や物理検証は実行していません。
- Studio 用 Raycast 観測サンプル、平地・坂・段差・端・ジャンプの練習用シーン生成スクリプト。

万能な接地判定、不正検出、キック・BAN、ゲームの物理修正ではありません。既存ゲームのコード・キャラクター・非公開データは使用していません。

## 判定の意味

- supported：設定した閾値内の支持面を Raycast で観測。着地や物理接触の保証ではありません。高速落下中でも床が近ければ該当します。
- airborne：coverage が known で必要数の支持面を観測できない場合、または必要数の支持面を検出したうえで上向き速度が閾値を超える場合です。速度だけでは決まりません。支持面が足りず coverage が unknown なら、高速上昇中でも unknown です。不正の証拠ではありません。
- unknown：情報不足・不正な入力。失敗時は安全側として処罰や移動強制に使わないでください。

ヒットなしだけでは、床がないのか、フィルターで除外されたのか、Streaming で未読込なのか分かりません。coverage="known" は開発者自身が管理された場面で観測範囲の十分性を確認した場合だけ指定します。StreamingEnabled=false から自動推定しません。サンプルの初期値は unknown です。実際に支持面を検出できた場合は coverage が unknown でも supported になり得ます。

## 実行

[公式 Luau 0.743](https://github.com/luau-lang/luau/releases/tag/0.743) を取得して PATH に配置し、プロジェクト直下で実行します。

```sh
luau tests/run.luau
luau-analyze src/GroundProbe.luau tests/run.luau
```

距離は Ray 原点からの studs、速度は世界 Y 軸の studs/秒、normalY は正規化済み法線の Y 成分。距離・傾斜の境界は含み、上昇速度による空中判定は、必要数の支持面を検出した後で、速度が閾値より大きい場合に適用します。同じ面を複数の Ray が捉えた場合もそれぞれ数えます。

## Studio で使う準備

実ゲームではなく、新しい空白の使い捨て Place で行ってください。

1. ReplicatedStorage に GroundProbeKit フォルダーを作り、その中に GroundProbe と Observer の ModuleScript を作成。src/GroundProbe.luau と studio/Observer.luau を貼ります。
2. studio/CreateTestScene.server.luau を ServerScriptService の Script に貼ります。実行時に新しいフォルダーを作るだけで、既存オブジェクトは削除しません。床なしを試す場合は、この使い捨て空白 Place のテンプレート Baseplate だけ CanCollide=false と CanQuery=false の両方を設定します。実ゲームの床には適用しません。
3. studio/Observe.client.luau を StarterPlayerScripts の LocalScript に貼り、Play して Output を確認します。
4. 各リグの root 高さ・スケールに合わせて距離・半径を手動調整。3 studs は例示であり、汎用の推奨値ではありません。
5. 平地・坂・段差・端・ジャンプ着地を観察し、TESTING.md の記録欄に期待値との差を書きます。
6. Streaming の設定変更と複数クライアントも別途検証します。Streaming 有効・複数クライアントの検証は未実施です。

サンプルはキャラクターを除外して下向きに 5 本観測します。CollisionGroup・CanQuery・CanCollide と Streaming 設定を確認できます。RespectCanCollide=false のため、衝突しない装飾でも CanQuery=true なら検出対象になり得ます。目的に応じたフィルターが必要です。検出されなかった物体の設定は Raycast 結果からは分かりません。

ログは個人識別子を含まない JSON。100 フレームだけメモリーに保持し、外部へ送信しません。再生する場合は JSON の数値を tests/synthetic-recording.luau と同じ Luau テーブル形式へ手動で写してください。JSON をそのまま require はできません。

足の端・狭い足場・動く床・水泳・登り・回転・通信遅延・独自リグでは別途設計が必要です。Humanoid の状態連携、足裏接触、ヒステリシス、不正対策の実装は含みません。CLI テスト成功は Studio の物理や多人プレイの成功を意味しません。

公式資料：[Raycasting](https://create.roblox.com/docs/workspace/raycasting) ／ [Studio testing modes](https://create.roblox.com/docs/studio/testing-modes) ／ [Luau](https://luau.org/getting-started/)

再生フレームは欠番のない配列が必要です。欠番や配列以外のキーは、黙って再生を打ち切らず明示エラーにします。ヒット配列の欠番は unknown になります。Studio Observer は開発者向けサンプルです。有効な character/root、登録済み CollisionGroup、正の有限な castLength（15,000 studs 以下）、0 以上の有限な radius を指定してください。不正な設定は純粋判定の前に Roblox API の例外になる場合があります。外部からの未検証入力向け API ではありません。

## 限定的な Studio 観測結果

2026-10-21、Studio 0.743.0.7431133 の新規非公開 Place、R6 1 種、単一ローカルセッションで観測しました。自動 Humanoid Move/Jump による 12 区間・1,093 Heartbeat フレームであり、1,093 件の独立したテストではありません。内訳は supported 941、airborne 84、unknown 68。

坂歩行は 61 フレーム中 48、段差歩行は 120 中 29 が airborne でしたが、それらの全フレームで Humanoid は Running、FloorMaterial は Plastic でした。このため、そのまま接地判定の正解として採用せず、リグと用途に合わせた設定が必要です。上向き速度や距離の閾値が分類へ影響します。CanQuery・CollisionGroup によるヒットの変化も確認しました。

ログの長い JSON は一部省略され、全フレームの生ログは保存できていません。集計と代表観測を使った限定的な検証です。R15、他スケール、動く床、実機モバイル、複数クライアント、Streaming 有効は未検証。詳細条件・観測値・残課題は [TESTING.md](TESTING.md) を参照してください。
