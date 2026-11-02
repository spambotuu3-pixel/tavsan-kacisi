# Kod incelemesi 1: Tavşan Kaçışı (oyun/)

**Doğruluk 6/10 · Temizlik 7/10 · Optimizasyon 7/10**

İncelenen dosyalar: `main.gd` (789 satır), `secim.gd`, `modeller.gd`, `test.gd`, `kalite/senaryo.gd`, `toon.gdshader`. Git yok, bu yüzden dosyaların şu anki hâli incelendi. Bulguların çoğu scratchpad'deki küçük deneme script'leriyle, `--fixed-fps 60` ile doğrulandı. Bu script'ler kullanıcının `ayar.cfg` dosyasına dokunmadı ve geçici dosyaları silindi.

Doğrulananlar:
- Birim testleri: `ok`.
- Senaryolar: `bolgeler`, `tekrar_enter` ve `bozuk_cfg` için `SENARYO OK`.
- Bozuk tipli cfg (skin=-7, isim=[1,2], karışık skor listesi): çökme yok, değerler varsayılana düşüyor.
- 10 kez sahne yenileme: nesne sayısı 1900–1976 arasında, kaynak sayısı 5'te sabit. Sızıntı yok.

Genel durum: Çökme bulunmadı. İsim temizleme (boş, uzun, Türkçe) ve cfg okuma sağlam. Puanı düşüren şeyler oyuncunun her koşuda gördüğü küçük hatalar ve `_process` içindeki tekrarlar.

---

## Doğruluk (6/10)

### 9'a çıkmak için düzeltilmesi gerekenler

**D1. Geri sayım yazıları birbirini erken söndürüyor** (`main.gd:429-438`, `pop()`)
- **Sorun:** Her `pop()` yeni bir tween başlatıyor ama öncekini durdurmuyor. Eski tween'in "söndür" adımı 0,78 sn sonra başlayıp yeni yazıyı da söndürüyor.
- **Ölçülen:** "2" yalnızca 2,12–2,57 sn, "1" 2,72–3,17 sn arasında görünüyor. **"KAÇ!" yalnızca ~0,2 sn (13 kare)** görünüyor. Olması gereken her biri için ~1 sn. "Kıl payı!", bölge yazıları ve "↓ ile atıl!" art arda gelince de aynı şey oluyor.
- **Düzeltme:** `var pop_tw: Tween` ekle. `pop()` içinde `if pop_tw: pop_tw.kill()` çalıştır, sonra `pop_tw = pop_label.create_tween()`. Toplam 2 satır.

**D2. Space bitiş ekranını anında geçiyor** (`main.gd:596-600`)
- **Sorun:** `ui_accept` hem zıplama (Space) hem "tekrar koş" tuşu. Planda bitişte yalnızca **Enter** var (PLAN-bolum1.md:32).
- **Senaryo:** Oyuncu çite karşı Space'e basarken Halil yakalıyor. Bir sonraki basış sahneyi yeniliyor. Denemede `over` durumundan 3 kare sonra Space ile yeni sahne açıldı. Puan ve "En iyiler" tablosu hiç görünmüyor.
- **Düzeltme:** Tekrar ve menü tuşlarını, açılışı atlayan `_unhandled_input` içine taşı ve keycode ile bak:
  ```gdscript
  elif state in ["over", "win"] and e is InputEventKey and e.pressed and not e.echo and e.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_ESCAPE]:
  	go_menu = e.keycode == KEY_ESCAPE
  	get_tree().reload_current_scene()
  ```
  `_process` içindeki blokta yalnızca `return` kalır. Senaryolar Enter ve Esc gönderdiği için kalite kapısı bozulmaz.

**D3. Açılışı atlayan tuş oyunda da işliyor** (`main.gd:424-426` ve `607-619`)
- **Sorun:** `_unhandled_input`, `intro_t = INTRO_TIME` yapıyor. Aynı karede `_process` önce `run` durumuna geçiyor, sonra `is_action_just_pressed` ile aynı basışı okuyor.
- **Ölçülen:** Açılış Space ile atlanınca tavşan ilk karede zıplıyor (vy=6,67). ←/→ ile atlanınca şerit değişiyor. PLAN-bolum1.md:61 bu tuşun oyunda sayılmamasını istiyor.
- **Düzeltme:** `main.gd:610` satırındaki `state = "run"` satırının altına `return` ekle. Koşu bir kare geç başlar ve "az önce basıldı" bilgisi o karede silinir. 1 satır.

