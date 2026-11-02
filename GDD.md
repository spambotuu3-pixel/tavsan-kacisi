# Tavşan Kaçışı: Oyun Tasarım Belgesi (GDD)

> Sürüm: 2026-11-02 · Sahibi: Tasarımcı (tav-an-ounu-72) · Motor: Godot 4.7 (`oyun/`)
> Kaynaklar: `PLAN-gorunum.md` (görsel tarz), `PLAN-mekanikler.md` (mekanikler), `PLAN-grafik.md` (grafik iyileştirme). Sayılar `oyun/main.gd` başındaki sabitlerden alındı; değişirse bu belge de güncellenmeli.

## 1. Hikaye

Yabani bir tavşan, çiftçi Halil'in tarlasından havuç çalıyor. Halil onu fark edip peşine düşüyor ve eline geçen her şeyi fırlatıyor: kova, tırmık, yumurta, lahana. Tavşanın derdi tek: havuçlarla birlikte yuvasına sağ salim varmak. Yakalanırsa Halil onu çuvala koyuyor. Varırsa mutlu son: tavşan yuvaya girer, sıcak toprak odada çalınan havuçlar ve turp, mısır, domates, patlıcan, lahana yığınlarıyla şölen yapar (yuva finali, `PLAN-yuva-finali.md`).

Ton: komik, sevimli, cezalandırıcı değil. Halil kötü adam değil, öfkeli bir çiftçi.

## 2. Oynanış döngüsü

```
koş → engelden kaç / havuç topla → havuçla atıl → Halil'i geride bırak → yuvaya var
           ↑                                                      │
           └──────────── çarpma / isabet: Halil yaklaşır ──────────┘
```

- **Hedef:** 600 m ötedeki yuvaya ulaşmak (`GOAL = 600`).
- **Kaybetme:** Halil'le aradaki mesafe (`gap`) sıfıra inerse.
- **Skor:** mesafe (m) + toplanan havuç × 10 + yuvaya varırsan 200. En iyi 5 kayıt isimle saklanır. Havuç aynı zamanda atılım yakıtı (M2).
- **Süre:** Şu haliyle yaklaşık 42 saniye. Ayar turunda uzatılabilir.

## 3. Kontroller

| Tuş | Eylem |
|---|---|
| ← / → | Şerit değiştir (3 şerit: x = -2, 0, 2) |
| ↑, Space veya Enter | Zıpla (inişten 0,12 sn önce basılsa da sayılır: `JUMP_BUFFER`) |
| ↓ | Havuçla atıl (3 havuç harcar) |
| ↑ / ↓ (menüde) | Tavşan rengini seç; Enter başlatır |
| Herhangi bir tuş (açılışta) | Açılışı atlar |
| Enter (oyun bitince) | Tekrar oyna |
| Esc (oyun bitince) | Menüye dön |
| Gamepad A / B | Bitişte tekrar oyna / menü; menüde A başlatır |

## 4. Mekanikler ve değerler

| Mekanik | Değer | Not |
|---|---|---|
| Koşu hızı | 10 m/s'den başlar, +0,15 m/s², en fazla 20 | Pratikte ~16 m/s'ye çıkıyor |
| Zıplama | dikey hız 7, yerçekimi 20 | Havada ~0,7 sn, tepe ~1,2 m |
| Halil mesafesi (`gap`) | en fazla 10, saniyede +0,5 geri dolar | Ekranda Halil gerçekten yaklaşır |
| Çarpma / isabet | `gap -= 4` (`HIT_COST`) | Tavşan 0,3 sn yanıp söner |
| Halil'in atışı | 1,5–3,5 sn'de bir, yuvaya yaklaştıkça ×0,6'ya kadar sıklaşır (M5) | Hedef: tavşanın 1 sn sonraki yeri, kırmızı dairede gösterilir |
| Atılım (M2) | 3 havuç, 2 sn, hız +6, `gap` saniyede +2,5 | Engeller yine çarpar; bedava kurtuluş değil |
| Kıl payı (M3) | Hedef şeritten son 0,25 sn içinde çıkmak ya da üstünden atlamak | `gap += 1`, "Kıl payı!" yazısı |
| Adil dizilim (M1) | Her sırada en az bir boş şerit; yeni boş şerit eskisine en fazla 1 şerit uzak | Tavuk sadece iki şerit arasında gider |

