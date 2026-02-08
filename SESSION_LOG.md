# セッションログ - TODO カレンダーアプリ

## 絶対ルール
- git push -f は絶対禁止
- 成功したコードに上書きしない
- 変更前に必ず git log で状態確認
- サンドボックスリセット後は現在の状態を完全に把握してから操作
- 各Phase成功後に通常pushでGitHubに保存
- GitHubがマスターデータ

## 復元ポイント（上書き禁止）
| 名前 | コミット | 内容 |
|---|---|---|
| STABLE_v1_57009eb | 57009eb | 全機能復旧+祝日バー修正+振動無効化+ミニバー4本 |
| STABLE_v2_2e797fb | 2e797fb | v1 + 全カテゴリリスト機能+リスト共有バグ修正 |

バックアップURL:
- STABLE_v1: https://www.genspark.ai/api/files/s/FgckSzdz
- STABLE_v2: https://www.genspark.ai/api/files/s/9aJWaoIh

## 現在の状態（STABLE_v2 時点）
- コミット: 2e797fb
- GitHub: https://github.com/take-ae86/todo-app.git
- 公開URL: https://take-ae86.github.io/todo-app/
- ローカル・リモート一致確認済み

## 完了済み機能
1. データモデル拡張（endTime/endDate/isAllDay）
2. モーダル入力UI（終日切替・開始日・終了日・終了時間）
3. タイムライン15分刻み + バー高さ連動 + 終日0:00-1:00表示
4. 空白タップ→ポッチ枠UI（新規作成用）
5. カレンダー複数日横バー（アイコンのみ）
6. ミニバー（h16, max4, アイコン+時間/終日）
7. 日付ピッカー日本語化
8. メモ詳細ハイパーリンク化（一覧も含む、アンダーバーなし）
9. バイブ無効化（navigator.vibrate無効化 + テーマfeedback無効化）
10. ドラッグ移動（開始/終了同時移動）
11. ポッチハンドル拡大 + ドラッグ修正
12. 開始日=終了日で初期表示
13. 祝日ラベルの下に横バー配置（隙間付き）
14. 祝日セルでもミニバー4本表示
15. 全カテゴリにリスト機能追加（買い物リスト/メニューリスト/タスクリスト等）
16. カテゴリ変更時にリストクリア（共有バグ修正）

## ブルブル（振動）問題の結論
- 原因: FlutterのMaterialウィジェット（TextField, ElevatedButton, Switch, DatePicker等）のハプティックフィードバック
- カレンダーセル・フッター等はGestureDetectorで自作なので振動なし
- 対策: web/index.htmlでnavigator.vibrate無効化 + テーマでenableFeedback:false
- APK版で振動が出る場合はAndroidManifestからVIBRATE除外が必要

## 次の作業：複数日TODO親子構造（未実装）

### 仕様① モーダルレイアウト変更
- 現状: 日付と時間が別々に配置
- 変更後: 日付の横に時間を配置
  - 開始 2026/1/28 12:00
  - 終了 2026/1/31 13:00
- タップで日付ピッカー/時間ピッカーが出る

### 仕様② 複数日TODOの親子構造

#### 親（複数日TODO）モーダル
- タイトル: あり
- 期間（開始日時〜終了日時）: あり
- カテゴリ: なし（複数日にした瞬間に消える）
- 追加リスト: なし（複数日にした瞬間に消える）
- 詳細: なし（複数日にした瞬間に消える）
- 該当日付ボタン: あり（期間設定した瞬間に表示）

#### 子（各日付TODO）モーダル
- タイトル: なし（親のタイトルが継承される）
- カテゴリ: あり
- 追加リスト: あり
- 時間: あり
- 詳細: あり

#### 表示
- カレンダー横バー: タイトル + 期間
- 時間バー: タイトル + 期間
- 子の時間バー: アイコン + 時間

#### 導線（複数日TODO）
1. カレンダーの日付タップ
2. 時間バー表示（アイコン + タイトル + 期間 例: 2/7 12:00〜2/11 14:00）
3. 時間バータップ → モーダルに該当日付ボタン表示（2/7, 2/8, 2/9, 2/10, 2/11）
4. 日付ボタンタップ → 該当日専用の時間バー
5. 該当日専用モーダル（カテゴリ・追加リスト・時間・詳細）

#### 重要ポイント
- 各日のデータは独立（2/8のメモは2/8だけに保存、他の日には共有しない）
- 親モーダルで期間設定した瞬間にカテゴリ・追加リスト・詳細が消えて日付ボタンが表示される
- 子モーダルはその日の中でしか見れない

## カテゴリ別リスト名（全10カテゴリ）
| カテゴリ | リスト名 |
|---|---|
| 買い物 | 買い物リスト |
| 食事 | メニューリスト |
| 遊び | やることリスト |
| 仕事 | タスクリスト |
| 休み | 予定リスト |
| 学校 | 課題リスト |
| 交通 | 乗換リスト |
| 旅行 | 持ち物リスト |
| 趣味 | やりたいリスト |
| その他 | チェックリスト |

## ファイル構成
- lib/main.dart - アプリエントリポイント + HomeScreen + Header + Footer
- lib/models/todo_model.dart - TodoItem, ShoppingItem, MemoItem
- lib/providers/app_provider.dart - 状態管理（todos, memos, darkMode等）
- lib/services/storage_service.dart - Hive永続化
- lib/screens/calendar_month_view.dart - カレンダー月表示
- lib/screens/timeline_day_view.dart - タイムライン日表示
- lib/screens/memo_view.dart - メモ帳
- lib/widgets/add_edit_modal.dart - TODO追加/編集モーダル
- lib/widgets/detail_modal.dart - 詳細表示モーダル
- lib/widgets/shopping_list_modal.dart - チェックリストモーダル（全カテゴリ共通）
- lib/widgets/time_picker_widget.dart - 時間ピッカー
- lib/utils/constants.dart - 定数・カテゴリ・色・アイコン
- lib/utils/holidays.dart - 2026年祝日データ
