# Kod incelemesi 9: Tavşan Kaçışı (oyun/)

**Doğruluk 9/10 · Temizlik 8/10 · Optimizasyon 9/10**

## Nasıl doğrulandı
- `godot --headless --path . -s test.gd` -> `ok`, çıkış 0.
- Ölü kod taraması (kendi betiğim): `modeller.gd`, `main.gd`, `secim.gd` içindeki her `const/var/func` adı, 5 .gd dosyasında (yorumlar süzülerek) sayıldı. Yalnız motor geri çağrıları (`_unhandled_input`, `_input`) tek geçiyor. Hiçbir sabit/model kullanılmaz değil. `CROPS/DOGHOUSE/HAYBALE/BASKET/ROCK/MUSHROOM/CAP_RED/ROCK_C/HAY/HAY_BAND` artık `ZONE_DECO` üzerinden erişiliyor. `SACK/BURLAP/ROPE/TARGET/TARGET_RING/DECO` kodda ve `.gd/.sh` dosyalarında kalmadı.
- Pencereli film: `/tmp/claude-1000/inc9/probe.gd` (ayar yolu `user://inc9_ayar.cfg`, işim bitince silindi; `ayar.cfg`/`test_ayar.cfg`'ye dokunulmadı). Tavşan 100/250/400/560 m'ye ışınlandı, 250 kare, her koşuda hata/uyarı/script hatası yok. Kareler `/tmp/claude-1000/inc9/s100.png` (tarla), `s250.png` (köpek), `s400.png` (kümes), `s560.png` (son), yakın kesitler `c100b.png`, `c400b.png`. Kapıyı koşmadım (test_ayar.cfg'ye yazar).

## Bölge dekoru
- Tarla: yol kenarında toprak tümsek + havuç sapı görünüyor (`c100b.png`), çiçek ve ağaç da çıkıyor. Köpek: kulübeler net (3 adet, kırmızı çatı, `s250.png`). Kümes: saman balyası ve çalı/çiçek (`c400b.png`). Son: kaya (gri-pembe) + ağaç + çalı (`s560.png`). Mantar ve sepet küçük, her karede seçilmedi; `ZONE_DECO` anahtarları (`tarla/kopek/kumes/son`) `main.gd:22` `ZONES` adlarıyla birebir, yani tüm bölgeler tanımlı.
- x aralığı: `main.gd:580` ağaç 5,5-9,0, diğerleri 4,2-7,0; yol yarı genişliği 3,2 (`modeller.gd:156`, 6,4 m). Rastgele yaw ile en kötü yarıçaplar: CROPS 0,69, HAYBALE 0,64, kulübe gövdesi 0,74, çatı 0,8, mama kabı köşesi 1,16. 4,2'de mama kabı en fazla 0,16 m yol kenarına taşar (3,04 < 3,2), şeritlere (±2) uzak ve nadir; yolu kapatan dekor yok. Probe'da en küçük dekor x'i 4,2 (kaz 3,6 zaten ayrı sabit).

## inceleme-8 ve öncekilerin düzeltmeleri
Hâlâ yerinde: bina x 11-14 (`main.gd:586`) tepeler ±23..30; `GDD.md:95` "Yapıldı ... Bekleyen: G6"; `kapi.sh:3` "690 karelik (ilk 10 atılır)"; `kapi.sh` test_ayar yedekleme/geri yükleme; hata yok.

## Doğruluk (9/10)
Test ok, dört bölge hatasız koştu, dekor doğru modeli doğru bölgede basıyor. Elle oynanmadı, gamepad/zayıf GPU denetlenmedi. Küçük risk: `ZONES`'a yeni bölge adı eklenip `ZONE_DECO`'ya eklenmezse `ZONE_DECO[zone(-z)]` KeyError verir; `test.gd` bunu denetlemiyor (aşağıda öneri, puan düşürmedim).

## Temizlik (8/10)
Koddaki ölü veri bitti; kod olarak temiz. Puanı düşüren, silinen/bağlanan modellere dair YANLIŞ BELGE:
1. **`RAPOR-bolum1.md:75-77`**: "Kazanma ve yakalanma mini sahneleri (yuvaya dalış, çuval). / Her bölgeye kendi dekoru. / Modelleri hazır, kod bağlantısı bu turda yapılacak." Dekor artık bağlı (yapıldı), çuval modeli (`SACK`) silindi, yani "modelleri hazır" yanlış. Düzeltme: "Her bölgeye kendi dekoru" satırını yapıldıya taşı/sil; "Modelleri hazır..." cümlesini "Çuvalın modeli yok; mini sahneler sonraki tur" yap.
2. **`HANDOFF-tasarimci.md:48`**: "TREE/BUSH/FLOWERS/DECO ... DEGERLENDIRME.md D için veriler hazır: SACK, ZONE_DECO ..., TARGET ... bağlamayı Geliştirici yapacak". `DECO`, `SACK`, `TARGET` artık yok, `ZONE_DECO` bağlı. HANDOFF'lar güncel durum belgesi, tarihli kayıt değil; kısa "bağlandı/silindi" notu ekle.
3. **`GDD.md:101`** "Bölgeler: tarla → kümes → ahır → dere → yuva" kodla (tarla, köpek, kümes, son) uyuşmuyor, ayrıca `GDD.md:72` Dünya paragrafı bölge dekorunu anmıyor. Not: 101 "sonraki tur" planı olduğu için ağır saymadım; yine de sırayı (köpek önce) ve "ahır/dere" (kodda yok) açıklamalı.
(`DEGERLENDIRME.md:75,128` ve `PLAN-*.md` içindeki `DECO` anımları tarihli gövde, bilerek önemsiz.)

## Optimizasyon (9/10)
`ZONE_DECO[...].pick_random()` satır başına iki arama, ek ayrılan bellek yok; tüm dekor `items` yaşam döngüsünde (pop, yok etme) eskisiyle aynı yoldan. Dört bölge 250 kare hatasız, takılma görülmedi; önceki ölçümler (CPU ~0,6-1,6 ms) değişmeyen yoldan tutarlı. Ölçülebilir sorun yok.

## Temizliği 9'a çıkaracak
1. `RAPOR-bolum1.md:75-77` düzelt (yukarıda madde 1).
2. `HANDOFF-tasarimci.md:48` DECO/SACK/TARGET atfını güncelle.
3. İsteğe bağlı: `test.gd`'ye bir satır: `for z in Main.ZONES: assert(Mod.ZONE_DECO.has(z[1]))`.
