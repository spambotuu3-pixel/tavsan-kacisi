# Kod incelemesi 4: Tavşan Kaçışı (oyun/)

**Doğruluk 8/10 · Temizlik 9/10 · Optimizasyon 9/10**

İncelenen dosyalar: `main.gd` (838 satır), `secim.gd` (162), `modeller.gd` (393), `test.gd`, `kalite/senaryo.gd`, `kalite/kapi.sh`, `toon.gdshader`. Git olmadığı için dosyalar şu anki hâlleriyle incelendi. `code-review` ve `ponytail-review` yöntemleri uygulandı. Araçlardan gelen her iddia ya oyun çalıştırılarak ya da satır satır okunarak doğrulandı. Önceki incelemelere güvenilmedi.

**Nasıl doğrulandı:**
- `test.gd`: `ok`, 25 durum, çıkış kodu 0.
- **14 senaryo:** `senaryo.gd`'nin `user://inceleme4_ayar.cfg` kullanan bir kopyasıyla pencereli koşturuldu (`--fixed-fps 60 --disable-vsync`). 14'ünün hepsi `SENARYO OK` verdi. Kare süresi ortanca 1,6–2,2 ms, %99'luk dilim 5 ms'nin altında. En kötü kare 63 ms, o da sahnenin yenilendiği kare. Tek hata çıktısı `bozuk_cfg` senaryosundaki motorun kendi `ConfigFile parse error` satırları; bu beklenen bir durum.
- **Yoklama script'i** (`scratchpad/probe4.gd`), headless çalıştırıldı:
  - **atis:** Tavşan şeridinde kıpırdamadan 20 m/s koşuyor. Her atış indiğinde tavşan ile hedef arasındaki z farkı ölçüldü. Ölçüm 60, 45, 32, 30 ve 25 FPS'te yapıldı.
  - **pad:** Menüde gamepad'in A tuşu, ardından Enter.
  - **yenile:** Enter ve Esc karışık 20 sahne yenilemesi.
- **Önerilen düzeltme denendi:** D1 için önerilen düzeltme, oyunun scratchpad'deki bir kopyasında denendi. Projedeki dosyalara dokunulmadı.
- Geçici `inceleme4_ayar.cfg` silindi. `ayar.cfg` ve `test_ayar.cfg` dosyalarına dokunulmadı.

**inceleme-3'ün "9 için şart" maddeleri:**

| inceleme-3 | Durum | Kanıt |
|---|---|---|
| T1 Kopya renkler (yumurta, lahana, hedef) | **Düzeltildi** | `THROWN` içinde `M.EGG_WHITE` ve `M.CABBAGE_LIGHT` var (`main.gd:10-11`). Hedef işaretinde `M.TARGET_C` (`main.gd:771`). `M.TARGET` modeli henüz bağlanmadı; bu, D turu için bilinçli olarak bekletiliyor. |
| T2 `THROWN`'ın 5. alanı ve `fx` adı | **Düzeltildi** | 4 alan kaldı, etki `th.item` ile ada göre seçiliyor (`784-799`). Önbelleğin adı `fx_mats` oldu (`119`). |
| İyi olur: D1 kova, D4 sıralama ve `\n`, T3 `THROW_H`, T8 `INTRO_GO` | Düzeltildi | `main.gd:830`, `secim.gd:22`, `secim.gd:65`, `main.gd:56`, `main.gd:18` |
| İyi olur: D3 gamepad | **Yarım düzeltildi** | Açılış ve bitiş ekranı gamepad ile çalışıyor, menü çalışmıyor. Bu yüzden yeni bir tuzak çıktı (bu incelemede D2). |
| İyi olur: T4–T7 | Değişmedi | Aşağıda, "iyi olur" altında. |

---

## Doğruluk (8/10)

Çökme, sızıntı ya da yanlış durum geçişi bulunmadı. Bitiş kilidi, bozuk ayar dosyası, isim temizliği ve yenileme döngüsü sağlam. Puanı düşüren iki gerçek hata var. Biri oyunun ana mekaniğinde, düşük FPS'te ortaya çıkıyor. Diğeri gamepad ile oynayanı menüde mahsur bırakıyor.

### 9 için şart

