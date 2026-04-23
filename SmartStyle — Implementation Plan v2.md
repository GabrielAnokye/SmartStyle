# SmartStyle Implementation Journey — v2

Revised implementation plan for SmartStyle, derived from **SmartStyle — Revised Project Plan**. This version closes gaps from v1: adds the laundry state machine to the schema phase, bakes testing into each phase, commits to a TFLite fallback-first strategy, and makes onboarding, RLS, and calendar integration explicit deliverables.

## Decisions Locked Before Phase 1

These were open questions in v1 — locking them now prevents rework later.

| Decision | Choice | Rationale |
| --- | --- | --- |
| State management | **Riverpod** | Lower boilerplate than BLoC, stronger compile-time safety than Provider, good fit for async Supabase streams. |
| ML classification at MVP | **ML Kit generic labels first, custom TFLite post-launch** | Directly follows the risk mitigation in Project Plan §8. Ship faster, train on real user data later. |
| Onboarding | **3-screen interactive tutorial + persistent tooltips on CLO/CPW fields** | Cost-per-wear is the differentiator; it must be felt in session 1 (Project Plan §8). |
| Routing | `go_router` | Standard, declarative, plays well with Riverpod. |
| Serialization | `freezed` + `json_serializable` | Immutable models, free `copyWith`, null-safety. |

## Phase 1 — Setup and Foundation (Weeks 1–2)

**Goal:** user can sign up, authenticate, and see an empty closet.

- Initialize Flutter project; configure iOS (min iOS 14) and Android (min SDK 24) targets.
- Folder structure: feature-first (`lib/features/<feature>/{data,domain,presentation}`) with shared `lib/core/`.
- Supabase project: create, set region, lock free-tier budget alerts.
- **Supabase Auth:** Email + Google OAuth. Write signup/login/logout screens.
- **Row-Level Security:** enable RLS on every table from day one; write base policies (`user_id = auth.uid()`). Non-negotiable.
- `go_router` shell with placeholder routes: Dashboard, Closet, Add Item, Analytics, Profile.
- Riverpod setup: `authProvider`, `supabaseClientProvider`, session listener.
- **Tests:** smoke test for auth flow (sign up → session persists → sign out).
- CI: GitHub Actions running `flutter analyze` + `flutter test` on PR.

## Phase 2 — Core Wardrobe CRUD and Storage (Weeks 3–4)

**Goal:** app is a working (boring) wardrobe tracker with a real, secure schema.

- **Full Supabase schema** including everything from Project Plan §5:
  - `items` table: `item_id`, `user_id`, `created_at`, `image_url`, `ml_detected_category`, `category`, `primary_hex`, `warmth_clo`, `purchase_price`, `occasions TEXT[]`, `fabrics TEXT[]`, `times_worn`, `state` (enum: `clean`/`worn`/`laundry`), `wears_before_laundry INT`, `cost_per_wear NUMERIC`, `last_worn_at`.
  - RLS policies for SELECT/INSERT/UPDATE/DELETE scoped by `user_id`.
  - Generated column or trigger for `cost_per_wear = purchase_price / NULLIF(times_worn, 0)`.
- Dart models with `freezed` + `json_serializable` mirroring the schema exactly.
- **Image pipeline:** client-side compression (target ≤200KB, max 1024px long edge) before upload to Supabase Storage. Document the compression budget — it protects the 1GB free tier.
- Manual item intake UI: single photo + metadata form.
- **Color extraction** (moved earlier from Phase 3): pull dominant hex from the chosen photo during manual intake too — `primary_hex` should never be empty.
- Closet grid: paginated list, filter by category/state, item detail, edit, delete.
- **Tests:** model round-trip serialization; repository CRUD against a local Supabase instance or mocks; widget test for the intake form.

## Phase 3 — Frictionless Intake & ML (Weeks 5–7)

**Goal:** intake drops from ~60s/item to ~10s/item. This is the make-or-break feature.

- Custom camera module with batch mode (continuous capture, thumbnail strip, retake).
- **ML Kit Subject Segmentation** for local background removal; store segmented PNG.
- **Classification — fallback-first strategy (locked decision):**
  - MVP: ML Kit generic image labels mapped to our category taxonomy via a lookup table. Gaps are filled by the user in the review step.
  - Post-launch: swap in a TFLite model trained on DeepFashion2 + real user data. Keep the classifier behind an interface so the swap is a single implementation change.
