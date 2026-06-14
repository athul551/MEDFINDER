- [x] Identify the exact failure mode (compile error, runtime crash, or logic bug) based on analyzer output.
- [x] Locate related code paths for login/auth and customer screens.
- [ ] Fix remaining compile errors:
  - [ ] lib/screens/customer/medicine_search_screen.dart:337:11 missing identifier (likely due to previous broken button widget).
  - [ ] lib/widgets/stock_card.dart constant expression issue (shade900 in const).
- [ ] Run `flutter analyze` again to confirm the project builds cleanly.
- [ ] Run a debug build/run (e.g., `flutter run -d <device>`).

