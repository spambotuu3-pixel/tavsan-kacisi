# Kod incelemesi 5: Tavşan Kaçışı (oyun/)

**Doğruluk 9/10 · Temizlik 8/10 · Optimizasyon 9/10**

İncelenen: `main.gd` (845 satır), `secim.gd` (163), `modeller.gd`, `test.gd`, `toon.gdshader`, `kalite/senaryo.gd`, `kalite/kapi.sh`; ayrıca `RAPOR-bolum1.md`, `PLAN-bolum1.md`, `GDD.md`. Kodu yazan oturumlara güvenilmedi; önceki inceleme maddeleri kodda ve ölçümle yeniden doğrulandı.

## Nasıl doğrulandı

- `godot --headless --path . -s test.gd` -> `ok`.
- Kendi yoklama betiklerim yalnızca scratchpad'de (`/tmp/claude-1000/.../scratchpad/`). Kendi ayrı ayar dosyalarımı kullandım ve sildim; `ayar.cfg`, `test_ayar.cfg` ve başkasına ait `inceleme5_ayar.cfg` dosyalarına dokunmadım.
- **Atış isabeti (inceleme-4 D1):** sabit FPS ile, tavşan şeritte kıpırdamadan koşarken her atışın (tırmık hariç) iniş anındaki z farkı ölçüldü. 60/45/32/25 FPS'te en çok 0,076-0,078 m (tolerans 0,6). Atılımda (hız 26) 60/40/30 FPS'te de 0,076-0,078 m. Düzeltme (`t = -delta / 2.0`, `main.gd:779`) çalışıyor.
- **Sahne yenileme:** Enter/Esc karışık 20 yenileme: nesne 1792 -> 1792, düğüm 178 -> 178, yetim düğüm 0, kaynak 5. Büyüme ve sızıntı yok.
- **Pencereli kare süresi** (`senaryo.gd` kopyası, ayrı cfg, 680 kare): `menu_enter` ortanca 1,68 ms, %99 2,48 ms; `kazan` ortanca 1,49 ms, %99 2,61 ms, en kötü 14,9 ms. İkisi de `SENARYO OK`.
- **Ayar/isim yoklaması** (`secim.gd` statikleri): `skin=99` -> 2'ye kırpılıyor; `isim="x\ny"` -> `x y`; skor listesinde `puan=3.0` (float), `isim=5` (int) elenir; `\n` içeren isim temizlenir; `puan=-5` kabul edilir.
- Yoklamalarda hata çıktısı yok.

## inceleme-4 maddelerinin durumu

| Madde | Durum | Kanıt |
|---|---|---|
| D1 atış FPS'e bağlı | **Düzeltildi** | Yukarıdaki ölçüm; `main.gd:779` |
| D2 gamepad menüden başlatamıyor | **Kodda eklenmiş, doğrulayamadım** | `secim.gd:137-138`. Aşağıda D1 |
| D3 bitiş karesinde ipucu | **Düzeltildi** | `main.gd:725-727` (`finish` sonrası `return`) |
| D4 yumurta kayması kıl payı saatini kuruyor | **Düzeltildi** | `main.gd:750` (`lane = ...`, `set_lane` değil) |
| D5 açılışı atlama | **Düzeltildi** | `main.gd:458-460` (yalnızca sol tık, "KAÇ!" koşullu) |
| T1 şerit sınırı `2` | **Düzeltildi** | `main.gd:151, 571, 668` `LANES.size()` |
| T2 `get_child(0)` | **Düzeltildi** | `body()` yardımcısı, `main.gd:243` |
| T3 yorumlar | **Düzeltildi** | `main.gd:114-115` |
| T4 çift temizleme | **Düzeltildi** | `secim.gd:160-162` |
| T5 ayar 3 kez okunuyor | Değişmedi | `main.gd:308`, `secim.gd:77`, `secim.gd:104` |
| T6 `TITLE_EDGE` = `HUD_TEXT` | Değişmedi | `secim.gd:12`, `main.gd:137` |
| T7 `_ready` uzun | Değişmedi | `main.gd:259-394`, 135 satır |
| T8 `kapi.sh` yorumu | **Düzeltildi** | `kapi.sh:4` |
| O1 `gap_fill.bg_color` her kare | Değişmedi, **önemsiz** | `main.gd:817` |
| O2 / O3 küçük ayırmalar | Değişmedi, ölçülebilir değil | `main.gd:644-722` |

---

## Doğruluk (9/10)

