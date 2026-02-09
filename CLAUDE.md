# Campus Nerds - Project Guide for AI Agents

## Project Overview

Campus Nerds (校園裡的書呆子) is a university student social event platform built with Flutter + Supabase, targeting Taiwanese college students. Users register for two types of events: **Focused Study (專注讀書)** and **English Games (英文遊戲)**, are auto-grouped with strangers, and interact through group chat.

- **Package:** `app.campusnerds.app`
- **Primary Language:** Traditional Chinese (Taiwan)
- **Backend:** Supabase (PostgreSQL + Edge Functions + Realtime)

## Architecture

### Frontend (Flutter)

- **Pattern:** Clean Architecture (Presentation → Domain → Data)
- **State Management:** BLoC pattern (`flutter_bloc`)
- **DI:** GetIt + Injectable
- **Routing:** GoRouter with auth guard
- **9 feature modules:** auth, onboarding, home, my_events, checkout, chat, account, ticket_history, facebook_binding

### Backend (Supabase)

- **25+ tables** with RLS policies
- **11+ database views** (e.g., `home_events_v`, `my_events_v`, `user_profile_v`)
- **20+ stored functions** for business logic
- **9 Edge Functions** for external integrations (Facebook, ECPay, email verification)
- **Cron job:** Daily at 00:00 Taipei time via `run-auto-grouping` Edge Function

### Key Patterns

- **Singleton BLoCs** for cross-navigation caching: `CheckoutBloc`, `TicketHistoryBloc`, `FacebookBindingBloc`
- **Stale-while-revalidate:** Used in `TicketHistoryBloc`, `OnboardingBloc`, `FacebookBindingBloc` — show cached data immediately, refresh in background
- **Type-safe Supabase access:** `SupabaseTable<T>` / `SupabaseDataRow` wrappers in `lib/data/models/tables/`

## Intentional Design Decisions

### Facebook Friend Avoidance (Permanent)

**Design:** Once two users are identified as Facebook friends, the friendship record in the `friendships` table is **never deleted**. This is intentional.

- Unbinding Facebook clears `users.fb_user_id` and `fb_access_token`, but does NOT delete `friendships` rows
- Rebinding a different Facebook account adds new friendships on top of old ones
- If two users unfriend each other on Facebook, the `friendships` record persists
- Sync functions (`sync-facebook-friends`, `run-auto-grouping`) only UPSERT, never DELETE

**Rationale:** "Once friends, always avoided" — maximize the chance of meeting strangers by maintaining the union of all known friend relationships across all Facebook accounts ever linked.

### Auto-Grouping Algorithm

