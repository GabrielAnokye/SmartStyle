# **SmartStyle — Revised Project Plan**

*Intelligent wardrobe, wellness, and wear-economy assistant*

## **1\. Executive Summary**

SmartStyle is a mobile app that digitizes a user's wardrobe and gives them three things no existing free app combines well: **(1)** weather- and context-aware outfit suggestions, **(2)** cost-per-wear and sustainability analytics that reveal which clothes are actually worth their closet space, and **(3)** frictionless AI-assisted inventory intake so users don't abandon the app in the first week.

The strategic bet is that the wardrobe-app category is crowded on "log your clothes" but under-served on **"help me stop buying clothes I don't wear."** That angle has a real audience (sustainability \+ personal finance crossover) and is defensible beyond a pretty UI.

## **2\. Problem Statement**

* **Decision fatigue.** People spend measurable time deciding what to wear.  
* **Under-utilization.** Studies routinely cite that people wear \~20% of their wardrobe 80% of the time. The other 80% is dead capital.  
* **Weather mismatch.** Dressing wrong for conditions is uncomfortable and, in extremes, a health risk.  
* **Intake friction.** Every competitor app dies on the same rock: users won't manually log 60 items. Whatever we build *must* make intake nearly effortless or nothing else matters.  
* **No feedback loop on spending.** Users have no idea their $180 blazer has a $60 cost-per-wear while their $20 t-shirt is at $0.40. That's the insight that changes behavior — and nobody surfaces it cleanly.

## **3\. Revised Tech Stack (budget-first)**

| Layer | Choice | Why |
| ----- | ----- | ----- |
| **Frontend** | Flutter (Dart) | Single codebase, iOS \+ Android, free. Unchanged from original — this call is correct. |
| **Backend / DB** | **Supabase** (swap from Firebase) | Free tier: 500MB Postgres, 1GB storage, 5GB bandwidth, auth included. Real SQL helps recs. Firebase free tier will choke on image bandwidth. |
| **Image storage** | Supabase Storage \+ compression | Keeps the 1GB free tier usable for hundreds of users. |
| **Auth** | Supabase Auth | Email \+ Google OAuth, free. |
| **On-device ML** | Google ML Kit | Free, offline, private. Subject Segmentation gives free background removal. |
| **Weather** | Open-Meteo | Free, no key, granular. |

**Total recurring cost at MVP: $0.** Everything above has a free tier sufficient for a soft launch.

## **4\. Core Features — Revised**

### **A. Frictionless Intake (the make-or-break feature)**

* **Batch photo mode.** User dumps 10 items on a bed, shoots once, app segments each item and creates 10 draft entries. This alone beats every competitor's "tap \+ shoot \+ tag \+ save, 60 times" flow.  
* **On-device background removal** via ML Kit Subject Segmentation (free).  
* **Custom TFLite classifier** predicts category (shirt / pants / jacket / dress / shoes / accessory) and sub-type.  
* **Color extraction** auto-fills dominant palette.  
* **User just confirms.** Tap to accept or swipe to edit. Goal: under 10 seconds per item.

### **B. Context-Aware Recommendation Engine**

Inputs:

1. **Weather** — temperature, feels-like, precipitation, UV, wind (Open-Meteo).  
2. **Calendar** — optional device calendar read. "Gym at 6pm" → include athleticwear. "Dinner" → bias formal.  
3. **Wear history** — soft deprioritization (not hard exclusion) of recently worn items.  
4. **User preferences** — favorites, disliked combinations (learned from rejections).

Logic flow:

1. Filter by weather-compatible warmth band.  
2. Filter by occasion (from calendar or user tap).  
3. Score remaining items: `score = favorability − recency_penalty + cost_per_wear_bonus`. The cost-per-wear bonus gently nudges under-worn items into rotation — that's the sustainability hook working inside the core loop.  
4. Compose outfit respecting layer rules (base / mid / shell) and return top 3\.

### **C. Cost-Per-Wear & Wardrobe Analytics (the differentiator)**

* **Every item has a `purchase_price` field** (optional, user-entered at intake).  
* **Dashboard shows:** cost-per-wear per item, best-value items, worst-value items, "ghost" items unworn in 90+ days, total wardrobe value, wear distribution curve.  
* **Monthly insight notifications:** "You've spent $0.82 per wear on your denim jacket this month — your best value. Meanwhile these 8 items haven't been worn in 90 days."  
* **Resale prompt:** for ghost items, a one-tap "draft a listing" that pre-fills title, category, and photo — ready to paste into Vinted/Depop/Poshmark. No API integration needed at MVP; just the pre-filled clipboard copy is enough to be useful.