**D4. Tırmık bir isabette iki kez ceza veriyor** (`main.gd:733-753`)
- **Sorun:** Tırmık tavşana isabet edince `gap -= HIT_COST` uygulanıyor. Ardından 752. satır yine de tavşanın tam üstüne `kind = "hit"` olan bir `RAKE_STUCK` koyuyor. Bir sonraki karede items döngüsü buna çarpıyor ve ikinci ceza geliyor.
- **Ölçülen:** gap 10 → 6 ("Vuruldun!") → 2 ("Tökezledin!"). Tek tırmık Halil'i 8 m yaklaştırıyor.
- **Ne zaman olur:** Oyuncu ilk ~7 sn içinde tırmık atıldıktan hemen sonra atılırsa (hız ≈10 iken atılım ≈16, bu da 1,6 katı ileriye denk geliyor).
- **Düzeltme:** Tırmığı yalnızca ıskalanınca sapla. Zinciri şöyle yap: `if hits(...): ... elif th.fx == "tirmik": items.append(tırmık) else: <kıl payı + yumurta/lahana>`. Bu `elif th.fx != "tirmik"` koşulunu da kaldırır, satır sayısı değişmez.

**D5. Kova karartması bitiş ekranında kalıyor** (`main.gd:659-661`, `finish()` `781`)
- **Sorun:** Oyun kova kafadayken biterse `_process` erken döndüğü için `blind_rect` ekranın üst yarısını kapatmaya devam ediyor. Denemede `over` durumunda `blind_rect.visible=true` görüldü.
- **Düzeltme:** `finish()` içine `blind_rect.visible = false` ekle. İstenirse `run_dust.emitting = false` da eklenebilir (donmuş tavşanın altında toz akmaya devam ediyor). 1–2 satır.

**D6. `DOG_EVERY` fiilen işlemiyor** (`main.gd:552-554`, `573-575`)
- **Sorun:** `dog_t` köpek doğduğu anda kuruluyor. Köpeğin ömrü 35 m / 8,33 m/s = 4,2 sn, bu da 2,5–4,5 sn aralığının çoğundan uzun. Bu yüzden köpek silindiği karede yenisi doğuyor.
- **Ölçülen:** Köpekler 266, 518, 770 ve 1022. karelerde doğdu: tam 252 karede bir (4,2 sn), hiç rastgelelik yok. Plan "rastgele bir şeritte" diyor, kod hep tavşanın şeridini seçiyor. Şerit seçimi bilinçli bir karar olabilir, ama `DOG_EVERY` sabiti yanıltıcı.
- **Düzeltme:** `dog_t = randf_range(...)` satırını doğumdan alıp `dog = {}` satırının yanına taşı. Aralık o zaman "köpek gittikten sonra" ölçülür. Ya da köpeği daha erken sil (`rel < -8`). Hangisinin seçileceği Tasarımcı'nın ayarı.

### İyi olur

**D7. Menü süsleri koşuda yolda kalıyor** (`main.gd:360-361`)
- **Sorun:** Çit (x=-1,3, z=0,6) ve havuç öbeği kök düğüme ekleniyor ve hiç silinmiyor. Halil koşuya başlarken çitin içinden geçiyor. Enter ile tekrar oynayınca (menü atlanınca) bu süsler hiç kurulmuyor, yani iki başlangıç farklı görünüyor.
- **Düzeltme:** İki satırı `if go_menu:` bloğunun üstüne taşı. Havuç öbeği açılıştaki "havuç kemirme" sahnesine de uyuyor. Ya da `on_start` içinde süsleri sil.

**D8. Düşük FPS'te engelin içinden geçilebiliyor** (`main.gd:698`)
- **Sorun:** Çarpışma her karede bir kez nokta olarak bakılıyor ve z penceresi 1,2 m. Hız 26 m/s'ye (en yüksek hız + atılım) çıkınca 21 FPS'in altında tavşan bir karede 1,2 m'den fazla ilerliyor. Çit, varil ve havuç hiç tutmayabiliyor.
- **Düzeltme:** `hits()` değişmeden kalır. `_process` başına `delta = minf(delta, 1.0 / 30.0)` ekle. Zayıf makinede oyun yavaşlar ama engeller atlanmaz.

