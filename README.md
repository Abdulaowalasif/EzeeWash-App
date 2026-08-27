# EzzeWash 🧺

A full-stack laundry service platform built with Flutter and Supabase — consisting of a **Customer App** and a **Rider App**.

---

## Apps

| App          | Package    | Description |
|--------------|------------|---|
| **EzzeWash** | `ezzewash` | Customer-facing: browse services, book orders, pay, track delivery |

---

## Tech Stack

- **Frontend** — Flutter (Dart), BLoC state management, GoRouter navigation
- **Backend** — Supabase (PostgreSQL + Auth + Realtime + Storage + Edge Functions)
- **Payments** — Stripe via Supabase Edge Function (zero-decimal BDT, Stripe-first flow)
- **Architecture** — Clean Architecture (Data / Domain / Presentation layers)
- **Font** — Alexandria + Pacifico (Google Fonts)
- **Primary colour** — `#1D4BC7`

---

## Customer App

### Features

- **Auth** — Email/password sign-up and login
- **Home** — Service grid with images, recent orders, quick actions
- **Services** — Browse and filter by category, search, book directly
- **Book Service** — 5-step wizard: Service → Store → Schedule → Address → Payment
- **Payment** — Cash on Delivery or Stripe card (payment is collected before the order is placed in DB — no unpaid orders)
- **Orders** — Active / history tabs, cancel active orders, service images on cards
- **Track Order** — Live map placeholder, full order timeline, progress bar
- **Notifications** — Realtime push alerts
- **Profile** — Edit info, address, theme, sign out

### Screen Map

```
Login / Register
└── Main (bottom nav)
    ├── Home
    ├── Services
    ├── Orders
    │   └── Track Order
    ├── Notifications
    └── Profile
        ├── Address
        ├── Help & Support
        ├── Terms & Policy
        └── Chat Bot

Book Service (5 steps)  →  Booking Confirmed
```

### Architecture

```
lib/
├── core/
│   ├── constants/      app_color.dart, app_constants.dart
│   ├── di/             injection_container.dart
│   ├── errors/         failures.dart, exceptions.dart
│   ├── theme/          app_theme.dart
│   └── utils/          responsive.dart, usecase.dart
├── features/
│   ├── auth/
│   ├── home/
│   ├── services/
│   ├── orders/
│   ├── notifications/
│   ├── profile/
│   └── stores/
└── routes/
    ├── app_router.dart
    └── routes_name.dart
```

---

## Rider App

### Features

- **Auth** — Email/password login (riders are created by admin in Supabase Auth)
- **Dashboard** — Online/offline toggle, available order cards with Accept button, live stats
- **My Orders** — Active assigned orders with status progress bars
- **Order Detail** — Full order info, one-tap status advancement, live GPS broadcast to customer's track screen
- **Profile** — Vehicle type/plate, rating, trip count, edit sheet, sign out

### Order Status Workflow

```
confirmed → picked_up → in_process → ready → out_for_delivery → delivered
```

Each tap on "Mark [next step]" calls `rider_update_order_status()` in Supabase. GPS is upserted to `rider_locations` every 20 metres via Geolocator stream.

---

## Supabase Setup

### 1. Run SQL Migrations (in order)

Run each file in **Supabase → SQL Editor**:

```
1. customer_schema.sql    core tables: orders, services, stores, profiles
2. add_image_columns.sql  image_url on services, logo_url on stores
3. payment_schema.sql     payment_status, payment_method on orders
4. rider_schema.sql       riders table, rider_locations, rider_id on orders
```

### 2. Deploy Edge Functions

```bash
supabase functions deploy create-payment-intent
supabase functions deploy stripe-webhook
```

Set Stripe secrets:

```bash
supabase secrets set STRIPE_SECRET_KEY=sk_live_...
supabase secrets set STRIPE_WEBHOOK_SECRET=whsec_...
```

### 3. Storage Buckets

Create these public buckets in **Supabase → Storage**:

| Bucket | Purpose |
|---|---|
| `service-images` | `services.image_url` |
| `store-images` | `stores.logo_url` |
| `avatars` | Rider profile avatars |

Upload images and link them to rows:

```sql
UPDATE services
SET image_url = 'https://<ref>.supabase.co/storage/v1/object/public/service-images/wash-fold.jpg'
WHERE title = 'Wash & Fold';

UPDATE stores
SET logo_url = 'https://<ref>.supabase.co/storage/v1/object/public/store-images/downtown.jpg'
WHERE name = 'Downtown Store';
```

If `image_url` / `logo_url` is NULL the app falls back to the icon automatically.

### 4. Add Keys to the Apps

**Customer App** — `lib/core/constants/app_constants.dart`:
```dart
static const supabaseUrl     = 'YOUR_SUPABASE_URL';
static const supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

**Customer App** — `lib/main.dart`:
```dart
Stripe.publishableKey = 'pk_live_...';
```

**Rider App** — `lib/core/constants/app_constants.dart`:
```dart
static const supabaseUrl     = 'YOUR_SUPABASE_URL';
static const supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

---

## Getting Started

### Customer App
```bash
cd EzeeWash-App
flutter pub get
flutter run
```

### Rider App
```bash
cd ezeewash_rider
flutter pub get
flutter run
```

### Android Release Build
```bash
flutter build apk --release
```

**Required Android config:**

`android/app/proguard-rules.pro`:
```
-dontwarn com.stripe.android.pushProvisioning.**
-dontwarn com.reactnativestripesdk.pushprovisioning.**
```

`android/app/build.gradle.kts` release block (Kotlin DSL):
```kotlin
release {
    isMinifyEnabled = true
    isShrinkResources = true
    proguardFiles(
        getDefaultProguardFile("proguard-android-optimize.txt"),
        "proguard-rules.pro"
    )
}
```

`android/app/src/main/kotlin/.../MainActivity.kt` must extend `FlutterFragmentActivity` (required by flutter_stripe):
```kotlin
class MainActivity : FlutterFragmentActivity()
```

---

## Key Dependencies

| Package | Purpose |
|---|---|
| `flutter_bloc` | BLoC state management |
| `go_router` | Declarative navigation |
| `supabase_flutter` | Auth, database, realtime, storage |
| `flutter_stripe` | Stripe card payments |
| `cached_network_image` | Cached image loading |
| `google_fonts` | Alexandria + Pacifico |
| `iconsax` | Icon library |
| `get_it` | Dependency injection |
| `dartz` | Either type for error handling |
| `geolocator` | Rider GPS tracking |
| `image_picker` | Avatar photo upload |

---

## Database Schema

```
profiles          id, full_name, phone, avatar_url
services          title, price, category, image_url, is_active
stores            name, address, lat, lng, logo_url, is_active
orders            user_id, service_id, store_id, status, progress,
                  payment_method, payment_status, rider_id
order_timelines   order_id, title, description, is_done, step_order
notifications     user_id, title, body, is_read
riders            id, full_name, phone, vehicle_type, vehicle_plate,
                  is_online, rating, total_trips
rider_locations   rider_id, order_id, latitude, longitude
```

### Order Status Flow

```
pending → confirmed → picked_up → in_process → ready → out_for_delivery → delivered
                                                                         ↘ cancelled
```

---

## Adding Riders

Riders cannot self-register. Add them via **Supabase → Auth → Users → Invite user**. A `riders` profile row is created automatically on first login via the `handle_new_rider()` database trigger.

---

## Colour Palette

| Token | Hex | Usage |
|---|---|---|
| Primary | `#1D4BC7` | Brand, buttons, gradients |
| Secondary | `#2F2E98` | Gradient end |
| Success | `#10B981` | Online, delivered, confirmed |
| Warning | `#F59E0B` | In-progress statuses |
| Error | `#EF4444` | Cancelled, errors |
| Info | `#3B82F6` | Confirmed status badge |

---

*Built with Flutter & Supabase*