## 5. Engeller ve eşyalar

| Nesne | Model | Yükseklik (`h`) | Cevabı |
|---|---|---|---|
| Çit | `M.FENCE` | 0,6 | Üstünden atla |
| Varil | `M.BARREL` | 1,6 | Şerit değiştir |
| Tavuk | `M.CHICKEN` | 0,5 | İki şerit arasında gider; zamanla ya da atla |
| Havuç | `M.CARROT` | 1,0 | Topla (skor + atılım yakıtı) |
| Kova (fırlatılan) | `M.BUCKET_HAT` | — | İsabet ederse 1,5 sn kafana geçer, ekranın üstü kararır |
| Tırmık (fırlatılan) | `M.RAKE_STUCK` | 0,6 | Daha ileri düşer ve yere saplanır; üstünden atla |
| Yumurta (fırlatılan) | `M.EGG_SPLAT` | 0,1 | Kaygan alan bırakır; basarsan yan şeride kayarsın |
| Lahana (fırlatılan) | `M.CABBAGE` | 0,5 | İndiği şeritte sana doğru yuvarlanır (6 m/s); atla ya da kaç |

## 6. Görsel tarz

**B · Yumuşak çizgi film (modern).** Ayrıntılar: `PLAN-gorunum.md`.

- **Şekiller:** Küre, kapsül, silindir, koni ve simitten kurulan oyuncak gibi modeller. Kafalar büyük (chibi oranı). Kamera arkada durduğu için kuyruk, kulak, şapka ve sırt ayrıntıları önemli.
- **Işık:** Alçak, sıcak gün batımı güneşi; mavi-turuncu gökyüzü; sis; ortam gölgesi; FILMIC ton eşleme.
- **Malzeme:** Mat (roughness 0,85), yumuşak gölge geçişi, ince kenar ışığı. Sıradaki adım iki bantlı toon shader (`PLAN-grafik.md` G3).
- **Palet:** Tavşan kürkü `#EFE1C4`, havuç `#FF8A1C`, Halil gömlek `#CF3B3B` / tulum `#3D5CAD`, hasır şapka `#ECD07A`, ahşap `#8A5A33`, çim `#6EA84D`, yol `#BD8C5E` (2026-11-02 gri tonlama testinden sonra koyulaştırıldı). Saf beyaz, saf kırmızı ve saf yeşil kullanılmaz.
- **Dünya:** Toprak yol, iki şerit çizgisi, kenarda ağaç, çalı ve çiçekler, yol kenarında uzakta çiftlik evleri, ahırlar ve silolar (`M.HOUSE`, `M.BARN`, `M.SILO`), sise karışan uzak tepeler, tepeye oyulmuş yuva ve önünde havuç yığını.
- **Arayüz:** Sol üstte yarı saydam krem renkli, yuvarlak köşeli panel: mesafe çubuğu (havuç turuncusu), Halil'e uzaklık çubuğu (yeşil → sarı → kırmızı), mesaj satırı. Oyun bitince ortada büyük panel. Menüde arkada büyük bir çiftlik görünür. Yazı tipi: Baloo 2 (OFL, `oyun/yazi/`), tüm arayüze `project.godot` üzerinden uygulanır.
- **Canlılık:** Zıplarken ezilip uzama, koşarken sallanma, nesnelerin büyüyerek belirmesi, havuç toplama efekti, vurulunca yanıp sönme.

## 7. Bilinen sorunlar ve çözümleri

Kaynak: `PLAN-mekanikler.md` bölüm 1 (2026-11-02 eleştirisi).