**D1. Atış isabeti FPS'e bağlı: ~33 FPS'in altında duran tavşan hiç vurulmuyor** (`main.gd:771-777`)
- **Sorun:** Yeni atış, oluşturulduğu karede de ilerliyor. Satır 776'daki `th.t += delta` aynı karede çalışıyor. Hedef ise (`to = p.z - spd`, satır 769) tavşanın o karede zaten ilerlemiş konumundan hesaplanıyor. Sonuç olarak atış bir kare erken iniyor ve iniş anında tavşan hedefin `spd × delta` kadar gerisinde kalıyor. `hits()`'in z toleransı 0,6 m.
- **Ölçülen** (tavşan şeridinde kıpırdamadan 20 m/s koşuyor):

  | Sabit FPS | İnişte z farkı | Aynı şeritte, tırmık dışı iniş | İsabet |
  |---|---|---|---|
  | 60 | 0,333 m | 10 | 10 |
  | 45 | 0,445 m | 9 | 9 |
  | **32** | **0,625 m** | **8** | **0** |
  | 30 | 0,0 m | 11 | 11 |

- **30 FPS neden çalışıyor:** Orada çalışması şans. 30 kez `1/30` toplanınca kayan noktalı sayıda sonuç 0,99999 çıkıyor ve atış bir kare geç iniyor.
- **Atılımda:** Hız 26 m/s olduğu için sınır daha da yükseliyor. Hesaba göre (ölçülmedi) 43 FPS'in altında aynı hata çıkıyor.
- **Ne zaman olur:** SSAO, MSAA 4x ve DOF açık olduğu için zayıf bir dizüstünde 31–40 FPS gerçekçi bir aralık. Orada atışlar "kendiliğinden" ıskalıyor. Tasarımın "şeridinde kalırsan vurulursun" kuralı bozuluyor. Kova ve lahana etkileri de hiç çıkmıyor.
- **Düzeltme (1 ifade):** Atış sözlüğünde `t = 0.0` yerine `t = -delta / 2.0` yaz. Böylece iniş, tavşanın 1 sn ± yarım kare yol aldığı kareye denk gelir. Hata en çok `spd × MAX_DT / 2` olur, bu da 26 m/s'de 0,43 m, yani her zaman 0,6'nın altında. `hits()` değişmiyor.
- **Düzeltme denendi:** Kopyada 60, 45, 32 ve 30 FPS'te tüm inişler 0,000 m farkla ve isabetle sonuçlandı.

**D2. Gamepad bitiş ekranından menüye götürüyor, ama menüden koşu başlatılamıyor** (`secim.gd:133-139`, `main.gd:458`)
- **Sorun:** Bitiş ekranında B (`ui_cancel`) basılınca `go_menu = true` oluyor ve menü açılıyor. Menüde ise koşuyu başlatacak bir gamepad yolu yok:
  - `LineEdit`'in `text_submitted` sinyali yalnızca `ui_text_submit` eylemine, yani Enter tuşuna bağlı.
  - Düğmelerde `FOCUS_NONE` var, gamepad ile odaklanamıyorlar.
  - `_input` yalnızca `KEY_ENTER` tuşuna bakıyor.
- **Ölçülen:** Menüde A basıldıktan sonra durum `menu` olarak kaldı. Enter basılınca `intro` oldu.
- **Sonuç:** Gamepad'le oynayan, B'ye bastığı anda klavyesiz kalıyor. Renk ↑↓ ile değişiyor, ama oyun başlamıyor.
- **Not:** GDD gamepad vaat etmiyor. Ama kod gamepad'i açılışta ve bitişte kendisi destekliyor, bu yüzden yarım destek tuzak yaratıyor.
- **Düzeltme (1 satır):** `secim.gd:137`'deki `elif`'e `or (e is InputEventJoypadButton and e.is_action_pressed("ui_accept"))` dalını ekle. Ya da `main.gd:458`'deki gamepad B dalını kaldır. Daha az iyi bir çözüm.

### İyi olur