- Fast-review pipeline: swipe/tap to confirm or edit auto-filled tags (category, color, occasions). Target median confirmation time ≤10s per item; instrument this.
- Empty/error states: segmentation failure, classifier low-confidence banner, offline camera capture queued for later upload.
- **Tests:** widget test for the review swipe flow; golden tests for the segmented preview; unit test for the label-to-category mapping.

## Phase 4 — Contextual Recommendations, Weather & Calendar (Weeks 8–9)

**Goal:** "what should I wear today" returns a usable answer that respects weather, calendar, and laundry state.

- Geolocation: permission flow (foreground only at MVP), graceful fallback to manual city entry.
- Open-Meteo client with response caching (15-min TTL) to stay under rate limits.
- **Calendar read** (Project Plan §B.2, missing in v1): read-only device calendar permission; parse today's events for occasion hints (`gym`, `dinner`, `meeting`). Skippable — users can still tap an occasion manually.
- Recommendation scoring engine (pure Dart, no Flutter deps so it's trivially testable):
  1. Filter `state = 'clean'` **(laundry state machine enforcement)**.
  2. Filter by warmth band matched to feels-like temperature.
  3. Filter by occasion (from calendar or manual tap).
  4. Score: `favorability − recency_penalty + cost_per_wear_bonus`.
  5. Compose outfit by layer rules (base / mid / shell / accessories); return top 3.
- User-rejection feedback: tapping "not this" on a suggestion increments a soft rejection counter used in `favorability`. (Project Plan §B.4, missing in v1.)
- Dashboard UI: top-3 outfit cards, weather summary, quick "log wear" action.
- **Tests:** full unit coverage on the scoring engine — weather bands, state filtering, recency decay, CPW bonus, rejection learning, tie-breaking.

## Phase 5 — Analytics & Wear Economy (Weeks 10–11)

**Goal:** the differentiator is live and visible on the home screen within session 1.

- **Laundry state machine finalized:** logging a wear increments `times_worn`, updates `last_worn_at`, and transitions `clean → worn → laundry` based on `wears_before_laundry`. Laundry items reappear as `clean` when the user marks the load done.
- `cost_per_wear` recompute verified end-to-end (DB trigger + client recalc as belt-and-suspenders).
- Analytics dashboard with `fl_chart`: best/worst value items, total wardrobe value, wear distribution histogram, ghost-item list (>90 days unworn).
- Ghost-item resale draft: generate title + category + photo, copy to clipboard. No marketplace API.
- **Monthly insight notifications** (Project Plan §C, missing in v1): scheduled local notification summarizing best-value item + ghost count. Set up the notification plumbing here so Phase 6 only adds triggers.
- Surface "best-value item this week" on the home dashboard — the differentiator must be felt early, not buried in a tab.
- **Tests:** CPW math, state-machine transitions, ghost detection boundary (89 vs 90 vs 91 days).

## Phase 6 — Polish, Wellness, Packing List & Launch (Weeks 12–13)

**Goal:** launchable MVP.

- Weather-triggered wellness alerts: UV high, cold snap, rain >40%, high wind. Each maps to a specific gear suggestion.
- Packing list generator: destination + dates → Open-Meteo long-range forecast → dynamic checklist pulled from user's wardrobe.
- Local push notifications: daily weather-aware outfit nudge, weekly insight digest.
- Onboarding tutorial (3 screens: intake demo, CPW explanation, daily suggestion demo) + tooltips on CLO and CPW fields.
- Empty states for every screen; global error boundary; offline banner.
- App store assets: icon, screenshots, privacy policy covering camera/location/calendar permissions, TestFlight + Play Internal Testing builds.
- **Tests:** end-to-end smoke test of the full intake → suggestion → wear-log → analytics loop.

## Cross-Cutting Concerns (not phase-specific)

- **RLS coverage check** before any new table ships.
- **Image payload budget:** reject client uploads >200KB; log compression ratio in analytics.
- **Free-tier guardrails:** Supabase dashboard budget alerts at 70% of each quota.
- **Privacy:** all ML runs on-device; document this in onboarding and the privacy policy — it's a trust advantage over competitors.
- **Observability:** Sentry (free tier) for crash reporting from Phase 1.

## Verification Plan

### Per-phase test expectations
| Phase | Required tests before moving on |
| --- | --- |
| 1 | Auth flow smoke test; CI green. |
| 2 | Model serialization; CRUD repository tests; RLS policies verified via failing-case tests. |
| 3 | Review-flow widget tests; classifier mapping unit tests; intake time instrumented. |
| 4 | Scoring engine unit tests (≥90% branch coverage); calendar parser tests. |
| 5 | CPW math, state transitions, ghost detection boundaries. |
| 6 | End-to-end smoke test; manual QA matrix below. |

### Manual QA matrix for launch
- Segmentation accuracy across: dark items on dark backgrounds, patterned items, shoes, accessories.
- Weather logic branches: spoofed locations for cold snap, heatwave, heavy rain, high UV.
- Calendar integration: event with known keyword, event without, calendar permission denied.
- Offline mode: capture photos offline, verify queued upload on reconnect.
- Free-tier load: 200 items per test user, verify gallery pagination and storage usage.

## Risks & Mitigations (carried from Project Plan §8)

| Risk | Mitigation in this plan |
| --- | --- |
| Custom TFLite accuracy disappoints | Locked fallback-first strategy; classifier behind an interface. |
| Differentiation not felt in session 1 | CPW tutorial in onboarding; best-value surfaced on home dashboard in Phase 5. |
| Retention drop after week 1 | Weather-aware daily nudge + weekly digest + packing list re-engagement hook (Phase 6). |
| Supabase free tier breach | Image compression budget; dashboard alerts; per-user storage ceiling. |

## Task Checklist

### Phase 1 — Setup (Weeks 1–2)
- [ ] Flutter project init (iOS 14+, Android SDK 24+).
- [ ] Feature-first folder structure.
- [ ] Supabase project + free-tier budget alerts.
- [ ] Supabase Auth (Email + Google).
- [ ] RLS enabled on all tables from day one.
- [ ] `go_router` shell with placeholder routes.
- [ ] Riverpod session providers.
- [ ] Sentry wired up.
- [ ] CI running analyze + test.
- [ ] Auth smoke test.

### Phase 2 — CRUD & Storage (Weeks 3–4)
- [ ] Full schema with occasions, fabrics, state, wears_before_laundry.
- [ ] RLS policies per table.
- [ ] `cost_per_wear` DB trigger.
- [ ] `freezed` models matching schema.
- [ ] Image compression pipeline (≤200KB).
- [ ] Manual intake UI.
- [ ] Color extraction in manual flow.
- [ ] Paginated closet grid + filters + detail + edit + delete.
- [ ] Model + repository tests.

### Phase 3 — Intake & ML (Weeks 5–7)
- [ ] Batch camera module.
- [ ] ML Kit Subject Segmentation.
- [ ] ML Kit label → category mapping (fallback-first).
- [ ] Classifier interface for future TFLite swap.
- [ ] Fast-review swipe UI with intake-time instrumentation.
- [ ] Offline capture queue.
- [ ] Review-flow widget tests.

### Phase 4 — Recommendations (Weeks 8–9)
- [ ] Geolocation with manual-city fallback.
- [ ] Open-Meteo client + 15-min cache.
- [ ] Calendar read permission + event parser.
- [ ] Pure-Dart scoring engine.
- [ ] Laundry state filter enforced in engine.
- [ ] Outfit composition rules.
- [ ] Rejection feedback loop.
- [ ] Home dashboard with top-3 cards.
- [ ] Scoring engine unit tests (≥90% branches).

### Phase 5 — Analytics (Weeks 10–11)
- [ ] State machine (clean/worn/laundry) with wear logging.
- [ ] `fl_chart` analytics dashboard.
- [ ] Ghost detection (>90 days).
- [ ] Resale draft to clipboard.
- [ ] Monthly insight notification plumbing.
- [ ] Best-value surfaced on home dashboard.
- [ ] State-machine + CPW + ghost boundary tests.

### Phase 6 — Polish & Launch (Weeks 12–13)
- [ ] Wellness alerts (UV / cold / rain / wind).
- [ ] Packing list generator.
- [ ] Daily + weekly push notifications.
- [ ] 3-screen onboarding + tooltips.
- [ ] Empty states + global error boundary + offline banner.
- [ ] Privacy policy, store assets, TestFlight + Play Internal builds.
- [ ] End-to-end smoke test.
- [ ] Manual QA matrix signed off.
