# Kod incelemesi 6: Tavşan Kaçışı (oyun/)

**Doğruluk 9/10 · Temizlik 8/10 · Optimizasyon 9/10**

İncelenen: `main.gd` (858 satır), `secim.gd` (172), `modeller.gd` (432), `test.gd`, `project.godot`, `yazi/`, `kalite/kapi.sh`, `kalite/senaryo.gd`, `GDD.md`, `RAPOR-bolum1.md`. Yeni konular: çiftlik binaları ve yazı tipi.

## Nasıl doğrulandı

- `godot --headless --path . -s test.gd` -> `ok` (çıkış 0).
- Yoklama betiği `/tmp/claude-1000/inc6/yoklama.gd` (proje dışı): gerçek `main.gd` sahnesi, `--fixed-fps 60`, `gap` her kare 10'a sabitlenip 2400 kare (464 m) koşuldu; kendi ayar yolu (`user://inc6_ayar.cfg`), `ayar.cfg` ve `test_ayar.cfg`'ye dokunulmadı.
  - `items` 30-42 arasında, düğüm 485-613, yetim düğüm hep 0. Binalar `kind="deco"` ile `items`'a giriyor ve `passed` (15 m geride) ile `queue_free` ediliyor (`main.gd:766-780`). Büyüme yok; 400 m sonrası artış köpek/kaz bölgesi süsleri (`~613 -> 572`'ye geri iniyor).
  - `Baloo2.ttf` ş ğ ı İ Ç Ö Ü ile ◀ ▶ ↑ ↓ glifleri için `has_char` hepsi `true`. Yedek yazı tipi gerekmiyor.
- Pencereli çiftlik görüntüsünü, hız/kare süresini ve gamepad'i bu turda ben ölçmedim. Kapı logu (`kapi-20261102-161021.log`, 16:10-16:12, kod 16:10:04'te son değişmiş, yani yeni kodla): 50/50 temiz, ortanca 1,57-1,66 ms, %99 en çok 2,06 ms, en kötü 3,56 ms. Bunu log olarak aktarıyorum, yeniden üretmedim.

## inceleme-5 maddelerinin durumu (kodda doğrulandı)

| Madde | Durum | Kanıt |
|---|---|---|
| D1 gamepad A/B eylem eşlemesine bağlı | **Düzeltildi** | `secim.gd:136-137` `JOY_BUTTON_A`; `main.gd:469-470` A/B doğrudan |
| D2 isimde denetim/yön karakteri | **Düzeltildi** | `secim.gd:17-29` `is_control`; `test.gd:30` `"a\tb\r‮ç"` -> `abç` |
| D3 `vy` yerde birikiyor | **Düzeltildi** | `main.gd:697-698` |
| D4 zıplama yüksekliği FPS'e hafif bağlı | Değişmedi, önemsiz | `main.gd:695-696` |
| D5 `cf.save` sonucu denetlenmiyor | Değişmedi | `secim.gd:76` |
| GDD skor/kontrol/yol haritası | **Kısmen**: skor ve kontrol tablosu düzelmiş (`GDD.md:22`, `:30-37`); bkz. T2 | |
| Kare sayısı yorumları | **Kısmen**: `kapi.sh:3`/`senaryo.gd:7` "690"; ölçülen sayım 680; bkz. T3 | |
| T5 ayar 3 kez okunuyor | Değişmedi | `main.gd:314`, `secim.gd:76-77`, `load_scores` |
| T6 `TITLE_EDGE` = `HUD_TEXT` | Değişmedi | `secim.gd:12`, `main.gd:138` |
| T7 `_ready` uzun | Değişmedi, **büyüdü** (~140 satır, `main.gd:260-400`) | |

## Doğruluk (9/10)

Çiftlik mantığı doğru çalışıyor: bina dönüşü hesabı (`main.gd:578`, `-90*fs`) kapıyı (+z) yola çeviriyor (sağ taraf için -x, sol için +x); tarafı `fs` ve x'i `11-15` ile ağaç/çalı bandının (`5.5-9`) dışında; `h` yok, `kind="deco"` olduğu için çarpışma sayılmıyor (`main.gd:767`, `kind != "deco"` koşulu). Yazı tipi: tema yerine `project.godot [gui] theme/custom_font` kullanılmış; menü teması (`ui_theme`) yalnızca boyut/renk koyduğu için font miras kalıyor, çakışma yok. Lisans dosyası (`yazi/OFL.txt`) yanında.

10 vermemem:

**D1. Çiftlik binaları tepelere ve komşu binalara girebilir** (`main.gd:575-579`, `modeller.gd:160-163`) — görsel, **doğrulamadım**
- `scenery` tavşanla kayar; tepeler sahnede göreli duruyor: `HILL_B` merkez (23, z-40) yarıçap x~11, `HILL_A` (-26, z-50) yarıçap x~13. Bina x'i 11-15 olduğundan o z aralığında bina tepenin kenarına gömülür (hesapla: x=13'te tepe ~1,4 m yüksek). Ayrıca satır aralığı 9-15 m, z kayması ±3, ahır genişliği 5,4 m: aynı yanda iki bina üst üste binebilir (hesapla satır başına <%1).
- Öneri (ihtiyaç olursa): bina x'ini 16-20'ye al ya da sıra yoğunluğunu kıs; önce pencereli ekran görüntüsüyle bak.

