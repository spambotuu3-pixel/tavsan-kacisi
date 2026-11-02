# Kod incelemesi 3: Tavşan Kaçışı (oyun/)

**Doğruluk 9/10 · Temizlik 8/10 · Optimizasyon 9/10**

İncelenen dosyalar: `main.gd` (827 satır), `secim.gd` (160), `modeller.gd` (393), `test.gd`, `kalite/senaryo.gd`, `toon.gdshader`. Git olmadığı için dosyalar şu anki hâlleriyle incelendi. inceleme-1 ve inceleme-2'ye güvenilmedi; maddeleri koda bakılarak ve çalıştırılarak yeniden denetlendi. `code-review` ve `ponytail-review` yöntemleri uygulandı. Bu iki aracın ürettiği iddiaların her biri ayrıca doğrulandı; doğru çıkmayanlar en altta "Reddedilen iddialar" başlığında.

**Nasıl doğrulandı:**
- `test.gd`: `ok`, 23 durum, çıkış kodu 0.
- 14 senaryonun hepsi `SENARYO OK` verdi. Senaryolar, `senaryo.gd`'nin `user://inceleme3_ayar.cfg` kullanan bir kopyasıyla scratchpad'den, headless ve `--fixed-fps 60` ile koşturuldu. Tek uyarı kaynağı `bozuk_cfg` senaryosundaki 4 satırlık motor `ConfigFile parse error` çıktısı; bu beklenen bir durum. `bolgeler`, `tekrar_enter` ve `kazan` ayrıca pencereli (RTX 4050) koşturuldu. Kare süresi ortanca 1,6–2,0 ms, %99'luk dilim 5 ms'nin altında. Hata veya uyarı çıkmadı. En kötü kare 46 ms, o da sahne yenilendiği kare.
- Yoklama script'leri (scratchpad: `probe3.gd`, `pivot.gd`, `cfg.gd`):
  - **bitiş:** Atılım sürerken, köpek gelirken, havada bir atış varken, tavşan zıplarken ve kova karartması açıkken yakalanma. Ardından kilit süresinde Enter, kilit bitince yine Enter.
  - **yenile:** Enter ve Esc karışık 17 sahne yenilemesi.
  - **uzun:** Yakalanmadan 600 m koşu (2711 kare).
  - **cfg:** Yanlış tipli ve bozuk `ayar.cfg` değerleri, eşit puanla 300 deneme.
- Geçici `inceleme3_ayar.cfg` silindi. `ayar.cfg` ve `test_ayar.cfg` dosyalarına dokunulmadı.

**Genel durum:** Çökme, yanlış durum geçişi ya da sızıntı bulunmadı. inceleme-2'nin "9 için şart" maddelerinin hepsi gerçekten düzeltilmiş (aşağıdaki tablo). Kalan bulguların çoğu temizlik tarafında: elle yazılmış kopya veriler ve birkaç adsız sayı.

---

## Doğruluk (9/10)

