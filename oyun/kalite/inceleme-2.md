# Kod incelemesi 2: Tavşan Kaçışı (oyun/)

**Doğruluk 7/10 · Temizlik 8/10 · Optimizasyon 9/10**

İncelenen dosyalar: `main.gd` (814 satır), `secim.gd`, `modeller.gd`, `test.gd`, `kalite/senaryo.gd`, `toon.gdshader`. Git olmadığı için dosyaların şu anki hâli incelendi. `inceleme-1.md`'ye güvenilmedi, her maddesi koda bakılarak yeniden kontrol edildi.

**Nasıl doğrulandı:**
- Birim testleri `ok` verdi (çıkış kodu 0).
- 14 senaryonun hepsi `SENARYO OK` verdi. Senaryolar, `senaryo.gd`'nin `user://inceleme_ayar.cfg` kullanan bir kopyasıyla scratchpad'den, `--headless --fixed-fps 60` ile koşturuldu. Böylece `test_ayar.cfg` dosyasına dokunulmadı.
- İki yoklama script'i yazıldı (`probe.gd`, `probe2.gd`, ikisi de scratchpad'de). Bunlarla şunlara bakıldı: menü ve açılıştaki durum, açılışı atlama, atılım + köpek + kova + uçan atış sürerken yakalanma, 12 kez art arda sahne yenileme (Enter ve Esc karışık), eşit puanlı skor ekleme ve Enter ile zıplayan oyuncunun bitiş ekranı.

**Genel durum:** Çökme bulunmadı. İsim temizleme ve bozuk cfg okuma sağlam. 12 yenilemede sızıntı yok: nesne sayısı 1909–2020 arasında, yetim düğüm 0, kaynak sayısı 5'te sabit. inceleme-1'in bulgularının çoğu gerçekten düzeltilmiş (tablo sonda). Puanı düşüren şeyler oyuncunun her koşuda gördüğü küçük görüntü hataları ve yarım kalmış bir D2 düzeltmesi.

---

## Doğruluk (7/10)

### 9 için şart

