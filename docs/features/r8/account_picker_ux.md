# Feature: Account Picker UX Redesign

## Vấn đề

Hiện tại `AccountPickerScreen`:
- **Tap** account card → select account ✅
- **Long press** family card → mở `FamilyDetailScreen` ❌

Vấn đề:
1. **Không discoverable** — không hint, không visual cue cho long press
2. **Vi phạm gesture guide** — long press phải có hint text
3. **Metadata ở sai chỗ** — quản lý members/invite nằm sau gesture ẩn thay vì ở Settings

## Giải pháp

- **Bỏ long press** trên account card
- **Tap** = select account (giữ nguyên)
- **Swipe left** family card = xóa/rời family (destructive — đúng gesture map)
- **Family metadata** (members, invite, activity) → chuyển vào **SettingScreen** khi user đang ở family account

---

## 1. Account Picker — Đơn giản hóa

### Card

```
┌─────────────────────────────────┐
│ 👤 Cá nhân                    › │  ← tap = select
└─────────────────────────────────┘
┌─────────────────────────────────┐  ← swipe left = leave/delete
│ 👥 Sổ gia đình  3 thành viên  › │  ← tap = select
└─────────────────────────────────┘
```

- **Tap** = select account → SplashBootstrapScreen
- **Swipe left** (family only) = hiện nút đỏ:
  - Owner → "Xóa" → `DeleteConfirmation` → `deleteFamily()`
  - Member → "Rời" → `DeleteConfirmation` → `leaveFamily()`
- Personal account không swipe được (không thể xóa personal)
- Bỏ `onLongPress` hoàn toàn

---

## 2. Setting Screen — Thêm Family Section

Khi user đang ở **family account** (`sl.cache.currentAccount?.isFamily`), SettingScreen hiện thêm section "Nhóm":

```
── Nhóm ──
👥 Thành viên (3)              →    ← tap = mở member list
📨 Mời người thân              →    ← tap = invite dialog
📋 Hoạt động                   →    ← tap = activity feed
🚪 Rời nhóm                         ← owner: "Xóa nhóm"
```

Khi ở **personal account** → ẩn section này.

### Member List

Reuse nội dung từ `FamilyDetailScreen._buildMembersSection()` — tách thành widget hoặc screen riêng:
- Hiện danh sách members (avatar, name, email, owner badge)
- Owner có thể remove member (icon button)

### Invite

Reuse `_inviteByEmail()` từ `FamilyDetailScreen` — dialog nhập email.

### Activity

Reuse `_buildActivitySection()` từ `FamilyDetailScreen` — stream activities.

---

## 3. Migration

- `FamilyDetailScreen` → giữ lại nhưng không navigate từ AccountPicker nữa. Có thể dùng từ SettingScreen hoặc inline sections.
- Hoặc: tách `FamilyDetailScreen` thành các widget nhỏ (`MemberListSection`, `ActivitySection`) rồi embed vào SettingScreen.

---

## 4. Ảnh hưởng

| File | Thay đổi |
|------|----------|
| `account_picker_screen.dart` | Bỏ `onLongPress`. Wrap family cards trong `SwipeListItem` (swipe = leave/delete). Bỏ import `FamilyDetailScreen` |
| `setting_screen.dart` | Thêm "Nhóm" section khi `isFamily`: members, invite, activity, leave/delete |
| `family_detail_screen.dart` | Tách thành reusable widgets hoặc giữ nguyên dùng từ settings |

---

## 5. L10n Keys

Không cần thêm — dùng keys đã có: `members`, `inviteMember`, `activity`, `leaveFamily`, `deleteFamily`.