**9 gerekçesi:** Ölçülebilen tek gerçek mantık hatası (D1) giderilmiş ve 25-60 FPS arası ölçülmüş. Durum makinesi (menu -> intro -> run -> over/win), bitiş kilidi, tekrar/menü ayrımı (`go_menu`), skor tablosu (tek yazma, `is_same` ile işaret), ayar okuma (tür kontrolü, kırpma, bozuk dosyada varsayılan) ve yenileme döngüsü kodda satır satır ve ölçümle tutarlı. Aşağıdakiler düşük etkili; 10 vermemem bunlar yüzünden. Not: 13 senaryonun yalnızca 2'sini (`menu_enter`, `kazan`) kendim çalıştırdım; kalan 11'ini ve 50'lik kapıyı yeniden çalıştırmadım (kapı logu 11:13-11:19, kod 11:11:57'de değişmiş, tutarlı).

### Bulgular (önem sırasıyla, hepsi "iyi olur")

**D1. Gamepad A/B yolunun çalışıp çalışmadığı doğrulanamıyor** (`secim.gd:138`, `main.gd:463-464`)
- Bu makinede (`godot --headless` ve pencereli) `InputMap.action_get_events("ui_accept")` yalnızca Enter, KP Enter ve Space içeriyor; `ui_cancel` yalnızca Escape. Joypad olayı yok (`ui_left`/`ui_up`'ta var). Sentetik `InputEventJoypadButton(A).is_action_pressed("ui_accept")` `false` döndü.
- Sonuç: `is_action("ui_accept")`/`is_action("ui_cancel")` koşullarına dayanan joypad dalları, motor pad bağlanınca eylem eşlemesini kendisi eklemiyorsa hiç tetiklenmez. Gerçek pad bağlıyken eklenip eklenmediğini **doğrulamadım**. inceleme-4'ün sentetik "pad" ölçümü de aynı sebeple geçersiz olabilir (menüde A'dan sonra `menu` kalması bu yüzden olabilir).
- Açılış atlama etkilenmiyor: `InputEventJoypadButton` türüne bakıyor, eylem eşlemesine değil.
- Öneri (iki satır): `secim.gd:138`'de `e.is_action_pressed("ui_accept")` yerine `e.button_index == JOY_BUTTON_A and e.pressed`; `main.gd:463-464`'te `again` için `JOY_BUTTON_A`, `menu` için `JOY_BUTTON_B`. Eşlemeden bağımsız ve elle test edilebilir olur.

**D2. İsimde kontrol ve yön karakterleri geçiyor** (`secim.gd:21-23`)
- `clean_name` yalnızca `\n`'yi boşluğa çeviriyor. Ölçüm: `"a\tb\r\rc"` -> bayt dizisi `[97, 9, 98, 13, 13, 99]`; `"‮abc"` uzunluğu 4. Yani sekme, satır başı ve sağdan sola geçersiz kılma karakteri isme girer, HUD'a ve skor tablosuna yansır.
- Etki: görsel/kozmetik; çökme veya veri bozulması yok.
- Öneri: `.replace("\n", " ")` yerine tüm `< 32` karakterleri ve U+202A-202E aralığını boşluğa çeviren tek bir döngü ya da `RegEx`.

**D3. Dikey hız yerdeyken sınırsız eksiye gidiyor** (`main.gd:684`)
- `vy -= GRAVITY * delta` yerdeyken de her karede çalışıyor; `ry` `maxf(..., 0.0)` ile sıfırda tutuluyor ama `vy` birikiyor (60 FPS'te dakikada -72000'e yakın). Zıplamada `vy = JUMP_VY` ile sıfırlandığı için davranışı bozmuyor; yalnızca gereksiz durum.
- Öneri: `ry = maxf(...)` sonrasında `if ry == 0.0 and vy < 0.0: vy = 0.0`.

**D4. Zıplama yüksekliği FPS'e hafifçe bağlı** (`main.gd:684-685`) — hesaba dayanıyor, ölçmedim
- Yarı örtük Euler ile tepe yaklaşık `v²/2g - v*dt/2`: 60 FPS'te ~1,17 m, 30 FPS'te ~1,11 m (kod yorumu 1,2 m diyor). `DOG_H`/`THROW_H` (0,5-0,6) ile karşılaştırınca oynanışı etkilemez. Düzeltmek zorunlu değil.

**D5. `cf.save` sonucu denetlenmiyor** (`secim.gd:73`)
- Yazma hatasında (kota, salt okunur) sessizce geçiliyor; bitiş ekranı puanı gösterir ama kaydedilmez. Düşük risk; en azından `push_warning` yeter.

**Puan düşülmeyen:** Tırmığın hedefi `RAKE_AHEAD` kadar ileride (tasarım). Atılım bitince `to` ile gerçek konum arasındaki sapma (hızı atış anında sabitliyor; tasarım basitliği). Eşit puanlı kaydın tabloya girmemesi (eskiler korunuyor; ölçtüm, `idx=-1`, işaret yok, çökme yok).

