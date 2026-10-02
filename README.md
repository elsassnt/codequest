# CodeQuest: Python Adventure (Flutter)

## Cara menjalankan
```bash
flutter create --platforms=android codequest
# salin isi zip ini (lib/, assets/, test/, pubspec.yaml) ke folder codequest, timpa file yang ada
cd codequest
flutter pub get
flutter test      # cek engine & skor
flutter run
```

## Struktur
- `lib/engine/` pseudo-interpreter Python + aturan skor
- `lib/services/` SQLite (data misi) + SharedPreferences (progres) + Provider
- `lib/screens/` splash, onboarding, home (peta misi), misi, hasil
- `lib/widgets/` keyboard coding, editor ber-syntax-highlight, maskot