**D3. Bitiş karesinde HUD ipucu panelin üstünde beliriyor** (`main.gd:719-722`, `818-820`)
- **Sorun:** `finish()` çağrıldıktan sonra aynı karede yine `update_hud()` çalışıyor. Havuç sayısı ilk kez 3'e çıktığı kare koşunun bittiği kareyse, `pop("↓ ile atıl!")` bitiş panelinin ortasında çıkıyor.
- **Ne zaman olur:** 3. havuç ile yakalanmaya yol açan isabet aynı kareye denk gelmeli; bu nadir bir durum. Kod okunarak doğrulandı, oyunda üretilmedi.
- **Düzeltme:** `finish(...)` çağrısından sonra `return` ekle (`update_hud` bitişte zaten gerekmiyor). Ya da 818'deki koşula `state == "run"` ekle.

**D4. Yumurta kayması "kıl payı" saatini de kuruyor** (`main.gd:743`)
- **Sorun:** `set_lane()` istemsiz kaymayı oyuncunun kaçışı gibi kaydediyor, çünkü `lane_left_t` güncelleniyor.
- **Sonuç:** Kayıştan sonraki 0,25 sn içinde eski şeride düşen bir atış, hak edilmemiş +1 gap ve "Kıl payı!" veriyor. Etkisi küçük.
- **Düzeltme:** Kaymada `lane = ...` değerini doğrudan ata, ya da bunun bilinçli bir tercih olduğunu bir yorumla belirt.
- **Puan düşülmeyen:** Kaymanın "en az bir şerit boş" güvencesini bozması PLAN-mekanikler'deki tasarımın kendisi. Bunun için puan düşülmedi.

**D5. Açılışı atlama fazla geniş** (`main.gd:453-455`)
- **Fare tekerleği:** Tekerlek olayı da `is_pressed()` döndürüyor. Fare tekerleğini çeviren oyuncu açılışı istemeden atlıyor.
- **Çift "KAÇ!":** 3,3–3,5 sn arasında bir tuşa basılınca "KAÇ!" ikinci kez beliriyor.
- **Düzeltme:** Fare için `e.button_index == MOUSE_BUTTON_LEFT` koşulu ekle. `pop` çağrısını `if intro_t < INTRO_CUES.keys()[-1]` koşuluna bağla.

---

## Temizlik (9/10)

inceleme-3'ün T1 ve T2 maddeleri gerçekten düzeltilmiş. Kalanlar küçük, birbirinden bağımsız düzeltmeler.

### 9 için şart
Yok.

### İyi olur

- **T1. Şerit sınırı `2` olarak elle yazılmış** (`main.gd:151`, `565`, `662`)
  - **Sorun:** Bu sınır üç yerde sabit sayı olarak geçiyor. Oysa `LANES` ve `near_lanes()` zaten var.
  - **Sonuç:** 4. bir şerit eklenirse üç yer de sessizce yanlış çalışır.
  - **Düzeltme:** `LANES.size() - 1` kullan. 565'te `range(LANES.size())`.
- **T2. Tavşan gövdesine indeksle erişiliyor** (`main.gd:421`, `650`, `653`, `716`)
  - **Sorun:** Gövdeye `rabbit.get_child(0)` ile ulaşılıyor.
  - **Sonuç:** `model()` yapısı değişirse yanlış düğüm oynatılır.
  - **Düzeltme:** `var rabbit_body` tut, ya da gövdeye bir ad ver.
- **T3. Veri yapısı yorumları eskimiş** (`main.gd:114-115`)
  - **Sorun:** `items` için yorum `{node, kind, h, phase}` diyor. Kodda `home` ve `lane` alanları da var. `throws` için yorum `{node, marker, from, to, t}` diyor; kodda `item`, `lane` ve `spd` de var.
  - **Sonuç:** Okuyan eksik bilgiyle yola çıkıyor.
  - **Düzeltme:** İki yorumu güncelle.
- **T4. İsim iki kez temizleniyor** (`secim.gd:161`)
  - **Sorun:** `typed` zaten temizlenmiş, ama `clean_name(typed, ...)` ikinci kez çağrılıyor. Amaç yalnızca boş isme varsayılan adı vermek.
  - **Düzeltme:** `typed if typed != "" else M.RABBIT_SKINS[skin].ad`.
- **T5. Ayar dosyası açılışta üç kez okunuyor** (`main.gd:303`, `secim.gd:77`, `secim.gd:104`)
  - **Sorun:** Menü açılırken aynı ayar dosyası `load_choice` ×2 ve `load_scores` ile toplam 3 kez okunuyor.
  - **Sonuç:** İki incelemedir bekliyor. Önemi düşük.
