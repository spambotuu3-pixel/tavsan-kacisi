# Kod incelemesi 8: Tavşan Kaçışı (oyun/)

**Doğruluk 9/10 · Temizlik 8/10 · Optimizasyon 9/10**

## Nasıl doğrulandı
- `godot --headless --path . -s test.gd` -> `ok`, çıkış 0.
- Pencereli film: `/tmp/claude-1000/inc8/probe.gd` (ayar yolu `user://inc8_ayar.cfg`, işim bitince silindi; `ayar.cfg`/`test_ayar.cfg`'ye dokunulmadı), 300 kare, `--write-movie`. Kareler `/tmp/claude-1000/inc8/g00000120.png`, `g00000160.png`, `g00000200.png`, `g00000250.png`. Kapı koşturmadım. Gamepad/gerçek düşük FPS donanımı denetlenemedi.

## inceleme-7 bulguları
| Madde | Durum | Kanıt |
|---|---|---|
| D1 bina tepeye gömülmesi | Düzeltildi | Bina x aralığı `main.gd:586` 11-14; tepeler `modeller.gd:157-162` x ±23..±30. Probe: bina x=±12-12,8 (`bina x=-12.8`, `12.4`). Karelerde evler zeminde temiz oturuyor, kesik/içbükey gömülme yok (4 kare). |
| T1 DEGERLENDIRME.md | Kabul (anlık görüntü notu) | Başta `:3` "ANLIK GÖRÜNTÜ (10:30)" notu var; gövdedeki eski satır numaraları (`:16-22`) ve "RAPOR yok / GDD eski" iddiaları duruyor ama not bunları tarihli kayıt olarak işaretliyor. Yanlış belge sayılmaz. |
| T2 GDD "Yapıldı" | Düzeldi | `GDD.md:95` artık "Yapıldı: ... Bekleyen: G6". |
| T3 kapi.sh yorumu | Düzeldi | `kapi.sh:3` "690 karelik (ilk 10 kare atılır, 680 ölçülür)". |

## Doğruluk (9/10)
Test ok, bina gömülmesi görsel kanıtla giderilmiş, bu turda işlev hatası bulmadım. Kapı koşmadığı için "50/50" bu turda yeniden üretilmedi (inceleme-7 logunu devralıyorum) ve oyun elle oynanmadı; 10 vermemem bundan.

## Temizlik (8/10)
**T1. Hiç kullanılmayan veri `modeller.gd` içinde (somut ölü kod).** Sembol aramasıyla yalnızca tanımda geçiyorlar:
- `SACK` `:337-341` (çuval modeli), `ZONE_DECO` `:388-393`, `TARGET` `:322-326`, ve yalnız bunlara hizmet eden `CROPS :346`, `DOGHOUSE :356`, `HAYBALE :364`, `BASKET :370`, `ROCK :377`, `MUSHROOM :381`, `TARGET_RING :254`, `ROCK_C :333`, `BURLAP/ROPE :329-330` (yaklaşık 50 satır). Kod `M.TARGET_C` ile kare kutu basıyor (`main.gd:800`), `M.TARGET` hiç çağrılmıyor; kenar dekoru bölgeden bağımsız `M.DECO` (`main.gd:579`). `DEGERLENDIRME.md:128` bunları "bağlanacak" diye anıyor, yani planlı-ama-bağlanmamış. Düzeltme: ya `spawn_row`'da `ZONE_DECO[zone(...)]`'u bağla ve `SACK`/`TARGET`'ı kullan, ya da bu blokları sil (belgeye "sonraki tur" notu düş).
**T2 (küçük).** `main.gd` `_input` yalnız bir kez geçiyor, bu motor geri çağrısı, sorun değil. `HANDOFF-gelistirici.md:46` "Dosya 253 satır" eski (şimdi 867), geçmiş notu.
Kod tekrarı, sızıntı, tutarsız sabit bulmadım.

## Optimizasyon (9/10)
- Probe: CPU 0,57 ms/kare (film modu; GPU 11 ms film kodlamasıyla şişik, kıyaslanamaz). Bina `z` göreli -80'den başlayıp ilerliyor, yaşam döngüsü sağlıklı. Önceki turun ölçümleri (50/50 kapı, ~1,6 ms) değişmeyen kodla tutarlı. Ölçülebilir sorun yok.

## Puanı 9'a çıkaracak (Temizlik)
1. `modeller.gd:254,322-326,329-330,333,337-341,346-393` bağlanmamış model/dekor verisini ya bağla ya sil (yukarıdaki liste); sonra `test.gd` ve bir senaryo koştur.