---

## Temizlik (8/10)

Kod tarafı temiz: ölü kod yok (kullanılmayan `modeller.gd` sabitleri `TARGET`, `SACK`, `ZONE_DECO` bilinçli bekleyen veri), adsız sabit kalmamış, tekrar azaltılmış. 8'e düşüren, **belgelerin kodla çelişmesi**.

### Düzeltilmesi gerekenler (önem sırasıyla)

1. **`GDD.md:22` skor tanımı yanlış.** "Skor: Toplanan havuç sayısı." Kod: `int(dist) + carrots_total*10 + (200 yuvaya varırsa)` (`main.gd:181-182`). Düzelt: bu formülü yaz.
2. **`GDD.md:98` ve bölüm 8 eski.** Köpek ve kaz "sonraki tur, henüz yapılmayacak" yazıyor; ikisi de kodda (`run_dog`, `kind = "goose"`). Tekrar kayıt, intro, bölgeler ve menü de bölüm 8'in "Ardından" kısmında bekliyor görünüyor. "Şu an / Ardından / Sonraki" listesini güncelle.
3. **`GDD.md:30-32` kontrol tablosu eksik.** Esc (menüye dön), menüdeki ↑↓ renk, Space ve herhangi bir tuşla açılış atlama yok; zıplama tuşu "↑ veya Enter" yazıyor, kod `ui_accept` (Enter, KP Enter, Space) ve `ui_up` kullanıyor. `RAPOR-bolum1.md` "Space" diyor, GDD "Enter" diyor; ikisini birleştir.
4. **Kare sayısı üç yerde farklı.** `kapi.sh:3` "700 karelik", `senaryo.gd:7` `END_FRAME := 690`, `RAPOR-bolum1.md:35` ve kapı logu "680 kare" (ölçülen sayım). Hepsini gerçeğe (680 ölçülen kare, bitiş 690. kare) çek ya da yorumdaki sayıyı kaldır.
5. **`RAPOR-bolum1.md`:** kalite kapısı tablosunda inceleme-4'ün "14 senaryo" demesi yanlış (13 senaryo, `kapi.sh:23`); rapor 13 diyor, doğru. Raporun "Gamepad" ile ilgili bir iddiası yok, ama D1 doğrulanmadan inceleme-4'ün "gamepad ile çalışıyor" cümlesine dayanılmamalı.
6. **T5-T7 (değişmedi):** ayar dosyası açılışta 3 kez okunuyor (`main.gd:308`, `secim.gd:77`, `:104`); `TITLE_EDGE` = `HUD_TEXT`; `_ready` 135 satır (`make_hud()` çıkarmak yeter).

---

## Optimizasyon (9/10)

**9 gerekçesi:** Pencereli ortanca kare 1,5-1,7 ms, %99 2,6 ms altı; 20 sahne yenilemesinde nesne/düğüm/kaynak sayıları sabit, yetim düğüm 0; `items` ve `throws` `CULL_BEHIND` ve iniş anıyla sınırlı; malzeme, mesh ve parçacık malzemesi önbellekli. Kapı logundaki 15 ms ortanca kare (11:15 sonrası) bu kodda yeniden üretilemedi (ben 1,5-1,7 ms ölçtüm); raporun "dış yük" açıklaması mantıklı ama kanıtlanmış değil.

### İyi olur (ölçülebilir etkisi yok)

- `gap_fill.bg_color` her karede yazılıyor (`main.gd:817`). `dist_bar.value` zaten her kare değiştiği için çubuk her halükârda yeniden çiziliyor; kazanç yok. İstenirse `if` ile sarılır.
- Her karede küçük geçici diziler: `EVENTS.keys()` + `filter` (`main.gd:715`), `[rabbit, halil]` (`:721`), HUD metni (`:813`). `EVENTS.keys()` ve `INTRO_CUES.keys()` sabit; `const` dizisi olarak önceden tutulabilir.
- `burst()` her çağrıda yeni `GPUParticles3D` açıp kapatıyor (`main.gd:525-530`); saniyede birkaç kez, ölçülebilir maliyeti yok.

---

## Denetlenemeyenler

- Gerçek gamepad (yukarıda D1) ve gerçek 30-40 FPS donanımı.
- Kalan 11 senaryo ve 50'lik kapı yeniden çalıştırılmadı.
- Pencere boyutu değişirken HUD/`pop()` yerleşimi.
- Yazı tipi yedekleri (ş, ğ, ı, İ harflerinin farklı sistemlerde çizimi).