| Sorun | Çözüm |
|---|---|
| Kovalamaca pasif; `gap` bir can çubuğu gibi, Halil'den aktif olarak uzaklaşılamıyor | M2 atılım, M3 kıl payı |
| Havucun işlevi yok, sadece sayaç | M2: havuç atılım yakıtı |
| Fırlatmanın tek cevabı var (şerit değiştir), 4 eşya aynı | M4: her eşyanın kendi etkisi |
| Zorluk sadece hızla artıyor, atış aralığı sabit | M5 atış ritmi; asıl ayar oyun denendikten sonra |
| "En az bir şerit boş" garantisi zayıf, tavuk 3 şeritte geziyor | M1 adil dizilim, tavuk iki şeritte |
| İnişten hemen önce basılan zıplama yok sayılıyor | M1 zıplama tamponu |
| Halil çarpmada 2 m ışınlanıyor | M1 yumuşak yaklaşma |
| Tekrar oynamak için sebep yok | Yol haritası (bölüm 8) |

**Korunacak güçlü yanlar:** özgün ve komik tema, Halil'in mesafesinin ekranda görünmesi, bitiş çizgisi (sonsuz koşu değil), kolay okunan engeller.

## 8. Yol haritası

**Yapıldı:** `PLAN-mekanikler.md` M1–M5 ve T1–T3, `PLAN-grafik.md` G1–G5 ve G7, `PLAN-karakter-secimi.md`, `PLAN-bolum1.md`. Bekleyen: G6 (kontur, kullanıcı kararı).

**Yuva finali (planlandı, modeller hazır):** kazanınca yeni durum `"feast"`: tavşan yuvaya girer, dokunma/tuşla (yoksa otomatik) yığınları yer, en çok 10 sn, Esc/Geç ile atlanır; puan formülü değişmez, bolluk havuç sayısıyla artar (4-12 yığın). Modeller `modeller.gd` içinde: `VEG_TURNIP`, `VEG_CORN`, `VEG_TOMATO`, `VEG_EGGPLANT`, `VEG_CABBAGE`, `CARROT_PILE`, `BURROW_INSIDE` (sözleşme dosyanın başında). Sekans kodu Geliştiricide.

**Ardından:** Ayar turu (kullanıcı oynar; hız, zıplama, atış sıklığı, atılım ve kıl payı değerleri ayarlanır). Açılış sahnesi (tavşan havuç kemirir → "HEY!" → 3-2-1) yapıldı.

**Sonraki tur (henüz yapılmayacak):**
- **Tema mekanikleri:** Devrilen varil Halil'in önüne düşer; tavşan deliği kısayolu (birkaç saniye yer altı, Halil izi kaybeder); uzun ekin tarlası (Halil göremez ve atamaz, sen de önünü geç görürsün).
- **Bölgeler:** Şu an tarla → köpek → kümes → son düzlük → yuva (kodda `ZONES`). Sonraki tur: ahır ve dere eklenir (`ZONE_DECO` ve `ZONES` birlikte güncellenir).
- **Ek kovalayıcılar:** (Köpek Karabaş ve kaz alarmı bölüm 1'de yapıldı; yenileri sonraki tur.)
- **Ses:** Halil yaklaştıkça hızlanan ayak sesi ya da kalp atışı.
- **Tekrar oynama:** Günler/bölümler, havuç sayısına göre 1–3 yıldız.

## 9. Ekip ve dosyalar

| Rol | Oturum | Sorumluluk |
|---|---|---|
| Yönetici / plan yazarı | tav-an-ounu-7a | Planlar, iş dağıtımı |
| Geliştirici | tav-an-ounu-27 | `main.gd` kodu, mekanikler, testler |
| Tasarımcı | tav-an-ounu-72 | `modeller.gd`, görsel değerler, HUD görünümü, bu belge |

- `oyun/main.gd`: sahne, mekanik ve HUD kodu. Dokunmadan önce diğer ajana haber verilir.
- `oyun/modeller.gd`: model verisi (`[boyut, renk, konum, şekil?, dönüş?]`). Kod girmez.
- `oyun/test.gd`: çarpışma ve mekanik testleri (`timeout 20 godot --headless --path . -s test.gd`).
