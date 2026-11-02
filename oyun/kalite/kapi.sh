#!/usr/bin/env bash
# Kalite kapısı (PLAN-bolum1.md §6): ardışık 50 temiz deneme.
# Deneme = test.gd ok + senaryolu 690 karelik (ilk 10 kare atılır, 680 ölçülür) oyun çalıştırması, çıktıda hata/uyarı yok.
# Herhangi bir hata ardışık sayacı sıfırlar. Senaryoların kullandığı test_ayar.cfg yedeklenir ve sonunda geri yüklenir (kullanıcının ayar.cfg dosyasına hiç dokunulmaz).
# Kullanım: kapi.sh [hedef=50] [en_fazla_deneme=120]
set -u
HEDEF=${1:-50}
MAKS=${2:-120}
OYUN="/home/halil/projeler/tavşan ounu/oyun"
BURASI="$(cd "$(dirname "$0")" && pwd)"
LOG="$BURASI/log/kapi-$(date +%Y%m%d-%H%M%S).log"
mkdir -p "$BURASI/log"

ad=$(sed -n 's/^config\/name="\(.*\)"/\1/p' "$OYUN/project.godot")
USERDIR="$HOME/.local/share/godot/app_userdata/${ad:-[unnamed project]}"
CFG="$USERDIR/test_ayar.cfg"  # senaryo.gd secim.gd'nin ayar_path'ini buna çevirir; kullanıcının ayar.cfg'si hiç değişmez
mkdir -p "$USERDIR"
YEDEK="$BURASI/ayar.cfg.yedek"
if [ -f "$CFG" ]; then cp "$CFG" "$YEDEK"; else rm -f "$YEDEK"; fi
geri_yukle() { if [ -f "$YEDEK" ]; then cp "$YEDEK" "$CFG"; else rm -f "$CFG"; fi; }
trap geri_yukle EXIT

# Varsayılan: ekransız (--headless), kullanıcının ekranında pencere açılmaz. Gölgelendirici/parçacık görüntü hatalarını da görmek için
# pencereli koşu gerekir: GODOT_EKRAN="" ./kapi.sh (nadiren, son kontrolde).
GODOT_EKRAN=${GODOT_EKRAN---headless}
# Kullanıcının ekranında pencere açılmasın: pencereli koşu yalnızca kullanıcı açıkça isterse (KULLANICI_ONAYI=1).
if [ -z "$GODOT_EKRAN" ] && [ "${KULLANICI_ONAYI:-0}" != "1" ]; then GODOT_EKRAN=--headless; fi
SENARYOLAR=(kazan_sofra dokunma bolgeler menu_enter tekrar_enter esc_menu kazan yakalan isim_bos isim_uzun isim_turkce bozuk_cfg skor_bos skor_dolu fare_bos ses duraklat ayar_paneli animasyon carpma_ses)


seri=0; toplam=0; hata=0
echo "Kalite kapısı başladı $(date)  hedef=$HEDEF  log=$LOG" | tee "$LOG"
while [ "$seri" -lt "$HEDEF" ] && [ "$toplam" -lt "$MAKS" ]; do
	s=${SENARYOLAR[$((toplam % ${#SENARYOLAR[@]}))]}
	toplam=$((toplam + 1))
	bas=$(date +%H:%M:%S)  # çakışma olursa sonradan kanıtlanabilsin
	t_out=$(cd "$OYUN" && timeout 20 godot --headless --path . -s test.gd 2>&1); t_kod=$?
	# Varsayılan ekransız; GODOT_EKRAN="" ile pencereli (shader/parçacık hataları da yakalanır). Senaryo kendini 690 karede bitirir (ilk 10 kare ölçülmez).
	o_out=$(cd "$OYUN" && timeout 120 godot $GODOT_EKRAN --path . --fixed-fps 60 --disable-vsync -s res://kalite/senaryo.gd -- --senaryo="$s" 2>&1); o_kod=$?
	sorun=""
	[ $t_kod -ne 0 ] && sorun="test.gd çıkış kodu $t_kod"
	echo "$t_out" | grep -q "^ok$" || sorun="${sorun:+$sorun; }test.gd ok yazmadı"
	[ $o_kod -ne 0 ] && sorun="${sorun:+$sorun; }oyun çıkış kodu $o_kod"
	# İSTİSNA (raporda belirtilir): bozuk_cfg senaryosunda motorun kendi "ConfigFile parse error ... test_ayar.cfg"
	# satırı beklenen davranıştır (bozuk dosyayı Godot okurken basar; oyun varsayılana düşer). Yalnızca o satır süzülür.
	[ "$s" = bozuk_cfg ] && o_out=$(printf '%s\n' "$o_out" | grep -v "ConfigFile parse error at user://test_ayar.cfg")
	echo "$o_out" | grep -q "SENARYO OK" || sorun="${sorun:+$sorun; }SENARYO OK yazmadı"
	bul=$(printf '%s\n%s\n' "$t_out" "$o_out" | grep -E "ERROR|WARNING|Parse Error|SCRIPT ERROR|Invalid|SENARYO HATA" | head -5)
	[ -n "$bul" ] && sorun="${sorun:+$sorun; }çıktıda: $bul"
	if [ -z "$sorun" ]; then
		seri=$((seri + 1)); echo "[$toplam] $bas $s TEMİZ  (seri $seri/$HEDEF)  $(echo "$o_out" | grep -m1 "KARE ms")" | tee -a "$LOG"
	else
		seri=0; hata=$((hata + 1)); echo "[$toplam] $bas $s HATA → seri sıfırlandı: $sorun" | tee -a "$LOG"
		printf -- '--- test.gd ---\n%s\n--- oyun ---\n%s\n' "$t_out" "$o_out" >> "$LOG"
	fi
done
if [ "$seri" -ge "$HEDEF" ]; then sonuc="GEÇTİ"; else sonuc="GEÇEMEDİ"; fi
echo "SONUÇ: $sonuc  ardışık temiz=$seri  toplam deneme=$toplam  hatalı=$hata  $(date)" | tee -a "$LOG"
[ "$sonuc" = "GEÇTİ" ]