- Runs 48 hours before each event via cron job
- Creates groups with **flexible even sizes** (`events.default_group_size`, must be even)
- Enforces **1:1 gender ratio**
- **Iteratively assigns** members to groups, actively avoiding Facebook friends
- Prioritizes users with high `not_grouped_count` (those who haven't been grouped recently)
- Uses `pg_advisory_xact_lock` to prevent concurrent grouping
- Groups are created as `draft` → staff confirms → `scheduled` (trigger validates constraints)

### Ticket System

- Separate balances for study and games tickets
- Append-only `ticket_ledger` for audit trail
- Atomic booking: `create_booking_and_consume_ticket` (deducts ticket in same transaction)
- Atomic cancellation: `cancel_booking_and_refund_ticket`

### Profile Avatar

- Male users: `Gemini_Generated_Image_wn5duxwn5duxwn5d.png`
- Female users: `Gemini_Generated_Image_ajjb8yajjb8yajjb.png`
- No network avatars — gender-based local assets only

### Theme

- **Low-saturation** color palette (grays, near-whites)
- Avoid high-saturation colors like `Colors.green`, `Colors.red` in UI
- Use theme colors: `colors.alternate`, `colors.tertiary`, `colors.secondaryText` for status indicators
- `AppColors.success` (#249689) and `AppColors.error` (#B95755) exist but are reserved for SnackBars/semantic use, not prominent UI blocks

## Project Structure

```
lib/
├── app/                    # Router, theme
├── core/                   # DI, services, errors, utils
├── data/                   # Repository impls, Supabase table models
│   ├── models/tables/      # 37 type-safe table wrappers
│   └── repositories/       # 9 repository implementations
├── domain/                 # Entities (8), repository interfaces (9)
└── presentation/
    ├── common/widgets/     # Shared widgets (AppConfirmDialog, etc.)
    └── features/           # 9 feature modules (bloc + pages + widgets)

supabase/
├── functions/              # 9 Edge Functions (Deno/TypeScript)
├── migrations/             # DDL migrations
└── schema.sql              # Full schema snapshot
```

## Edge Functions

| Function | Purpose | Auth |
|----------|---------|------|
| `sync-facebook-friends` | Sync FB friends, exchange for long-lived token | JWT |
| `run-auto-grouping` | Cron: sync friends + auto-seed groups | Service role |
| `confirm-group` | Staff confirms draft group | Staff |
| `send-school-email-code` | Send OTP to .edu.tw email | JWT |
| `verify-school-email-code` | Verify OTP | JWT |
| `ecpay_create_order` | Create pending order | JWT |
| `ecpay_pay` | Generate ECPay payment form | Public (token) |
| `ecpay_return` | ECPay webhook callback | Public |
| `ecpay_client_result` | Payment result redirect | Public |

## Event Lifecycle (Booking → Event Day)

### Phase 1: Event Creation (Admin)

- `trg_set_event_signup_times` auto-calculates:
  - `signup_open_at` = event_date - 23 days (00:00 Taipei)
  - `signup_deadline_at` = event_date - 3 days (23:59 Taipei)
  - `notify_deadline_at` = event_date - 2 days (23:59 Taipei)

### Phase 2: Registration Window (User, event_date-23d ~ event_date-3d)

- **User books:** `create_booking_and_consume_ticket` — booking status=active, deduct 1 ticket
  - Validates: profile complete, has university, event is scheduled, within signup window, no same-slot conflict, sufficient tickets
  - For focused_study events: `trg_create_study_plans_on_booking` auto-creates 3 empty study plan slots
- **User cancels:** `cancel_booking_and_refund_ticket` — booking status=cancelled, refund 1 ticket
  - Must be within signup window

### Phase 3: Auto-Grouping (Cron, event_date-2d 00:00 Taipei)

- **Triggered by:** pg_cron `0 16 * * *` (16:00 UTC = 00:00 Taipei) → calls `run-auto-grouping` Edge Function via pg_net
- Edge Function syncs Facebook friends for all registered users with stored tokens (calls Facebook Graph API)
- Calls `auto_seed_groups_for_event` RPC for each qualifying event
- Creates groups with status=**draft**, assigns members avoiding FB friends
- Priority: `not_grouped_count` DESC → age → academic_rank → OS → avg_performance_score DESC → booking time

### Phase 4: Staff Confirms Groups (Staff, manual)

- **How:** Staff manually changes `groups.status` from `draft` → `scheduled` (or calls `confirm-group` Edge Function which does additional FB sync first)
- **`handle_group_status_scheduled` trigger fires** and validates:
  - Group is full (member_count = max_size)
  - 1:1 gender ratio
  - venue_id is set
  - All timing fields are set
  - NO Facebook friends in the group
- **If any validation fails, the status change is REJECTED** — `groups.status` remains `draft`
- On success, trigger auto-creates:
  - Focused study: `create_focused_study_plans_for_group` (3 goal slots per member)
  - English games: `assign_english_contents_for_group` (unique content per member)
- `trg_set_group_times` auto-calculates from venue schedule:
  - `chat_open_at` = venue.start_at - 1 hour
  - `goal_close_at` = venue.start_at + 1 hour
  - `feedback_sent_at` = event_date 12:00/17:00/22:00 (morning/afternoon/evening)
  - `goal_check_close_at` = event_date 13:00/18:00/23:00

### Phase 5: Notification (Staff, manual)

- **How:** Staff manually changes `events.status` from `scheduled` → `notified`
- **`trg_events_status_notified` trigger fires** and validates:
  - Status transition must be exactly scheduled → notified
  - ALL groups for this event must be status=`scheduled` (no remaining `draft` groups)
- **If any validation fails, the status change is REJECTED** — `events.status` remains `scheduled`
- On success, creates `in_app_notifications` for all registered users:
  - Grouped users: "您已成功分組"
  - Ungrouped users: "這次活動沒有成團" (get priority next time via `not_grouped_count`)

### Phase 6: Event Day

| Time | Event | Trigger |
|------|-------|---------|
| `chat_open_at` (venue start - 1hr) | Chat opens | Automatic (time-based) |
| venue start | Event begins | — |
| `goal_close_at` (venue start + 1hr) | Goal editing closes | Automatic |
| `feedback_sent_at` (12:00/17:00/22:00) | Feedback window opens | Automatic |
| `goal_check_close_at` (13:00/18:00/23:00) | Goal check-off closes | Automatic |

### Phase 7: Post-Event

- `run_move_events_to_history`: event status notified → completed (day after event)

### Status Progressions

```
Events:  draft → scheduled → notified → completed
Groups:  draft → scheduled (staff confirms, trigger validates)
Bookings: active → cancelled (user cancels, optional)
```

### Trigger Summary

| Trigger | Fires On | Purpose |
|---------|----------|---------|
| `trg_set_event_signup_times` | events INSERT/UPDATE | Calculate signup windows |
| `trg_set_group_times` | groups INSERT/UPDATE | Calculate chat/goal/feedback times from venue |
| `handle_group_status_scheduled` | groups UPDATE (draft→scheduled) | Validate group, create study plans/content |
| `trg_events_status_notified` | events UPDATE (scheduled→notified) | Validate all groups confirmed, send notifications |
| `trg_groups_require_venue_on_scheduled` | groups UPDATE | Enforce venue_id when scheduling |
| `trg_groups_enforce_venue_matches_event` | groups UPDATE | Venue city must match event city |
| `trg_create_study_plans_on_booking` | bookings INSERT (focused_study) | Auto-create 3 study plan slots at booking time |

## EventDetailsPage UI Presentation Logic (Focused Study)

The `EventDetailsPage` displays booking details with two tabs: 待辦事項 (study plans) and 聊天室 (chat). The page adapts to the event lifecycle phase.

### Status Badge (top-right)

| `event_status` | Badge Text |
|----------------|-----------|
| `scheduled` / `notified` | 已報名 |
| `completed` | 已結束 |
| other | (hidden) |

- Style: `tertiaryText` bg, `secondaryBackground` text, rounded 8, NO shadow

### Buttons Row (規則 + 取消報名/填寫問券)

Two buttons at the same position, shown based on lifecycle:
- **取消報名**: visible when `feedbackSentAt == null` (scheduled phase)
  - Pressable (bg = `tertiaryText`): before `signupDeadlineAt`
  - Disabled (bg = `tertiary`): after `signupDeadlineAt`
- **填寫問券**: visible when `feedbackSentAt != null` (notified/completed phase)
  - Pressable (bg = `tertiaryText`): after `feedbackSentAt` AND `!hasFilledFeedbackAll`
  - Disabled (bg = `tertiary`): otherwise
- Text color: `secondaryBackground`, NO shadow

### Study Plans (待辦事項) — Time-gated Editing

Study plan slots (3 per user) are auto-created at booking time via DB trigger `trg_create_study_plans_on_booking`.

| Phase | `canEditGoalContent` | `canCheckGoal` | Edit icon? | Can edit text? | Can check? |
|-------|---------------------|---------------|-----------|----------------|------------|
| After booking (no group) | true (goalCloseAt null) | false (groupStartAt null) | Yes | Yes | No |
| After grouping, before venue start | true | false | Yes | Yes | No |
| After venue start, before goalCloseAt | true | true | Yes | Yes | Yes |
| After goalCloseAt, before goalCheckCloseAt | false | true | Yes | No | Yes |
| After goalCheckCloseAt | false | false | No | No | No |

- **Pre-grouping**: Only the user's own card shown (loaded via `get_my_focused_study_plans` RPC)
- **Post-grouping**: All group members' cards shown (loaded via `get_group_focused_study_plans` RPC)
- **StudyPlanCard**: header "書呆子 [nickname]", 3 numbered goals, edit/check icons per timing
- **EditGoalDialog**: Text field shown only when `canEditContent`; checkbox shown only when `canEditCompletion`

### Dialog Design Pattern (FlutterFlow standard)

All dialogs use: `Dialog(transparent bg, elevation 0)` → `Container(579w, secondaryBackground, tertiary border 2, rounded 12)` → `Padding(h:16)` → `Column`

Buttons: two `Expanded` buttons — "取消" (secondaryBackground bg, tertiary border, elevation 0.2, rounded 12) + "確定" (alternate bg, elevation 0, rounded 12)

### Chat Tab

- Chat opens at `chatOpenAt` (venue start - 1 hour)
- Before open: shows "聊天室尚未開放" message
- Uses Supabase Realtime for live messages

## Mock Time System (Integration Testing)

A global mock time system allows testing the entire event lifecycle without waiting for real time to pass. When enabled, **both** Supabase and Flutter use the same fake clock.

### How It Works

- **Supabase:** `public.now()` overrides `pg_catalog.now()` using a stored time offset. All RPC functions, triggers, views, and RLS policies resolve `now()` through this override (via `search_path = 'public', 'pg_catalog'`).
- **Flutter:** `AppClock.now()` replaces all `DateTime.now()` calls. On app startup, it syncs with the server's `get_server_now()` RPC and stores the offset locally. **In release mode, sync is skipped entirely** — no network call, no latency, `AppClock.now()` = `DateTime.now()`.
- **Offset-based:** Time still flows naturally (advances in real-time), just shifted by the offset. No drift between client and server.

### Usage

```sql
-- Set mock time (Supabase SQL Editor or Admin Dashboard)
SELECT test_set_now('2026-02-20 10:00:00+08');

-- Check current mock time
SELECT now();

-- Clear mock time (revert to real time)
SELECT test_clear_now();
```

After setting/clearing mock time, **restart the Flutter app** to re-sync `AppClock`.

### Security

- `test_set_now()` and `test_clear_now()` are **restricted to `service_role` only** — regular authenticated/anonymous users cannot call them
- Only accessible via Supabase SQL Editor, admin dashboard, or service_role API key
- `get_server_now()` remains callable by authenticated users (harmless — only returns current time)
- In release builds, Flutter never calls `get_server_now()` at all

### Key Rules

- **Never use `DateTime.now()` directly** in Flutter code — always use `AppClock.now()`
- The only file that uses `DateTime.now()` is `lib/core/utils/app_clock.dart` itself
- In release mode, `AppClock.syncWithServer()` is a no-op — zero overhead, zero latency
- In debug/profile mode, syncs with server to pick up any mock time offset
- The `test_config` table stores the offset; it has RLS enabled with no policies (only accessible via SECURITY DEFINER functions and service_role)

### Files

- `lib/core/utils/app_clock.dart` — Flutter clock utility
- `supabase/migrations/20260209061100_add_mock_time_system.sql` — Supabase migration
- `supabase/migrations/20260209120000_restrict_mock_time_permissions.sql` — Permission lockdown

## Common Commands

```bash
# Run Flutter app
flutter run

# Build APK
flutter build apk

# Code generation (injectable)
flutter pub run build_runner build --delete-conflicting-outputs
```

## Important Notes

- Supabase project URL: `https://lzafwlmznlkvmbdxcxop.supabase.co`
- ECPay integration supports both stage and production environments
- Facebook `user_friends` permission requires App Review for production
- Long-lived FB tokens expire after 60 days; expired tokens (error code 190) are auto-cleared during sync
