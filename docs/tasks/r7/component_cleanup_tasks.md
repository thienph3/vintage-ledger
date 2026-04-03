# Tasks: Component Cleanup — Remove Vintage Artifacts

Bỏ các element vintage không phù hợp style guide mới.

| # | Task | File(s) | Detail |
|---|------|---------|--------|
| 1 | LedgerHeader → AppHeader | `ledger_header.dart` → rename | Bỏ Divider bottom (vintage feel). Clean AppBar, soft title weight 600. Rename class + file |
| 2 | LedgerCard → SoftCard | `ledger_card.dart` → update | Bỏ border. Subtle shadow only. Background `surface` white. Radius 16. Rename optional |
| 3 | AmountText color | `amount_text.dart` | Income: gentle green `#5BA37C`. Expense: warm orange `#D4845A`. Bỏ harsh red/green |
| 4 | SwipeListItem background | `swipe_list_item.dart` | Delete background: warm orange thay vì red. Softer feel |
| 5 | EmptyState style | `empty_state.dart` | Larger emoji, friendly text, soft color. Không dùng grey |
| 6 | IncomeExpenseSummaryRow | `income_expense_summary_row.dart` | Softer colors. Casual labels ("Thu" / "Chi" thay vì "Tổng thu" / "Tổng chi") |
| 7 | TypeSelector | `type_selector.dart` | Soft toggle style. Muted colors. Không dùng harsh blue/red |
| 8 | FormSaveButton | `form_save_button.dart` | Soft blue, rounded 20. Text weight 600 (not bold typewriter) |
| 9 | DeleteConfirmation dialog | `delete_confirmation.dart` | Casual tone: "Xóa luôn hả?". Soft button colors |
| 10 | NetworkStatusBanner | `network_status_banner.dart` | Softer: muted orange background, friendly text "Đang offline — dữ liệu sẽ đồng bộ sau" |
| 11 | LoginPromptCard | `login_prompt_card.dart` | Evaluate: có còn cần không? Nếu giữ → casual tone, soft style |
