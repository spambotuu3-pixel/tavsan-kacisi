# Tavşan Kaçışı

Yabani bir tavşan havuçları çalıp kaçıyor; çiftçi Halil onu kovalıyor ve eline geçeni fırlatıyor. 3 şeritli, 3B bir kaçış oyunu (Godot 4.7, GDScript).

**Tarayıcıda oyna:** https://spambotuu3-pixel.github.io/tavsan-kacisi/

## Kontroller
- Bilgisayar: ← → şerit değiştir, ↑ / Space zıpla, ↓ havuçla atıl (3 havuç), Enter başlat / tekrar, Esc menü
- Telefon: ekranın solu = sola, ortası = zıpla, sağı = sağa; bitişte dokun = tekrar

## Geliştirme
- Çalıştır: `godot --path oyun`
- Test: `godot --headless --path oyun -s test.gd`
- Web sürümü: `godot --headless --path oyun --export-release Web ../docs/index.html` (Godot 4.7 web şablonu gerekir)
- `docs/` klasörü GitHub Pages ile sunulan web sürümüdür.

Yazı tipi: Baloo 2 (SIL Open Font License, `oyun/yazi/OFL.txt`).