**Ölçülenler:**
- **Menü:** `state=menu`, toz kapalı.
- **Açılış:** HUD dolu (`'Pamuk 0 / 600 m Havuç: 0'`), Halil çubuğu %100, "ATIL" ipucu gizli, atılım havuçları soluk (a=0,25), toz kapalı.
- **Açılışı atlama:** Space ile atlanınca "KAÇ!" görünüyor, tavşan zıplamıyor (`vy=-0,33`, yerde).
- **Yakalanma anı:** Atılım (1,68 sn kalmıştı), köpek, havada bir atış ve zıplama aynı anda sürüyordu. Bitişte `state=over`, toz kapalı, karartma gizli, panel açık.
- **Bitiş kilidi:** Bitişten 1 kare sonra basılan Enter yok sayıldı. Kilit bitince basılan Enter sahneyi yeniledi (`state=intro`, `go_menu=false`, isim korundu).
- **Bozuk ayar dosyası:**
  - `skin=99` sınıra çekildi (2'ye), `skin=-3` 0'a.
  - `skin=1.0` (tipi yanlış) ve `isim=5` varsayılana düştü.
  - `liste="x"` boş liste oldu.
  - Bozuk kayıtlar elendi, 22 karakterlik isim 12'ye kısaldı.
- **Eşit puan:** 300 denemenin 300'ünde eski sıra korundu, yeni kayıt kesildi ve `◀` hiçbir kayda konmadı. Doğru davranış.

### 9 için şart
Yok.

### İyi olur (10 için)

**D1. Bitiş ekranında kova tavşanın kafasında kalıyor** (`main.gd:819`)
- **Sorun:** `finish()` yalnızca `blind_rect` karartmasını gizliyor, `bucket.visible` değerine dokunmuyor. Yoklamada `blind_rect=false bucket=true` görüldü.
- **Ne zaman olur:** Kova kafadayken yakalanınca, bitiş paneli boyunca tavşan kovayla kalıyor. Komik bile sayılabilir, ama ekran ile model birbirini tutmuyor.
- **Düzeltme:** `blind_rect.visible = false` yerine `blind_t = 0.0` yaz ve iki görünürlük satırını kapat. Ya da `bucket.visible = false` satırını ekle (1 satır).

**D2. Tırmık neredeyse hiç isabet etmiyor, kıl payı da saymıyor** (`main.gd:758`, `772-778`)
- **Sorun:** PLAN-mekanikler M4'e göre tırmık, tavşanın 1 saniye sonraki yerinin 1,6 katı ileriye düşer. Tavşan o noktaya ancak atıştan hemen sonra atılım başlatırsa ve düşük hızdayken varabilir (10 m/s + 6 = 16 m = 1,6 × 10). Ölçülen: 600 m'lik koşuda tavşanın tırmık hedefine 1 m'den yakın olduğu iniş sayısı 0.
- **Sonuç:** 772–776'daki isabet dalı tırmık için pratikte hiç çalışmıyor. 777'deki yorum ise isabetin olağan bir durum olduğunu ima ediyor. Ayrıca M3'e göre "vurulmadıysa" her atış kıl payı sayılabilir, tırmık ise `elif` dalında bundan dışlanıyor.
- **Değerlendirme:** Tasarım gereği olabilir. Hata sayılmadı, puan düşülmedi.
- **Düzeltme:** Yorumu "tırmık yalnızca atılımla isabet eder" diye düzelt. Kıl payının tırmıkta sayılıp sayılmayacağını Tasarımcı'ya sor.

**D3. Gamepad yarım destekleniyor** (`main.gd:446`, `449`)
- **Sorun:** Koşu `ui_*` eylemleriyle oynandığı için gamepad ile de çalışıyor. Ama açılışı atlama yalnızca `InputEventKey/MouseButton`, bitiş ekranı ise yalnızca klavye tuş kodlarıyla çalışıyor.
- **Sonuç:** Gamepad ile oynayan oyuncu bitiş ekranında kalıyor. GDD gamepad vaat etmediği için puan düşülmedi.
- **Düzeltme:** `e.is_action_pressed("ui_accept")` ve `e.is_action_pressed("ui_cancel")` kullanmak, tuş listesinin yerini de alır.

**D4. `load_scores` listeyi sıralamıyor** (`secim.gd:64`)
- **Sorun:** Elle düzenlenmiş, sırasız bir liste menüde sırasız görünüyor. Liste ancak bir sonraki kayıtta sıralanıyor.
- **Not:** İsimdeki `\n` karakteri de temizlenmiyor; yoklamada `"c\nd"` olduğu gibi geçti ve tabloda satırı bölüyor. Dosya yalnızca kullanıcının kendi diskinde, bu yüzden önemi düşük.

---

## Temizlik (8/10)

inceleme-2'deki T2 (`soft_mat`) ve T3 (silme koşulu) düzeltilmiş. T1 (adsız sayılar) büyük ölçüde düzeltilmiş: `THROW_EVERY`, `THROW_RAMP`, `THROW_ARC`, `RAKE_AHEAD`, `BOUNCE_AHEAD`, `DOG_H` artık sabit. `_process` okunaklı, durumlar net. Puanı tutan şey, iki incelemedir işaretlenen kopya verilerin hâlâ durması.

### 9 için şart

**T1. Tasarımcı verisi elle kopyalanmış ve paletten ayrılmış** (`main.gd:10-11`, `main.gd:761`)
- **Sorun:**
  - `THROWN` içinde yumurta `Color(1, 0.97, 0.9)` ve lahana `Color(0.45, 0.75, 0.35)` elle yazılmış. Palette yumurta `M.EGG_WHITE` (0.97, 0.96, 0.9), lahana `M.CABBAGE_LIGHT` (0.55, 0.8, 0.4).
  - Hedef işareti `Color(0.95, 0.3, 0.3, 0.55)` olarak elle yazılmış, oysa aynı değer `M.TARGET_C` (`modeller.gd:253`) olarak duruyor.
- **Sonuç:** Havada açık yeşil olan lahana yere düşünce başka bir yeşile dönüyor. Tasarımcı hedef rengini değiştirirse oyunda bir şey değişmiyor. Gereksiz iki malzeme daha üretiliyor. Bu madde inceleme-2'de T4 idi ve değişmedi.
- **Düzeltme (3 değer):** Yumurta için `M.EGG_WHITE`, lahana için `M.CABBAGE_LIGHT`, hedef için `M.TARGET_C` kullan. Tasarımcının hazırladığı `M.TARGET` modeli (disk + halka + nokta) bağlanacaksa satır `model(M.TARGET, to + Vector3(0, 0.03, 0))` olur. HANDOFF-tasarimci'ye göre bu D turunda yapılacak.

**T2. `THROWN` girdisinin ad ve etki alanları kopya, `fx` adı iki anlamda kullanılıyor** (`main.gd:10-11`, `117`, `762`)
- **Sorun:** 5 alanlı konum dizisinde `[0]` ve `[4]` alanları dört eşyanın üçünde aynı ("kova"/"kova" gibi). Ayrı `[4]` alanı yalnızca "tırmık"/"tirmik" ASCII farkı için var. GDScript Türkçe karakterli dizeleri sorunsuz karşılaştırdığı için bu alana gerek yok.
- **Ayrıca:** `fx` hem parçacık malzemesi önbelleğinin adı (`var fx := {}`, satır 117), hem atış sözlüğündeki etki kimliği (`th.fx`). Okuyan `th.fx == "kova"` satırında önbelleği düşünüyor.
- **Sonuç:** Bir eşyanın adı değişip etki alanı unutulursa `run_throws`'taki `th.fx == ...` karşılaştırmaları sessizce eşleşmez. Eşya yine fırlatılır ama etkisi kaybolur.
- **Düzeltme:** `[4]` alanını sil, `what[0] == "tırmık"` ile karşılaştır, `th.fx` yerine `th.kind = what[0]` yaz. Önbelleğin adını `fx_mats` yap. Sonuçta yaklaşık 4 alan silinir, 1 ad değişir.

### İyi olur

- **T3. İsabet yüksekliği adsız, ikinci `0.5` yanıltıcı** (`main.gd:772`, `780`): Atışın isabet yüksekliği `0.5` olarak elle yazılmış. inceleme-2 T1'in kalan son parçası bu. 780'deki `hits(Vector3(r.x, 0, r.z), ..., 0.5)` çağrısında da `0.5` geçiyor, ama orada y=0 verildiği için bu sayı hiçbir şeyi değiştirmiyor. Çağrının asıl işi "tavşan hedefin tam üstünde mi" diye bakmak. Okuyan iki `0.5`'in birbirine bağlı olduğunu sanıyor. Düzeltme: `const THROW_H := 0.5` ekle ve 772'de kullan. 780'de tavşanın tam üstte olup olmadığını açıkça yazan bir ifade kullan, ya da yükseklik olarak `THROW_H` ver.
- **T4.** Şerit sınırı `o >= 0 and o <= 2` `main.gd:565` ve `733`'te tekrar ediyor, `2` sayısı `652`'de de var. Bu inceleme-2'de T5 idi ve değişmedi. `clampi`/`LANES.size() - 1` ile bir yardımcı fonksiyona alınabilir.
- **T5.** `_ready` (`main.gd:247-382`, 135 satır) gökyüzünü, ışığı, kamerayı, HUD'ı, bitiş panelini, kova karartmasını, pop yazısını ve menüyü tek fonksiyonda kuruyor. Doğrusal olduğu için okunuyor. Ama HUD'a dokunmak isteyen 135 satırı taramak zorunda. Bölünecekse `make_hud()` yeterli.
- **T6.** Tavşanın gövdesine `rabbit.get_child(0)` ile indeksle erişiliyor (`main.gd:414`, `640`, `643`, `706`). `model()` yapısı değişirse bu satırlar sessizce yanlış düğümü oynatır.
- **T7.** inceleme-2'nin T7 ve T8 maddeleri değişmedi:
  - `secim.gd:75` `load_choice()` fonksiyonunu ikinci kez okuyor.
  - `TITLE_EDGE` sabiti `HUD_TEXT` ile aynı değer.
  - Menünün teması (`ui_theme`) `main.gd`'de, menünün kendisi `secim.gd`'de.
- **T8.** `INTRO_CUES.values()[-1]` (`main.gd:448`) "KAÇ!" yazısını sözlüğün ekleme sırasına bağlıyor. Bunun yerine `INTRO_CUES[3.3]` ya da adlı bir sabit kullanılabilir.
- **Puan düşülmeyen:** `modeller.gd` içindeki `TARGET`, `SACK`, `ZONE_DECO` (ve buna bağlı `CROPS`, `DOGHOUSE`, `HAYBALE`, `BASKET`, `ROCK`, `MUSHROOM`) bugün hiçbir yerde kullanılmıyor. HANDOFF-tasarimci'ye göre bunlar D turunda bağlanacak hazır veri, artık değil. D turu iptal olursa silinmeliler.

---

## Optimizasyon (9/10)

**Ölçülenler:**
- **17 yenileme:** Nesne sayısı 1916–2008, düğüm sayısı 305–394. Yetim düğüm hep 0, kaynak sayısı hep 5. Büyüme yok, sızıntı yok.
- **600 m tam koşu:** En çok 503 düğüm, `items` en çok 37, `throws` en çok 2, `main` altında en çok 56 çocuk düğüm. Listeler `CULL_BEHIND` ile sınırlı. Malzeme, mesh ve parçacık malzemesi önbellekleri renk ve şekil sayısıyla sınırlı.
- **Pencereli kare süresi:** Ortanca ~2 ms.

### 9 için şart
Yok.

### İyi olur

- **O1.** `burst()` (`main.gd:509-514`): Her inişte (saniyede ~1 kez), havuçta ve vuruluşta yeni bir `GPUParticles3D` düğümü açılıp kapatılıyor. Bu ölçekte ölçülebilir bir maliyeti yok. Ölçek büyürse türe göre tek bir emitter tut ve `restart()` ile yeniden kullan.
- **O2.** `gap_fill.bg_color` (`main.gd:800`) her karede yazılıyor. `StyleBoxFlat` eşit değerde bile `changed` sinyali gönderiyor, bu yüzden çubuk her karede yeniden çiziliyor. Çözüm: değer değiştiyse yaz.
- **O3.** Her karede küçük geçici diziler oluşuyor: `EVENTS.keys()` + `filter` lambdası (`699`), `[rabbit, halil]` (`705`), HUD metni biçimlemesi (`796`). Ölçülebilir değil.

---

## inceleme-2 "9 için şart" maddelerinin durumu

| inceleme-2 | Durum | Kanıt |
|---|---|---|
| D1 Enter zıplatıp bitişi geçiyor | **Düzeltildi** | `END_LOCK` (`main.gd:28`, `817-818`). Kilitteki Enter yok sayıldı, kilit bitince Enter yeniledi. |
| D2 Açılışta bayat HUD | **Düzeltildi** | `on_start` → `update_hud(0.0)`. Açılışta HUD dolu, çubuk %100, ipucu gizli. |
| D3 Menüde ve açılışta toz | **Düzeltildi** | `particles()` içinde `emitting = false`. Menüde ve açılışta `dust=false`. |
| T1 Adsız ayar sayıları | **Büyük ölçüde** | 6 sabit eklendi. İsabet yüksekliği `0.5` kaldı (bu incelemede T3, iyi olur). |
| T2 `soft_mat` ölü dal | **Düzeltildi** | Tek `if`/`else` (`main.gd:203-221`). |
| T3 Silme koşulu 3 kez | **Düzeltildi** | `var passed` tek kez (`main.gd:736`). |
| İyi olur: D4 "KAÇ!" | Düzeltildi | Atlanınca "KAÇ!" görünüyor. |
| İyi olur: D5 gerçek saat | Düzeltildi | `var t := clock`. |
| İyi olur: D7 tablo temizliği | Kısmen | `clean_name` ve `slice` var, sıralama yok (D4). |
| İyi olur: T4–T8 | Değişmedi | T4 → bu incelemede T1, T5 → T4, T7/T8 → T7. |

## Reddedilen iddialar (araçlardan gelen, doğrulanınca tutmayan)

- **"Kaz orta şeritte hep ötüyor, `absi(...) <= 1` hatalı" (`main.gd:727`):** PLAN-bolum1.md:27'de "kazın 1 şerit yakınından geçerse" yazıyor. Kod spesifikasyona uyuyor.
- **"`pop()` pivotu eski boyuttan hesaplıyor":** Pencereli ölçümde etiket tam genişlikte (1280×77) ve pivot (640, 38,5). Her tek satırlık yazı için doğru. Headless'te görülen fark 64×64'lük sahte pencereden kaynaklanıyor.
- **"Eşit puanlarda sıralama kararsız":** 300 denemenin 300'ünde kararlı. Liste en fazla 6 eleman, Godot bu boyutta ekleme sıralaması kullanıyor.
- **"Köpek `items`/`hits()` düzenini kullanmıyor":** Köpeğin uyarı şeridi ve tek geçişlik çarpışması ayrı bir davranış. Çarpışmanın kendisi yine `hits()` ile yapılıyor (`main.gd:599`). Puan düşülmedi.

## Denetlenemeyenler

- Gerçek bir oyuncunun tuş zamanlaması. Tüm girdiler `Input.parse_input_event` ile üretilen sentetik olaylardı. Özellikle Enter'ın LineEdit'ten açılışa sızmaması sentetik olayla ve kod okunarak doğrulandı.
- Pencere boyutu oyun sırasında değişirken `pop()` pivotu ve HUD yerleşimi.
- Gamepad ile tam bir oturum.
- İlk `burst()` anında shader derlemesinden doğan takılma. Makinede shader önbelleği zaten dolu olduğu için ölçülemedi.
- Düşük donanımda (SSAO + MSAA 4x + DOF + gölge) kare süresi. Yalnızca RTX 4050'de ölçüldü.
- 50'lik kalite kapısı döngüsü. O, başka bir oturumda `test_ayar.cfg` üzerinde koşuyor ve bu inceleme ona dokunmadı.