**D1. Enter hem zıplıyor hem bitiş ekranını geçiyor (inceleme-1 D2'nin yarısı düzeltilmiş)** (`main.gd:643`, `main.gd:440`)
- **Sorun:** GDD.md:30'a göre zıplama tuşu "↑ veya Enter". Kod da `ui_accept` ile zıplatıyor ve Enter bu eylemin içinde. Bitiş ekranında ise Enter sahneyi hemen yeniliyor. Önceki düzeltmede yalnızca Space çıkarılmıştı.
- **Ölçülen (`probe2.gd`):** Enter ile zıplandı (vy=6,33), tavşan havadayken yakalandı, 2 kare sonra yine Enter'a basıldı. Sahne yenilendi ve durum `intro` oldu. Bitiş paneli yalnızca ~5 kare göründü, puan ve tablo okunamadı.
- **Kim yaşar:** Enter ile zıplayan ve yakalanırken tuşa art arda basan her oyuncu.
- **Düzeltme:** `finish()` içinde girdiyi kısa bir süre kapat (2 satır):
  ```gdscript
  set_process_unhandled_input(false)  # zıplarken yakalanan oyuncunun Enter'ı tabloyu geçmesin
  get_tree().create_timer(0.6).timeout.connect(set_process_unhandled_input.bind(true))
  ```
  `tekrar_enter` ve `esc_menu` senaryoları tuşa 180 kare sonra bastığı için kalite kapısı bozulmaz.

**D2. Açılış boyunca HUD bayat ve yanıltıcı** (`main.gd:414-419`, `on_start`)
- **Sorun:** `on_start` HUD panelini gösteriyor ama `update_hud` ilk kez koşunun ilk karesinde çalışıyor. 3,5 saniyelik açılış boyunca HUD'ın içi boş ya da yanlış kalıyor.
- **Ölçülen (`probe.gd`, açılışın 28. karesi):** `hud.text=''` (isim ve metre yok). `gap_bar=0`, yani "Halil'e uzaklık" çubuğu boş ve Halil yakalamak üzereymiş gibi görünüyor. `dash_hint.visible=true`, yani "↓ ATIL" yazısı çıkıyor. 3 atılım havucu tam renkli, oysa havuç sayısı 0.
- **Ne zaman olur:** Her koşuda, Enter ile tekrar koşunca da.
- **Düzeltme:** `on_start` sonuna, `state = "intro"` satırından sonra `update_hud(0.0)` ekle (1 satır). `msg_label` gizli kalır çünkü durum `run` değil. `can_dash(0, 0)` yanlış döndüğü için ipucu da çıkmaz.

**D3. Menüde ve açılışta duran tavşanın altından toz akıyor** (`main.gd:409`, `particles()` `489-496`)
- **Sorun:** `GPUParticles3D` nesnesinin `emitting` değeri varsayılanda `true`. `run_dust` ancak koşu başlayınca kapatılıp açılıyor. Menüde (ve her renk değişikliğinde yeniden) atılımdaki tam yoğunlukla (`amount_ratio=1.0`) toz çıkıyor. Açılışta da aynısı oluyor.
- **Ölçülen:** Menüde `run_dust.emitting=true amount_ratio=1.00`, açılışta `dust=true`.
- **Düzeltme:** `particles()` içinde `g.emitting = false` ekle (1 satır). `burst()` zaten `g.emitting = true` yapıyor. `_process:684` de koşuda tozu açıyor.

### İyi olur

**D4. Açılış atlanınca "KAÇ!" hiç çıkmıyor, "HEY! Havuçlarım!" koşuya taşıyor** (`main.gd:438-439`)
- **Ölçülen:** 0,8. saniyede tuşa basıldı. Koşu başladığında ekranda hâlâ `HEY! Havuçlarım!` vardı (a=1,0) ve ardından başka yazı gelmedi. Koşunun başladığını gösteren bir işaret olmuyor.
- **Düzeltme:** Atlama dalına `pop(INTRO_CUES[3.3], HUD_WARN)` ekle (1 satır). `pop_tw.kill()` eski yazıyı zaten siliyor.

**D5. Tavuk, havuç dönüşü ve gövde sallanması gerçek saatle çalışıyor** (`main.gd:694`)
- **Sorun:** `Time.get_ticks_msec()` kullanılıyor, oyun ise `MAX_DT` ile yavaşlatılan `clock` ile ilerliyor. 30 FPS'in altında oyun bilerek yavaşlıyor ama tavuklar gerçek hızla şerit değiştiriyor ve yavaşlamış tavşanın önünde daha hızlı gidip geliyor. `--fixed-fps` çalıştırmalarında da tavuk konumu kareye bağlı olmaktan çıkıyor ve tekrarlanabilir olmuyor.
- **Düzeltme:** `var t := clock` (1 satır).

**D6. Başlangıçtaki havuç yığını `BURROW.slice(2)` dizi sırasına bağlı** (`main.gd:362`)
- **Sorun:** Tasarımcı `BURROW` başına bir parça eklerse yol kenarında havuç yerine toprak tümseği çıkar. Hesaba göre ikinci havuç (-0,1, 0,15, 0,2) noktasına düşüyor, bu da tavşanın gövdesinin içi ya da arkası (tavşan -z yönüne bakıyor). Bu görsel olarak denetlenmedi.
- **Düzeltme:** `modeller.gd` içine adlı bir `CARROT_PILE` sabiti ekle (Tasarımcı'nın dosyası) ve konumu ağzın önüne al.

**D7. `load_scores` elle bozulmuş tabloyu temizlemiyor** (`secim.gd:59-63`)
- **Sorun:** Tipi doğru ama 300 karakterlik isim ya da 40 kayıtlık sırasız liste olduğu gibi menüye basılıyor. Tablo ancak bir sonraki kayıtta sıralanıp 5'e kesiliyor. Dosya yalnızca kullanıcının kendi diski olduğu için önemi düşük.
- **Düzeltme:** Dönüşte `.slice(0, TOP)` kullan ve `score_lines` içinde `clean_name(list[i].isim, "?")` çağır.

---

## Temizlik (8/10)

`hurt()`, `run_items`, `run_throws` ve `update_hud` ayrılmış. `_process` 87 satıra inmiş ve okunuyor. Ayar değerlerinin çoğu adlı sabit. Kalanlar küçük kopyalar ve adsız sayılar.

### 9 için şart

**T1. `run_throws` ve köpekteki ayar sayıları adsız** (`main.gd:745`, `747`, `749`, `758`, `761`, `774`, `589`)
- **Sorun:** Atış aralığı `randf_range(1.5, 3.5)`, sona doğru sıklaşma `0.6`, tırmık ileri payı `1.6`, atış yayı `4.0`, isabet yüksekliği `0.5`, sekme mesafesi `0.6`, köpek yüksekliği `0.6` elle yazılmış. Dosyanın kendi kuralı "Tasarımcı ayarlar" değerlerini başta adlı sabit yapmak. Ayar turunda (GDD:93, "atış sıklığı") ilk dokunulacak değerler bunlar ve fonksiyonun içinde aranmaları gerekiyor.
- **Düzeltme:** `THROW_EVERY := Vector2(1.5, 3.5)`, `THROW_RUSH := 0.6`, `RAKE_AHEAD := 1.6`, `THROW_ARC := 4.0`, `DOG_H := 0.6` gibi 5–6 sabit ekle.

**T2. `soft_mat` içinde ölü dal ve çift kontrol** (`main.gd:196-214`)
- **Sorun:** İkinci blok yalnızca saydam renkler için çalışıyor, yani `if color.a < 1.0` her zaman doğru ve ölü. İki ayrı `if not mats.has(color)` bloğu okuyana opak StandardMaterial hâlâ mümkünmüş gibi gösteriyor.
- **Düzeltme:** `if mats.has(color): return mats[color]`, ardından `color.a >= 1.0` için if/else. `transparency` satırı koşulsuz kalır. Yaklaşık −3 satır.

**T3. Silme koşulu tek döngüde üç kez yazılmış** (`main.gd:726`, `728`, `737`)
- **Sorun:** `n.position.z > p.z + CULL_BEHIND` ve iki tersi aynı yinelemede tekrar ediliyor. Koşul değişirse (örneğin türe göre farklı mesafe) üç yeri birden değiştirmek gerekiyor. Biri unutulursa geride kalan havuç toplanır ya da geride kalan engel tavşanı vurur.
- **Düzeltme:** `var gone := n.position.z > p.z + CULL_BEHIND` satırını bir kez yaz ve üç yerde kullan.

### İyi olur

- **T4.** `main.gd:11`: `THROWN` içinde yumurta `Color(1, 0.97, 0.9)` ve lahana `Color(0.45, 0.75, 0.35)` elle yazılmış. Bunlar `M.EGG_WHITE` (0.97, 0.96, 0.9) ve `M.CABBAGE_LIGHT` (0.55, 0.8, 0.4) ile tutmuyor, bu yüzden düşünce renk değişiyor. Ayrıca gereksiz iki malzeme daha üretiliyor. Paletten al.
- **T5.** Şerit sınırı `o >= 0 and o <= 2` ifadesi `main.gd:555` ve `723`'te tekrar ediyor. `2` sayısı `142` ve `642`'de de geçiyor. Bunlar `LANES.size() - 1` olmalı.
- **T6.** `main.gd:414`: `on_start(_skin, ...)` parametresini kullanmıyor. Renk zaten `renk` sinyaliyle uygulanıyor, bu yüzden `basla` sinyalinin `skin` parametresi gereksiz.
- **T7.** `secim.gd:12`: `TITLE_EDGE`, `main.HUD_TEXT` sabitinin kopyası. `secim.gd:74` de `load_choice()` fonksiyonunu ikinci kez okuyor (main.gd:289 zaten okudu). Menü açılırken ayar dosyası diskten üç kez, `start()` ile dört kez okunuyor.
- **T8.** `main.gd:379-395`: Menünün görünümü (`ui_theme`) `main.gd` içinde, menünün kendisi `secim.gd` içinde. Görünümü değiştirmek isteyen iki dosyaya bakmak zorunda. `rounded()` static yapılırsa tema `secim.gd`'ye taşınabilir.

---

## Optimizasyon (9/10)

Ölçek küçük: ~290–380 düğüm, 20–30 item. Parçacık malzemeleri ve küre artık önbellekte (`fx`, `fx_mesh`). Listeler sondan başa `remove_at` ile dolaşılıyor, kopya alınmıyor. Atılım tozu (`M.DUST` modelleri) kaldırılmış. 12 yenilemede sızıntı yok. Kalanların hepsi küçük.

### 9 için şart
Yok.

### İyi olur

- **O1.** `main.gd:489-504`: Her iniş, havuç ve vurulma yeni bir `GPUParticles3D` düğümü açıp kapatıyor. Her düğüm RenderingServer'da kendi parçacık arabelleğini ayırıyor (saniyede ~1–3 kez). Bu ölçekte sorun değil. Ölçek büyürse şunlar yeterli: `g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF` (saydam, gölgesiz noktaların gölge haritasına yazılmasını önler), ardından 4–5 düğümlük bir döngüsel havuz.
- **O2.** `main.gd:789`: `gap_fill.bg_color` her karede yazılıyor. Bu `changed` sinyalini tetikliyor ve çubuk her karede yeniden çiziliyor. Değer değişmediyse yazmamak yeter.
- **O3.** D3'teki menü tozu menüde boşuna GPU harcıyor. D3 düzeltmesi bunu da çözer.
- **O4.** `main.gd:627`, `689`, `695`: `keys()`, `filter` ve `[rabbit, halil]` her karede küçük diziler oluşturuyor. Maliyeti çok küçük, değiştirmek şart değil.

---

## inceleme-1 bulgularının durumu

| # | Durum | Not |
|---|---|---|
| D1 pop söndürme | Düzeltildi | `pop_tw.kill()` (`main.gd:451-452`) |
| D2 Space bitişi geçiyor | **Yarım** | Space düzeldi, Enter (GDD'deki zıplama tuşu) hâlâ geçiyor. Bu incelemede D1. |
| D3 atlama tuşu zıplatıyor | Düzeltildi | `main.gd:635` `return` |
| D4 tırmıkta çift ceza | Düzeltildi | `elif th.fx == "tirmik"` |
| D5 kova karartması | Düzeltildi | `finish()` gizliyor. Yoklamada `blind_rect=false`, `dust=false` görüldü. |
| D6 DOG_EVERY | Düzeltildi | Süre artık köpek gidince başlıyor (`main.gd:594`) |
| D7 menü süsleri | Kısmen | Artık iki yolda da kuruluyor, çit yolun dışında (x=-3,4). Havuç yığını için bu incelemede D6. |
| D8 düşük FPS | Düzeltildi | `MAX_DT` |
| D9 skor oku | Düzeltildi | `find_custom(is_same)` |
| T1, T2, T3, T5, T7, T8 | Düzeltildi | `hurt()`, `ZONES[2][0]`, fonksiyonlar ayrıldı, `renk` alanı silindi, sabitler adlandı, senaryolar kendi cfg'lerini yazıyor |
| T4 çift save | Kısmen | Tek save kaldı, ama `secim.gd:74` hâlâ ikinci kez okuyor |
| T6 THROWN renkleri | Kısmen | Kova ve tırmık paletten alınıyor, yumurta ve lahana almıyor (bu incelemede T4) |
| O1, O2, O3 | Düzeltildi | |
| O4, O5, O6 | Değişmedi | O4 ve O5 önemsiz. O6 (ilk patlamada shader derlemesi) headless çalıştırmada ölçülemedi. |

## Reddedilen iddia

- **"`insert_score` kararsız sıralıyor, eşit puanlar rastgele yer değiştirir":** Ölçüldü ve doğru değil. 5 tane 300 puanlı kayda 200 kez yeni bir 300 eklendi, sonuç hep aynıydı: eski sıra korundu, yeni kayıt kesildi. Godot 16 elemandan küçük dizilerde ekleme sıralaması kullanıyor ve bu sıralama kararlı. Liste en fazla 6 eleman.

## Kalite kapısı için not (oyun kodu değil)

- `bozuk_cfg` senaryosu her çalıştırmada motorun kendi yazdığı 4 satırlık `ERROR: ConfigFile parse error ...` çıktısını üretiyor. Bunlar `ConfigFile.load` fonksiyonundan geliyor ve beklenen davranış: oyun varsayılana düşüyor ve dosyayı ilk kayıtta onarıyor. PLAN-bolum1.md §6'daki "ERROR çıktısı sayacı sıfırlar" kuralı bu senaryoda bu satırlar için istisna tanımazsa 50'lik döngü hiç tamamlanamaz.

## Denetlenemeyenler

- Pencereli çalıştırmada gerçek GPU kare süresi (SSAO, MSAA 4x, DOF, gölge). Tüm çalıştırmalar headless yapıldı.
- İlk `burst()` sırasında shader derlemesinden doğan takılma (O6).
- Havuç yığınının tavşanın içine girip girmediği (D6). Yalnızca koordinatlardan hesaplandı.
- Gamepad girdisi. Açılış yalnızca klavye ve fareyle atlanıyor, gamepad ile denenmedi.
- Fareyle boş yere tıklama yalnızca `fare_bos` senaryosuyla, sentetik olayla denendi.