**D9. Skor tablosunda ok yanlış satırı gösterebilir** (`main.gd:789`)
- **Sorun:** `table.find(entry)` sözlükleri içeriğe göre karşılaştırıyor. Aynı isim, puan ve renkte eski bir kayıt varsa "◀" eski kaydın yanına çıkabiliyor. Etkisi neredeyse yok.

---

## Temizlik (7/10)

Genel olarak okunaklı: yorumlar kısa ve nedenini anlatıyor, sabitler başta toplu. Puanı düşürenler:

### 9'a çıkmak için düzeltilmesi gerekenler

**T1. "Vuruldun" bloğu üç kez kopyalanmış** (`main.gd:569-572`, `710-713`, `734-737`)
- **Sorun:** `gap -= HIT_COST; blink_t = BLINK_TIME; say(...); burst(... STAR_C, 10)` köpek, engel ve atış için ayrı ayrı yazılmış. Vurulma sesi ya da çarpma sonrası dokunulmazlık gibi bir ekleme üç yerde yapılmak zorunda. Biri unutulursa davranış tutarsız olur.
- **Düzeltme:** `func hurt(text: String) -> void` yaz ve üç yerden çağır. Yaklaşık −8 satır.

**T2. Kümesin yeri bir mesaj sözlüğünün sırasına bağlı** (`main.gd:276`)
- **Sorun:** `-EVENTS.keys()[1]` kullanılıyor. EVENTS'e mesela 100 m'de bir mesaj eklenirse kümes sessizce yanlış bölgeye gider.
- **Düzeltme:** `-ZONES[2][0]` kullan. Bu bölge tablosundan gelir, kümes bölgesi 350 m.

**T3. `_process` 190 satır ve altı ayrı iş yapıyor** (`main.gd:590-777`)
- **Sorun:** Girdi, fizik, kamera ve efektler, nesne döngüsü, atışlar ve HUD aynı fonksiyonda. `run_dog` zaten ayrılmış ve iyi bir örnek.
- **Düzeltme:** En az HUD kısmını (`761-777`) `update_hud(p, dist)` fonksiyonuna, atış döngüsünü (`716-756`) `run_throws(...)` fonksiyonuna ayır. Satır sayısı için değil, iş başına bölmek için.

### İyi olur

- **T4.** `secim.gd:152-153`: `start()` içinde iki `save()` çağrısı var ve her biri dosyayı baştan okuyup yazıyor. Tek `config()`, iki `set_value`, bir `save` yeter. Ayrıca `secim.gd:73` `load_choice()` fonksiyonunu ikinci kez çağırıyor (main.gd:279 zaten okudu).
- **T5.** `main.gd:784`: Skor kaydındaki `renk = skin` alanı hiçbir yerde okunmuyor (`score_lines` kullanmıyor). Ya kullan ya sil.
- **T6.** `main.gd:8`: `THROWN` içinde kova rengi `M.METAL`, tırmık rengi `M.WOOD` ile aynı ama elle tekrar yazılmış. Paletten al.
- **T7.** `_process` içinde adsız sayılar var: zıplama 7.0, yerçekimi 20.0, şerit hızı 12.0, gap toplama 0.5, hızlanma 0.15, tavan 20.0, silme mesafesi 15. Diğer ayarların hepsi adlı sabit. Tasarımcının ayarlayacağı değerler de bunlar.
- **T8.** `kalite/senaryo.gd`: `bozuk_cfg`, `skor_bos` ve `skor_dolu` senaryoları kendi koşullarını kurmuyor. Dosyayı bozmuyor, tabloyu boşaltmıyor ya da doldurmuyor. Tek başına çalıştırılınca `yakalan` ile birebir aynılar. Koşulu dışarıdaki döngü hazırlamıyorsa bu senaryolar yanlış güven veriyor. `_initialize` içinde senaryoya göre `test_ayar.cfg` dosyasını yazmak 5–6 satır.

---

## Optimizasyon (7/10)

Bu ölçekte kare maliyeti düşük: ~350 düğüm, ~30–40 item, sahne yenilemede sızıntı yok (ölçüldü). Puanı düşürenler gereksiz ayırmalar:

### 9'a çıkmak için düzeltilmesi gerekenler