### **D. Wellness Layer**

* **UV alerts** → suggest hat, sunglasses, sunscreen reminder.  
* **Wind chill / cold snap** → prioritize windproof shells, warn about inadequate layering.  
* **Humidity** → bias breathable fabrics.  
* **Rain probability \> 40%** → waterproof outerwear \+ umbrella reminder.

### **E. Laundry State Machine**

Items cycle through: `Clean → Worn → Laundry → Clean`. Worn items auto-move to Laundry after N wears (user-configurable per item). Recommendation engine excludes non-clean items. This was in the original schema but not the feature list — it's actually important.

### **F. Packing List Generator (high-value, low-effort)**

User enters destination \+ dates → app pulls weather forecast for that location/period → generates a packing list from their wardrobe. This is the single most-requested feature in reviews of every competitor app. Cheap to build, very sticky.

## **5\. Revised Data Model**

```json
{
  "item_id": "uuid",
  "user_id": "uuid",
  "created_at": "2026-04-13T08:00:00Z",
  "image_url": "https://[supabase]/...",
  "ml_detected_category": "jacket",
  "primary_hex": "#2B4A6B",
  "category": "outerwear",
  "warmth_clo": 0.8,
  "purchase_price": 89.00,
  "usage": {
    "times_worn": 12,
    "state": "clean",
    "cost_per_wear": 7.42
  }
}
```

Key changes from the original: CLO values instead of a 1–5 scale, purchase price and cost-per-wear as first-class fields, occasions and fabrics as arrays, explicit state machine for laundry.

## **6\. Roadmap (lean, MVP-first)**

**Phase 1 — Skeleton (2 weeks).** Flutter project, navigation, auth via Supabase, empty grid views. Goal: you can sign up and see an empty closet.

**Phase 2 — Manual CRUD (2 weeks).** Add/edit/delete items with manual entry and a single photo. Supabase Storage wired up. Goal: the app is a working (boring) wardrobe tracker.

**Phase 3 — Intake automation (3 weeks).** Camera flow, ML Kit segmentation, custom TFLite classifier, color extraction, batch mode. Goal: intake time drops from \~60s/item to \~10s/item.

**Phase 4 — Weather \+ recommendations (2 weeks).** Open-Meteo integration, scoring function, outfit composition. Goal: "what should I wear today" returns a usable answer.

**Phase 5 — Analytics \+ sustainability layer (2 weeks).** Cost-per-wear dashboard, ghost-item detection, monthly insights, resale draft export. Goal: the differentiator is live.

**Phase 6 — Polish \+ wellness \+ packing list (2 weeks).** UV/cold alerts, packing list generator, onboarding refinement, empty states, error handling.

**Total: \~13 weeks to a launchable MVP, solo or small team.**

## **7\. Future Scope**

* **Generative visualization** (virtual try-on) — keep this as a *future* feature. Running GANs/diffusion is expensive and hard to do well. Not MVP.  
* **Retail partnerships / affiliate revenue** — "you're missing a navy blazer in your wardrobe, here are three in your size" → affiliate links. Real monetization path.  
* **Calendar deeper integration** — learn dress codes from recurring events.  
* **Social / outfit sharing** — only if retention data shows users want it.  
* **Apple Watch / Wear OS glance** — "today's outfit" on the wrist.

## **8\. Risks and Honest Caveats**

* **The custom TFLite classifier is the biggest technical risk.** Training on DeepFashion2 takes real work and accuracy may disappoint. Fallback: launch with ML Kit generic labels \+ user correction, train the custom model on real user data post-launch.  
* **Category is crowded.** Differentiation has to be *felt* in the first session, not buried three screens deep. The cost-per-wear angle has to show up fast.  
* **Retention is the historical killer for wardrobe apps.** Users log clothes for a week, then quit. Counter-moves: push notifications tied to weather ("cold front tomorrow, here's your outfit"), weekly insight digest, packing list as a re-engagement hook.  
* **Monetization is unproven.** Users historically resist paying for wardrobe apps. Likely path: free core \+ paid tier for unlimited items, advanced analytics, and calendar integration ($3–5/mo). Affiliate revenue as secondary.

## **9\. References**

* Flutter — flutter.dev  
* Supabase — supabase.com/docs  
* Google ML Kit — developers.google.com/ml-kit  
* Open-Meteo — open-meteo.com  
* DeepFashion2 dataset — github.com/switchablenorms/DeepFashion2

