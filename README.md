<p align="center">
  <img src="assets/icon/wordmark.png" alt="Cashmori" width="520">
</p>

<p align="center">
  A personal, fully-offline expense &amp; net-worth tracker.<br>
  Built with Flutter + SQLite as a mini project — no accounts, no servers, no internet permission.
</p>

<p align="center">
  <img alt="platform" src="https://img.shields.io/badge/platform-Flutter-02569B?logo=flutter&logoColor=white">
  <img alt="database" src="https://img.shields.io/badge/database-SQLite-003B57?logo=sqlite&logoColor=white">
  <img alt="offline" src="https://img.shields.io/badge/offline-100%25-E0B84D">
  <img alt="license" src="https://img.shields.io/badge/license-MIT-1E2A38">
</p>

---

## Why Cashmori

Most expense trackers want an account, an internet connection, and a copy of your financial data on
someone else's server. Cashmori doesn't:

- Everything is stored **on-device**, in one SQLite file — zero servers, zero sign-ups, zero analytics.
- **Backup is a file you own.** One tap zips the database; you decide where it goes (Drive, phone
  storage, email to yourself). Restore reads that same file back — no cloud account involved.
- Covers the everyday financial picture in one app: daily spending, money lent/borrowed, a simple
  share portfolio, and other assets (gold, property, vehicles).

## Screenshots

These are the original design mockups (the app is built to match them closely — swap in real device
screenshots once you've run it):

| Home hub | My Saving | Add entry |
|---|---|---|
| ![Home hub](screenshots/home_hub.jpg) | ![My Saving](screenshots/my_saving.jpg) | ![Add entry](screenshots/add_entry.jpg) |

## Features

- **My Saving** — total saving at a glance, a 12-month Saving / Income / Expense trend chart, and a
  month-grouped transaction list.
- **Add / edit entry** — Expense/Income toggle, category → sub-category dependent dropdowns, amount,
  date, description. One bottom sheet handles both add and edit.
- **Borrow & Outstanding** — track money lent or borrowed per person, due dates, and a running net
  balance. Mark records settled without deleting them.
- **My Shares** — a manual portfolio: quantity, buy price, current price, invested vs. current value,
  and gain/loss %.
- **My Assets** — property, gold, vehicles, and other assets with a running total.
- **Settings → Backup & Restore** — export the live database as a `.zip` via the native share sheet;
  restore by picking a previously exported `.zip`.

## Tech stack

| Layer | Choice |
|---|---|
| UI | Flutter |
| Local database | `sqflite` (SQLite) |
| Chart | `fl_chart` |
| Backup / restore | `archive` (zip/unzip) + `file_picker` + `share_plus` |
| Formatting | `intl` |

## Getting started

```bash
git clone <this-repo-url>
cd money_tracker
flutter pub get
flutter run
```

No API keys, no `.env` file, no backend to stand up — it runs the moment `flutter pub get` finishes.

### App icon

The launcher icon (`assets/icon/app_icon.png` + `app_icon_foreground.png`) is wired up via
`flutter_launcher_icons`. Generate every platform size with:

```bash
dart run flutter_launcher_icons
```

## Project structure

```
lib/
  main.dart                     # app entry point
  theme/app_theme.dart          # colors, card style, button style
  models/                       # Transaction, Borrow, Share, Asset
  db/database_helper.dart       # single SQLite database, CRUD + chart queries
  services/backup_service.dart  # zip export / import of the raw .db file
  screens/                      # one file per page
  widgets/                      # reusable pieces (hub card, transaction tile, chart)
```

## Database

Four independent SQLite tables — one per section, no foreign keys between them:

```
transactions        borrow_records       shares               assets
─────────────       ─────────────        ──────               ──────
id            PK     id            PK    id            PK     id            PK
type                 type                company_name         name
amount               person_name         quantity             asset_type
date                 amount              buy_price            value
category             date                current_price        purchase_date
sub_category         due_date            purchase_date        notes
description          status              notes
                      notes
```

Independent tables keep restore simple: there's no relational integrity to reconcile, just a file swap.

## Backup & restore

**Export:** Settings → *Backup Now* closes the live DB connection, zips `money_tracker.db` into
`money_tracker_backup.zip`, and opens the OS share sheet — save it to Drive, local storage, email,
wherever.

**Restore:** Settings → *Restore from file* opens the file picker, extracts `money_tracker.db` from the
selected `.zip`, and overwrites the live database (after a confirmation dialog, since it's destructive).

Zipping the raw `.db` file (instead of exporting JSON) means one file *is* every table, byte-for-byte —
restore is "replace file, reopen," not "re-parse and re-insert thousands of rows."

## Known limitations

- Share prices are entered manually — no live market data fetch (keeps the app fully offline).
- Backup/restore goes through the OS share sheet / file picker rather than a fixed folder, since modern
  Android's scoped storage restricts direct file-system access.
- No PIN / biometric app lock yet.
- Single currency — no multi-currency conversion.

## Roadmap

- [ ] PIN / biometric app lock (`local_auth`)
- [ ] CSV export alongside the zip backup
- [ ] Budget limits per category with progress bars
- [ ] Scheduled local reminders to back up weekly
- [ ] Optional multi-currency support

## Regenerating screenshots

```bash
flutter pub get
flutter run
# capture screenshots on the emulator/device and drop them into /screenshots,
# replacing the mockup images referenced above
```

## License

MIT — do whatever you like with it. If this helped with your own mini project, a star is appreciated
but never required.
