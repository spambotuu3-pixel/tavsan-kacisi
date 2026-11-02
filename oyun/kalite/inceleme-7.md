# Kod incelemesi 7: Tavşan Kaçışı (oyun/)

**Doğruluk 8/10 · Temizlik 8/10 · Optimizasyon 9/10**

## Nasıl doğrulandı
- `godot --headless --path . -s test.gd` -> `ok`, çıkış 0.
- Pencereli film: `--write-movie ... --fixed-fps 30 --quit-after 120` (menü) ve `/tmp/claude-1000/inc7/probe.gd` ile oyun içi 420 kare (proje dışı; ayar yolu `user://inc7_ayar.cfg`, `ayar.cfg`/`test_ayar.cfg`'ye dokunulmadı). Kareler `/tmp/claude-1000/inc7/k00000119.png` ve `g00000285.png`.
- Son kapı logu (`kapi-20261102-161553.log`) 50/50 temiz, ortanca ~1,6 ms; log olarak aktarıyorum, yeniden üretmedim. Gamepad ve gerçek düşük FPS donanımı denetlenemedi.

## inceleme-6 bulguları
| Madde | Durum | Kanıt |
|---|---|---|
| T1 RAPOR G7 açık soru | Düzeltildi | `RAPOR-bolum1.md:85`, `DEGERLENDIRME.md:134`, `PLAN-grafik.md:106` |
| T2 GDD çiftlik/yazı tipi/kontrol | Düzeltildi | `GDD.md:72-73`, `:30-37` (kodla uyumlu: ui_up/ui_accept, menüde ↑↓, A/B) |
| T3 kare sayısı | Tutarlı | 690'da biter, 680 ölçülür: `RAPOR-bolum1.md:35`, `senaryo.gd:7`, log |
| T4/T7 `_ready` bölünmesi | Düzeltildi | `make_world()` `main.gd:333`, `make_hud()` `:351`; `_ready` kalan ~75 satır çoğu ortam kurulumu, kabul |
| D2 `f[0] in M.FARM` kırılganlığı | Düzeltildi | `FARM_SET` 4. alan ölçek (`modeller.gd:424-429`, `main.gd:338`) |
| D3 `cf.save` denetimi | Düzeltildi | `secim.gd:82-83` `push_warning` |
| T5 ayar 3 kez okunuyor | Bilerek bırakıldı, önemsiz | Üçü farklı anlarda (açılış seçimi, skor, kayıt); `config()` küçük dosyayı okur, ölçülebilir maliyet yok |
| T6 `TITLE_EDGE`=`HUD_TEXT` kopyası | Önemsiz | `secim.gd:12` / `main.gd:138`, tek renk iki ad; zevk meselesi |

## Doğruluk (8/10)
**D1. Bina-tepe gömülmesi GERÇEK ve görünüyor** (önceki "önemsiz olabilir" tahmini yanlış). `g00000285.png`: sol ve sağ evin alt kısmı tepe yüzeyine girip içbükey kesik görünüyor. Sayısal neden: bina x'i 11-15 (`main.gd:586`), yakın tepeler `HILL_A (-20,0,-10)` ve `(19,0,0)` `modeller.gd:164-165` x'te 10-30 aralığını kaplıyor; x=±11,5'te tepe yüksekliği ~1,6 m, ev duvarı 2,6 m. Bina tepeyle her geçişte yaklaşık 1,5-2 m gömülüyor (probe: x=-11,5 binası z göreli -18..+3 boyunca tepe içinde). Düzeltme: `main.gd:586` aralığını `randf_range(16.0, 20.0)` yap (`ağaç/çalı` bandı 5,5-9 ile hâlâ çakışmaz) ya da yakın tepelerin (`modeller.gd:164-165`) x merkezini 24+ yap. Sonra pencereli kareyle tekrar bak. Menü çiftliği (`FARM_SET`) temiz görünüyor (`k00000119.png`).
Başka işlev hatası bulmadım; mantık ve test tutarlı.

## Temizlik (8/10)
**T1. `DEGERLENDIRME.md` kodun ve diğer belgelerin gerisinde** (somut yanlış belge):
- `:16`, `:19` `main.gd:263-298`, `particles() :460`, `bulutlar :280`; `:17` `make_rabbit :399`; `:21` `run_dog :573`; `:22` D1 `:451` vb. satır numaraları bölünmeden sonra yanlış (ör. `make_rabbit` artık `main.gd:433`, MSAA `:286`, bulutlar `:339`, `burst` `:540`). Satır numarası yerine fonksiyon adı yaz.
- `:18` "GDD eski kaldı: menü, bölüm 1 ve puan formülü yok" artık yanlış (`GDD.md:22`, `:72-73`). `:21` "`RAPOR-bolum1.md` yok" yanlış (dosya var). `:22` "graphify güncellemesi yapılmadı / ikinci inceleme yok" eski (inceleme-1..7 ve kapı logu var). Üç satırı güncelle.
**T2.** `GDD.md:95` "Şu an: M1–M5 ve T1–T3" bitmiş işi hâlâ "şu an" gösteriyor (`DEGERLENDIRME.md:18` hepsi tamam diyor); "Şu an" yalnızca G6'yı ve ayar turunu içermeli.
**T3 (küçük).** `kapi.sh:3`/`:33` yalnız "690" diyor, ölçülen 680; "(ilk 10 kare atılır)" eklemek yeter. Boş `[unnamed project]` kullanıcı klasörü proje dışı, zararsız.
Kodun kendisi temiz: ölü kod, kopya blok, sızıntı bulmadım.

## Optimizasyon (9/10)
- Probe'da bina yaşam döngüsü sağlıklı: bina `z` göreli -80'den başlayıp geçince siliniyor (`CULL_BEHIND`), `items` büyümüyor. Mesh/malzeme önbellekli. Menü karesi CPU 0,43 ms, oyun içi 0,57 ms/kare (film modu CPU; GPU süresi film kodlamasıyla şişik, kıyaslanamaz).
- Bina başına `Tween` ve ayrı mesh, ölçülebilir sorun değil. Her karedeki `EVENTS.keys()`, `gap_fill.bg_color` önemsiz.

## Önemsiz mi? (karar)
- Ayar dosyası 3 okuma: önemsiz. `TITLE_EDGE` kopyası: önemsiz. Bina-tepe gömülmesi: önemsiz DEĞİL, küçük ama görünür kusur (yukarıda D1).

## Puanı 9'a çıkaracaklar
1. `main.gd:586` bina x aralığı 16-20 (ya da tepe kaydır) + yeni kareyle doğrula -> Doğruluk 9.
2. `DEGERLENDIRME.md:16-22` satır numaraları/eski iddialar, `GDD.md:95` yol haritası -> Temizlik 9.