**D2. `f[0] in M.FARM` dizi eşitliğine dayanıyor** (`main.gd:303`) — işlevsel doğru, kırılgan
- `HOUSE`/`BARN`/`SILO` dizileri değer olarak karşılaştırılıyor. İki bina aynı içerikle tanımlanırsa yanlış ölçeklenir. Daha sağlam: `FARM_SET` kayıtlarına ölçek alanı koymak ya da `FARM_SET` bina girdilerini `M.FARM_SCALE` ile ayrı listede tutmak.

**D3. `cf.save` sonucu yine denetlenmiyor** (`secim.gd:76`) — düşük etki; `push_warning` yeter.

## Temizlik (8/10)

Kod temiz: yeni sabitler adlı (`FARM_CHANCE`, `FARM_SCALE`), ölü kod yok, bina verisi `modeller.gd`'de, mantık `main.gd`'de. 8'e düşüren **belgeler hâlâ kodun gerisinde** ve `_ready` uzaması.

Düzeltilmesi gerekenler (önem sırasıyla):

1. **T1. `RAPOR-bolum1.md:85` eski açık soru.** "Yazı tipi (G7) indirilsin mi?" artık yapılmış (Baloo 2, OFL). Maddeyi kapalı yaz ve yazı tipinin adını/lisansını belirt. `GDD.md:93` "Şu an: G1-G7" doğru ama `DEGERLENDIRME.md:19, :134` ve `PLAN-grafik.md:106` hâlâ "kullanıcı kararını bekliyor" diyor.
2. **T2. `GDD.md` çiftlik ve yazı tipinden hiç bahsetmiyor.** `GDD.md:68` "Dünya" satırına çiftlik binalarını (ev/ahır/silo, yol kenarında sırada %30 olasılık, menü arkasında sabit çiftlik) ve "Arayüz" satırına Baloo 2'yi ekle. `GDD.md:95` "Ardından: açılış sahnesi" artık yapılmış; listeden çıkar. `GDD.md:30-37` kontrol tablosunda hâlâ menüde ↑↓ renk, Space ve açılışı herhangi tuşla atlama yok; zıplama "↑ veya Enter" yazıyor, `RAPOR-bolum1.md:28` "↑ ya da Space" diyor. Kod: `ui_up` + `ui_accept` (Enter, KP Enter, Space). İkisini de aynı yaz.
3. **T3. Kare sayısı hâlâ tutarsız.** `kapi.sh:3` ve `:33` "690 karelik", `senaryo.gd:7` `END_FRAME := 690`, `RAPOR-bolum1.md:35` ve kapı logu "680 kare" (ölçülen). Rapor ve loga "690. karede biter, 680 kare ölçülür" yaz ya da `kapi.sh` yorumunu 680'e çek.
4. **T4. `_ready` uzun** (`main.gd:260-400`, ~140 satır, FARM_SET döngüsü eklendi). `make_hud(layer)` (`:327-384`) ve `make_world()` (`:261-313`) çıkarılırsa kısalır.
5. **T5. Ayar dosyası açılışta 3 kez okunuyor** (`main.gd:314`, `secim.gd:76`, `load_scores`): `config()` bir kez okuyup geçirmek yeter. `TITLE_EDGE` = `HUD_TEXT` (`secim.gd:12`, `main.gd:138`) tek sabite indirilebilir.
6. `.godot/` ve `[unnamed project]` kullanıcı klasörü: yalnız `~/.local/share/godot/app_userdata/` altında bırakılmış eski bir klasör; projeyle ilgisi yok, zararsız.

## Optimizasyon (9/10)

- Nesne sayısı kontrollü: yoklamada 2400 karede `items` 30-42, düğüm 485-613, yetim 0; çiftlik binaları `CULL_BEHIND` ile siliniyor, sızıntı yok. Bir bina 2-7 `MeshInstance3D` (HOUSE 7, BARN 6, SILO 2); mesh ve malzemeler önbellekli (`shape_mesh`, `soft_mat`), yani bina başına yeni kaynak yok.
- Sabit çiftlik (`FARM_SET`, 11 bina + 6 süs, ~80 mesh) `scenery` altında; kamera çerçevesi dışında kalanlar GPU'da atılır. Kapı logundaki ortanca 1,6 ms ile uyumlu.
- 9 yerine 10 vermemem: her bina için ayrı `Tween` ve ayrı `MeshInstance3D` (`:603-606`); birleştirme (MultiMesh/tek mesh) olası ama ölçülebilir kazanç beklemiyorum. Pencereli çerçeve süresini ben bu turda yeniden ölçmedim, kapı loguna dayanıyorum.
- Küçük, önemsiz: `gap_fill.bg_color` her kare (`main.gd:830`); `EVENTS.keys()`/`INTRO_CUES.keys()` her kare yeni dizi (`:664`, `:728`); `burst()` yeni `GPUParticles3D` (`:531`).

## Denetlenemeyenler

- Gerçek gamepad, gerçek 30-40 FPS donanım.
- Çiftlik binalarının tepe/komşu bina kesişmesi (görsel olarak bakmadım).
- Pencere boyutu değişince HUD yerleşimi; menü yazı boyutu Baloo 2 ile taşma yapıyor mu (ekran görüntüsüne bakmadım).