**O1. Her patlama sıfırdan kaynak üretiyor** (`main.gd:442-482`, `burst()` → `particles()`)
- **Sorun:** Her zıplama inişi, havuç ve vurulmada yeni bir `ParticleProcessMaterial`, `Gradient`, `GradientTexture1D` (GPU'ya doku yükleme), `SphereMesh` (64×32 segment, ~2 bin köşe GPU'ya yükleniyor), `StandardMaterial3D` ve `GPUParticles3D` oluşuyor. Saniyede birkaç kez yapılıp çöpe atılıyor. `shape_mesh` ve `soft_mat` zaten önbellek kullanıyor, bu kod onlara uymuyor.
- **Düzeltme:** `particles()` içinde process material ve draw mesh'i `{[color, vel]: [pm, mesh]}` sözlüğünde önbelleğe al. Küre mesh'i zaten renkten bağımsız, onu tek kopya yap. Yaklaşık 4 satır.

**O2. Her karede liste kopyası ve O(n) silme** (`main.gd:679`, `699`, `726`, `756`)
- **Sorun:** `items.duplicate()` ve `throws.duplicate()` her karede yeni dizi ayırıyor. `items.erase(it)` de sözlükleri içerik içerik karşılaştırarak arıyor.
- **Düzeltme:** Sondan başa indeksle dön: `for i in range(items.size() - 1, -1, -1):` ve silerken `items.remove_at(i)` kullan. Hem kopya hem arama gider. Atışlar için de aynısı.

### İyi olur

- **O3.** `main.gd:653-658`: Atılımda 0,1 sn'de bir `model(M.DUST)` çağrılıyor: kök, body ve 3 mesh, artı bir tween (saniyede ~50 düğüm oluşup siliniyor). `run_dust` atılımda zaten `amount_ratio = 1.0` ile yoğunlaşıyor. Toz bulutu efekti tasarım gereği değilse bu blok silinebilir.
- **O4.** `main.gd:603`, `671` (`crossed`): Her karede `keys()`, `filter` ve lambda ile yeni dizi oluşuyor. Maliyeti çok küçük, fonksiyon test ediliyor ve plan istiyor. Değiştirmek şart değil.
- **O5.** `main.gd:766`: `gap_fill.bg_color` her karede yazılıyor ve stylebox'ın `changed` sinyalini tetikleyip çubuğu yeniden çizdiriyor. Değer değişmediyse yazmamak yeter. Maliyeti çok küçük.
- **O6.** İlk `burst()` çağrısında parçacık shader'ı derleniyor, ilk inişte küçük bir takılma olabilir. Önbellek (O1) ile `_ready` içinde bir kez görünmez bir patlama yapmak bunu da çözer.

---

## Özet

| # | Bulgu | Önem | Boyut |
|---|---|---|---|
| D1 | Geri sayım yazıları erken sönüyor | Orta (her koşuda görünür) | +2 satır |
| D2 | Space bitiş ekranını geçiyor | Orta | ~0 satır |
| D3 | Açılışı atlayan tuş zıplatıyor | Düşük-orta | +1 satır |
| D4 | Tırmıkta çift ceza | Düşük-orta | 0 satır |
| D5 | Kova karartması bitişte kalıyor | Düşük | +1 satır |
| D6 | DOG_EVERY işlemiyor | Düşük (ayar) | taşıma |
| T1–T3 | Vurulma kopyası, EVENTS sırası, uzun `_process` | Temizlik | −8 satır |
| O1–O2 | Patlama kaynakları, liste kopyası | Optimizasyon | ~+4 satır |

**Karar:** 9'a çıkmak için önce D1–D6, T1–T3 ve O1–O2 düzeltilmeli. Hepsi küçük ve yerel; `hits()`, çit (0.6) ve varil (1.6) değerlerine dokunulmuyor.
**Sadeleşme:** yaklaşık −10 satır mümkün (T1, D4, D2).
**Denetlenmeyenler:** Pencereli çalıştırmada gerçek GPU kare süresi ölçülmedi. Fareyle boş alana tıklanınca isim kutusunun odağı kaybedip kaybetmediği (Enter'ın menüde ölmesi) denenmedi. D4'ün gerçek oyunda ne sıklıkla yaşandığı yalnızca hesapla tahmin edildi.
