# preinspection_agent_app

Flutter port of the **Pre-Inspection Agent** portal from the web app
(`car-damage-insurance-web-app/src/pages/flows/preinspection/PreinspectionAgent`).

Every screen and every route of that portal is reproduced 1:1 — same layout,
same copy, same field order, same navigation. Route paths are kept identical to
the web URLs so the two apps stay easy to compare.

## Run

```bash
flutter pub get
flutter run          # device / emulator (camera + location need a real device)
flutter test         # 24 tests: routes, login/session, signature pad, doc-upload status, validators
flutter analyze
```

## Routes

`lib/core/routing/app_routes.dart` holds the path constants;
`lib/core/routing/app_router.dart` wires them to pages via `go_router`.
Initial location is `/preinspection-agent/login`.

| Path | Page |
| --- | --- |
| `/preinspection-agent/login` | `login/login_page.dart` |
| `/preinspection-agent/dashboard` | `dashboard/dashboard_page.dart` |
| `/preinspection-agent/claim-start` | `claim_start/claim_start_page.dart` |
| `/preinspection-agent/owner-vehicle-details` | `owner_vehicle_details/owner_vehicle_details_page.dart` |
| `/preinspection-agent/document-upload` | `document_upload/document_upload_page.dart` |
| `/preinspection-agent/inspection-details` | `inspection_details/inspection_details_page.dart` |
| `/preinspection-agent/photo-capture-selection` | `photo_capture_selection/photo_capture_selection_page.dart` |
| `/preinspection-agent/camera-capture/:angle` | `camera_capture/camera_capture_page.dart` |
| `/preinspection-agent/walk-around-video` | `walk_around_video/walk_around_video_page.dart` |
| `/preinspection-agent/add-damage-photos` | `add_damage_photos/add_damage_photos_page.dart` |
| `/preinspection-agent/add-others-photos` | `add_others_photos/add_others_photos_page.dart` |
| `/preinspection-agent/damage-review` | `damage_review/damage_review_page.dart` |
| `/preinspection-agent/submitted` | `submitted/submitted_page.dart` |
| `/preinspection-agent/reinspection-photos` | `reinspection_photos/reinspection_photos_page.dart` |
| `/preinspection-agent/repair-submission` | `repair_submission/repair_submission_page.dart` |
| `/preinspection-agent/vehicle-information` | `vehicle_information/vehicle_information_page.dart` |
| `/preinspection-agent/customer-declaration` | `customer_declaration/customer_declaration_page.dart` |
| `/preinspection-agent/inspector-declaration` | `inspector_declaration/inspector_declaration_page.dart` |

Page paths above are relative to
`lib/features/preinspection_agent/presentation/`.

### Flow order

```
login → dashboard → claim-start → owner-vehicle-details → document-upload
      → inspection-details → photo-capture-selection
                               ├─ camera-capture/:angle   (per capture point)
                               └─ walk-around-video
      → add-others-photos → damage-review → submitted
                                              └─ reinspection-photos → repair-submission
vehicle-information → customer-declaration / inspector-declaration → dashboard
```

`camera-capture/:angle` is pushed from photo-capture-selection,
add-damage-photos and add-others-photos, and pops back to whichever screen
pushed it (see `core/routing/app_back.dart`).

## Folder structure

```
lib/
├── main.dart                  # entry point, wraps the app in a ProviderScope
├── app.dart                   # MaterialApp.router + theme
├── core/                      # everything shared across screens
│   ├── config/                # insurer branding switch
│   ├── routing/               # app_routes.dart (paths), app_router.dart, app_back.dart
│   ├── services/              # camera, location, media storage
│   ├── theme/                 # app_colors.dart, app_text_styles.dart
│   ├── utils/                 # validators, orientation helpers
│   └── widgets/               # AppHeader, PageTitleBar, BottomButton, modals, signature pad…
└── features/
    └── preinspection_agent/
        ├── data/              # demo claims, vehicle capture-point assets
        ├── domain/            # models (Claim, OwnerVehicleDetails, CapturedPhoto), enums
        ├── presentation/      # one folder per screen (see route table above)
        └── state/             # Riverpod flow state + notifier (persisted via SharedPreferences)
```

Adding a screen: create `presentation/<screen>/<screen>_page.dart`, add its
path to `AppRoutes`, and register it in `createAppRouter()`.

## Preinspection-specific differences from the claim flow

- **Claim Start** — "Thank you for using risk inspection services"; checklist is
  previous policy copy, PUC, registration certificate, KYC.
- **Owner & Vehicle Details** — extra *Survey type* radio (pre inspection /
  Valuation), *Owner Serial Number* dropdown and *Present Market Value / IDV*
  field; the action button reads **Next**.
- **Document Upload** — previous policy copy + PUC replace claim form, driving
  licence and repair estimate; all six documents are mandatory.
- **Dashboard** — counters read Total Preinspection / Completed / Pending, and
  list cards label the claim number as **PI Ref. Number** and the insured as
  **Owner Name**.
- **Inspection Details** — the claim number row is **PI Ref. Number**.
- **Photo Capture Selection** — both workflow options continue to *Add Others
  Photos*.
- **Vehicle Information** — submitting returns to the dashboard.

## Deliberate deviations from the web app

These are places the Flutter app improves on the reference rather than
copying it:

- **Document upload** — the badge reads Submitted/Pending from the real
  capture state instead of the static `required` flag, so a document only
  shows Submitted once its images are saved.
- **Photo Capture Selection** — restyled as a photo-guide board: eight
  numbered markers spaced evenly around an ellipse (captions sit under each
  marker so they cannot overlap), wired to a large vehicle image by leader
  lines, with odometer / chassis number / walk-around video as cards in a
  strip along the bottom. Each of those cards pairs the guide shot with the
  agent's own capture. Every vehicle type gets a chassis-number card — the
  two-wheeler folder ships no plate artwork, so it borrows the car's.
- **Add Others Photos** — the sample shot for each slot is small and shown at
  full opacity, with the agent's own photo for that slot beside it; it used to
  be a card-width image faded to 40%, which read as a broken photo.
- **Camera capture** — the whole-car silhouette overlay (and the landscape
  lock) applies only to the eight 360-degree angles. Close-ups — dashboard,
  open hood, tyre numbers, under body, selfie — get a plain portrait
  viewfinder.
- **Signatures** — the pad claims the pointer outright, so a stroke is never
  swallowed by the surrounding scroll view, and Clear/Undo actually wipe the
  ink (see `test/core/signature_pad_test.dart`). The declaration screens are
  pushed and popped, so returning lands on the same scroll position.
- **Branding** — `InsurerBranding.current` is `none`, so the header carries
  the IBima Assist logo alone; point it at a named `InsurerBranding` to bring
  partner branding back.
- **Login & session** — the web app's two tabs pick a portal (Claim /
  Pre-Inspection); this app *is* the preinspection portal, so its tabs pick
  who is signing in — **Agent** or **Surveyor**. The chosen role and the id
  typed on the form are held in `state/session_provider.dart`, and the
  dashboard greets that id and shows its role instead of a hardcoded
  workshop name.