- **T6. Kopya sabit ve yanlış yerdeki menü teması** (`secim.gd:12`, `main.gd:393`)
  - `TITLE_EDGE` değeri `HUD_TEXT` ile aynı.
  - Menünün teması (`ui_theme`) `main.gd`'de, menünün kendisi ise `secim.gd`'de duruyor.
- **T7. `_ready` çok uzun** (`main.gd:254-390`): 136 satır, doğrusal okunuyor. Bölünecekse `make_hud()` yeterli.
- **T8. `kalite/kapi.sh:4`'teki yorum yanlış**
  - **Sorun:** Yorum "Gerçek ayar.cfg yedeklenir" diyor, ama betik `test_ayar.cfg` dosyasını yedekliyor. Yedeğin adı da (`ayar.cfg.yedek`) bu yüzden yanıltıcı.
  - **Not:** Kalite aracında, oyun kodunda değil.
- **Puan düşülmeyen:** `modeller.gd` içindeki `TARGET`, `SACK` ve `ZONE_DECO` sonraki tura hazırlanan veri.

---

## Optimizasyon (9/10)

**Ölçülenler:**
- **20 sahne yenilemesi** (Enter ve Esc karışık):
  - Nesne sayısı 1878–1956, düğüm sayısı 281–358.
  - Yetim düğüm hep 0, kaynak sayısı hep 5.
  - Büyüme yok, sızıntı yok.
- **Listeler sınırlı:** `items` ve `throws` listeleri `CULL_BEHIND` ve iniş anıyla sınırlı.
- **Önbellekler sınırlı:** Malzeme, mesh ve parçacık malzemesi önbellekleri renk ve şekil sayısıyla sınırlı.
- **Pencereli kare süresi:** Ortanca ~2 ms.

### 9 için şart
Yok.

### İyi olur

- **O1.** `gap_fill.bg_color` (`main.gd:810`) her karede yazılıyor. `StyleBoxFlat` eşit değerde bile `changed` sinyali gönderiyor, bu yüzden çubuk her karede yeniden çiziliyor. Çözüm: değer değiştiyse yaz.
- **O2.** `burst()` (`main.gd:519-524`) her inişte (saniyede ~1 kez), her havuçta ve her vuruluşta yeni bir `GPUParticles3D` düğümü açıp kapatıyor. Bu ölçekte ölçülebilir bir maliyeti yok.
- **O3.** Her karede küçük geçici diziler oluşuyor: `crossed(EVENTS.keys(), …)` + `filter` (`709`), `[rabbit, halil]` (`715`), HUD metni biçimlemesi (`806`). Ölçülebilir değil.

---

## Reddedilen ya da puan düşülmeyen iddialar

- **"Tırmık hiç isabet etmiyor":** Bu, `RAKE_AHEAD` değerinden kaynaklanıyor, yani tasarım ve oynanış değeri. Satır 787'deki yorum doğru. Puan düşülmedi.
- **"Hedef işareti `M.TARGET` modelini kullanmıyor":** Bu, D turunda bağlanacak hazır veri. Kural gereği puan düşülmedi.
- **"Yumurta kayması varilli şeride itiyor":** Bu, PLAN-mekanikler'de yazan davranışın kendisi.

## Denetlenemeyenler

- **Gerçek donanımda düşük FPS:** D1, `--fixed-fps` ile sabit karede ölçüldü. Kare süresinin değiştiği gerçek bir 30–40 FPS makinesinde ölçülmedi. Atılımla 43 FPS sınırı hesaba dayanıyor, yoklamada atılım zorlanamadı.
- **Gerçek gamepad:** Girdiler `Input.parse_input_event` ile üretilen sentetik olaylardı.
- **Gerçek oyuncunun tuş zamanlaması:** Tüm tuşlar sentetik olaylarla verildi.
- **Pencere boyutu değişirken HUD ve `pop()` yerleşimi.**
- **D3:** Oyunda üretilmedi, kod okunarak doğrulandı.
- **50'lik kalite kapısı:** Başka oturumda `test_ayar.cfg` üzerinde koşuyor, bu inceleme ona dokunmadı.
