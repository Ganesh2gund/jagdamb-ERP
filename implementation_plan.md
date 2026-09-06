# Hotel ERP Flutter App — Implementation Plan

## Overview

A premium, mobile-only Hotel ERP Management App built with Flutter + Dart + Material 3. Single Admin role. Mock data with clean repository/service architecture ready for Fastify backend integration.

---

## Architecture

```
lib/
├── core/
│   ├── theme/           # AppTheme, colors, typography
│   ├── constants/       # app constants, routes
│   └── utils/           # helpers, formatters
├── models/              # data models (Room, Booking, Guest, etc.)
├── services/
│   ├── auth_service.dart
│   └── api_service.dart  (stub for future Fastify)
├── repositories/        # abstract + mock implementations
│   ├── room_repository.dart
│   ├── booking_repository.dart
│   ├── guest_repository.dart
│   ├── payment_repository.dart
│   ├── restaurant_repository.dart
│   ├── housekeeping_repository.dart
│   ├── inventory_repository.dart
│   ├── expense_repository.dart
│   ├── staff_repository.dart
│   ├── maintenance_repository.dart
│   └── notification_repository.dart
├── widgets/             # shared reusable widgets
└── features/
    ├── splash/
    ├── auth/
    ├── dashboard/
    ├── rooms/
    ├── bookings/
    ├── guests/
    ├── restaurant/
    ├── housekeeping/
    ├── inventory/
    ├── expenses/
    ├── payments/
    ├── staff/
    ├── maintenance/
    ├── reports/
    ├── notifications/
    └── settings/
```

## Build Order

1. Flutter project setup + pubspec.yaml
2. Theme / design system (colors, typography, component styles)
3. Models (all data models)
4. Mock repositories (realistic data)
5. Auth service + Splash + Login
6. Main navigation (BottomNavBar + More screen)
7. Dashboard (stats, revenue, activity, alerts, quick actions)
8. Rooms (list, filter, detail, status change)
9. Bookings (list, new booking form, check-in/check-out flow)
10. Guests (list, detail)
11. Billing (invoice-style)
12. Payments (pending, paid, partial)
13. Restaurant/POS
14. Housekeeping
15. Inventory
16. Expenses
17. Staff
18. Maintenance
19. Reports (with mock charts)
20. Notifications
21. Settings / Profile

## Tech Decisions

- **Navigation**: `go_router` for declarative routing
- **State**: `provider` (simple, ready for service injection)
- **Charts**: `fl_chart` for reports
- **Icons**: Material Icons + `lucide_icons` or similar
- **Fixed credentials**: `tejas@gmail.com` / `tejas4010`
- **Theme**: Material 3, neutral palette with indigo/slate primary brand color

## Color System

- Primary: `#4F46E5` (indigo-600 — professional, premium)
- Background: `#F8F9FA` (light)
- Surface: `#FFFFFF`
- Error: `#EF4444`
- Success: `#10B981`
- Warning: `#F59E0B`

## Open Questions

None — spec is comprehensive. Proceeding with full implementation.
