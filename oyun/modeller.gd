extends RefCounted
# Tasarımcının dosyası: model verisi. Kod buraya girmez.
# Parça: [boyut, renk, köke göre konum, şekil?, dönüş(derece)?]. Şekil: b kutu, s küre, c kapsül, y silindir, k koni (uç +y), t simit.
# Kök = çarpışma noktası; kökü kaydırma, sadece parçaları oynat. İleri yön -z, kamera +z tarafında (arka taraf önemli).

# Palet (PLAN-gorunum.md). Const içinde Color("#hex") olmaz, r/g/b yazılır.
const FUR := Color(0.937, 0.882, 0.769)      # EFE1C4
const EAR_PINK := Color(0.957, 0.651, 0.69)  # F4A6B0
const TAIL := Color(1.0, 0.973, 0.933)       # FFF8EE
const CARROT_C := Color(1.0, 0.541, 0.11)    # FF8A1C
const LEAF := Color(0.31, 0.659, 0.227)      # 4FA83A
const SHIRT := Color(0.812, 0.231, 0.231)    # CF3B3B
const OVERALL := Color(0.239, 0.361, 0.678)  # 3D5CAD
const SKIN := Color(0.953, 0.776, 0.627)     # F3C6A0
const STRAW := Color(0.925, 0.816, 0.478)    # ECD07A
const WOOD := Color(0.541, 0.353, 0.2)       # 8A5A33
const WOOD_LIGHT := Color(0.69, 0.5, 0.32)
const METAL := Color(0.647, 0.659, 0.71)     # A5A8B5
const FENCE_PAINT := Color(0.96, 0.94, 0.88)  # çitin üst tahtası
const BOOT := Color(0.36, 0.24, 0.16)
const HAIR := Color(0.4, 0.26, 0.15)
const HAT_BAND := Color(0.62, 0.2, 0.15)
const HEN := Color(0.98, 0.95, 0.9)
const COMB := Color(0.88, 0.3, 0.3)
const BEAK := Color(1.0, 0.72, 0.25)
const EYE := Color(0.16, 0.1, 0.12)
const EYE_SHINE := Color(0.98, 0.98, 1.0)
const NOSE := Color(0.92, 0.48, 0.58)
const WHISKER := Color(0.35, 0.28, 0.28)

# Tavşan: kök yerden 0.3 yukarıda. Büyük kafa, tombul gövde, eğik kulaklar.
const RABBIT := [
	[Vector3(0.6, 0.5, 0.7), FUR, Vector3(0, -0.02, 0.05), "s"],                         # gövde
	[Vector3(0.5, 0.46, 0.46), FUR, Vector3(0, 0.3, -0.3), "s"],                         # kafa
	[Vector3(0.13, 0.55, 0.09), FUR, Vector3(-0.13, 0.72, -0.28), "c", Vector3(0, 0, 12)],   # kulaklar, dışa eğik
	[Vector3(0.13, 0.55, 0.09), FUR, Vector3(0.13, 0.72, -0.28), "c", Vector3(0, 0, -12)],
	[Vector3(0.07, 0.4, 0.03), EAR_PINK, Vector3(-0.13, 0.72, -0.33), "c", Vector3(0, 0, 12)],  # kulak içi
	[Vector3(0.07, 0.4, 0.03), EAR_PINK, Vector3(0.13, 0.72, -0.33), "c", Vector3(0, 0, -12)],
	[Vector3(0.24, 0.24, 0.2), TAIL, Vector3(0, 0.05, 0.42), "s"],                       # ponpon kuyruk
	[Vector3(0.17, 0.36, 0.12), FUR, Vector3(-0.18, -0.24, 0.12), "c", Vector3(90, 0, 0)],   # arka ayaklar
	[Vector3(0.17, 0.36, 0.12), FUR, Vector3(0.18, -0.24, 0.12), "c", Vector3(90, 0, 0)],
	[Vector3(0.1, 0.1, 0.12), FUR, Vector3(-0.12, -0.25, -0.22), "s"],                   # ön patiler
	[Vector3(0.1, 0.1, 0.12), FUR, Vector3(0.12, -0.25, -0.22), "s"],
	[Vector3(0.1, 0.36, 0.1), CARROT_C, Vector3(0.2, 0.2, -0.5), "k", Vector3(0, 0, -100)],  # ağızdaki havuç
	[Vector3(0.04, 0.16, 0.04), LEAF, Vector3(0.0, 0.24, -0.5), "c", Vector3(0, 0, 60)],
	# yüz (menüde önden görünür). FUR/EAR_PINK/TAIL kullanmaz: renk seti değişimi yüzü boyamasın
	[Vector3(0.08, 0.11, 0.05), EYE, Vector3(-0.11, 0.37, -0.5), "s"],                  # gözler
	[Vector3(0.08, 0.11, 0.05), EYE, Vector3(0.11, 0.37, -0.5), "s"],
	[Vector3(0.03, 0.03, 0.02), EYE_SHINE, Vector3(-0.095, 0.395, -0.525), "s"],        # göz parıltısı
	[Vector3(0.03, 0.03, 0.02), EYE_SHINE, Vector3(0.125, 0.395, -0.525), "s"],
	[Vector3(0.08, 0.06, 0.05), NOSE, Vector3(0, 0.27, -0.53), "s"],                    # burun
	[Vector3(0.012, 0.22, 0.012), WHISKER, Vector3(-0.14, 0.25, -0.5), "c", Vector3(0, 0, 80)],   # bıyıklar
	[Vector3(0.012, 0.22, 0.012), WHISKER, Vector3(-0.14, 0.22, -0.5), "c", Vector3(0, 0, 100)],
	[Vector3(0.012, 0.22, 0.012), WHISKER, Vector3(0.14, 0.25, -0.5), "c", Vector3(0, 0, -80)],
	[Vector3(0.012, 0.22, 0.012), WHISKER, Vector3(0.14, 0.22, -0.5), "c", Vector3(0, 0, -100)],
]

# Seçilebilir renk setleri (PLAN-karakter-secimi.md). skin_parts, RABBIT içindeki FUR/EAR_PINK/TAIL'i bunlarla değiştirir.
const RABBIT_SKINS := [
	{ad = "Pamuk", fur = FUR, ear = EAR_PINK, tail = TAIL},
	{ad = "Fındık", fur = Color(0.66, 0.47, 0.3), ear = Color(0.93, 0.62, 0.6), tail = Color(0.96, 0.89, 0.78)},
	{ad = "Duman", fur = Color(0.6, 0.61, 0.66), ear = Color(0.9, 0.6, 0.67), tail = Color(0.93, 0.93, 0.95)},
	{ad = "Beyza", fur = Color(0.0, 0.0, 0.01), ear = Color(0.62, 0.3, 0.4), tail = Color(0.9, 0.9, 0.92)},  # simsiyah; kulak içi ve kuyruk açık kalır, silüet okunsun
]

# Halil: kök yerden 1.0 yukarıda. Kapsül gövde, büyük kafa, geniş hasır şapka.
const HALIL := [
	[Vector3(0.28, 0.7, 0.28), OVERALL, Vector3(-0.18, -0.6, 0), "c"],                  # bacaklar
	[Vector3(0.28, 0.7, 0.28), OVERALL, Vector3(0.18, -0.6, 0), "c"],
	[Vector3(0.32, 0.2, 0.42), BOOT, Vector3(-0.18, -0.92, -0.05), "s"],                 # çizmeler
	[Vector3(0.32, 0.2, 0.42), BOOT, Vector3(0.18, -0.92, -0.05), "s"],
	[Vector3(0.8, 0.95, 0.55), SHIRT, Vector3(0, 0.1, 0), "c"],                          # gömlek
	[Vector3(0.7, 0.65, 0.58), OVERALL, Vector3(0, -0.05, 0), "c"],                      # tulum
	[Vector3(0.1, 0.5, 0.05), OVERALL, Vector3(-0.18, 0.3, 0.27), "c", Vector3(0, 0, -6)],   # sırttaki askılar
	[Vector3(0.1, 0.5, 0.05), OVERALL, Vector3(0.18, 0.3, 0.27), "c", Vector3(0, 0, 6)],
	[Vector3(0.2, 0.7, 0.2), SHIRT, Vector3(-0.47, 0.15, 0), "c", Vector3(0, 0, -15)],  # kollar
	[Vector3(0.2, 0.7, 0.2), SHIRT, Vector3(0.47, 0.15, 0), "c", Vector3(0, 0, 15)],
	[Vector3(0.18, 0.18, 0.18), SKIN, Vector3(-0.56, -0.22, 0), "s"],                    # eller
	[Vector3(0.18, 0.18, 0.18), SKIN, Vector3(0.56, -0.22, 0), "s"],
	[Vector3(0.62, 0.6, 0.6), SKIN, Vector3(0, 0.88, 0), "s"],                           # kafa
	[Vector3(0.6, 0.4, 0.32), HAIR, Vector3(0, 0.84, 0.15), "s"],                        # ense saçı (arkadan görünür)
	[Vector3(1.15, 0.05, 1.15), STRAW, Vector3(0, 1.1, 0), "y"],                         # şapka kenarı
	[Vector3(0.6, 0.3, 0.6), STRAW, Vector3(0, 1.25, 0), "y"],                           # şapka tepesi
	[Vector3(0.66, 0.08, 0.66), HAT_BAND, Vector3(0, 1.16, 0), "t"],                     # şapka bandı
]

# Tavuk: kök yerden 0.25 yukarıda.
const CHICKEN := [
	[Vector3(0.42, 0.38, 0.5), HEN, Vector3(0, 0, 0.02), "s"],                           # gövde
	[Vector3(0.1, 0.22, 0.32), HEN, Vector3(-0.2, 0.02, 0.03), "s"],                     # kanatlar
	[Vector3(0.1, 0.22, 0.32), HEN, Vector3(0.2, 0.02, 0.03), "s"],
	[Vector3(0.26, 0.26, 0.26), HEN, Vector3(0, 0.24, -0.2), "s"],                       # kafa
	[Vector3(0.08, 0.08, 0.08), COMB, Vector3(0, 0.4, -0.26), "s"],                      # ibik
	[Vector3(0.09, 0.09, 0.09), COMB, Vector3(0, 0.42, -0.2), "s"],
	[Vector3(0.08, 0.08, 0.08), COMB, Vector3(0, 0.4, -0.14), "s"],
	[Vector3(0.08, 0.12, 0.08), BEAK, Vector3(0, 0.22, -0.36), "k", Vector3(-90, 0, 0)], # gaga
	[Vector3(0.05, 0.15, 0.05), BEAK, Vector3(-0.08, -0.22, 0), "y"],                    # bacaklar
	[Vector3(0.05, 0.15, 0.05), BEAK, Vector3(0.08, -0.22, 0), "y"],
	[Vector3(0.28, 0.3, 0.1), HEN, Vector3(0, 0.12, 0.26), "s", Vector3(-30, 0, 0)],    # yelpaze kuyruk
]

# Havuç (toplanan): kök yerden 0.3 yukarıda, kendi etrafında döner.
const CARROT := [
	[Vector3(0.26, 0.5, 0.26), CARROT_C, Vector3(0, -0.05, 0), "k", Vector3(180, 0, 0)],  # uç aşağıda
	[Vector3(0.06, 0.25, 0.06), LEAF, Vector3(-0.05, 0.27, 0), "c", Vector3(0, 0, 20)],
	[Vector3(0.06, 0.28, 0.06), LEAF, Vector3(0, 0.3, 0), "c"],
	[Vector3(0.06, 0.25, 0.06), LEAF, Vector3(0.05, 0.27, 0), "c", Vector3(0, 0, -20)],
]

# Çit: kök yerden 0.3 yukarıda, toplam yükseklik 0.6 kalmalı (h = 0.6 ile üstünden atlanıyor).
const FENCE := [
	[Vector3(0.16, 0.6, 0.16), WOOD, Vector3(-0.72, 0, 0), "y"],
	[Vector3(0.16, 0.6, 0.16), WOOD, Vector3(0.72, 0, 0), "y"],
	[Vector3(0.1, 1.6, 0.1), FENCE_PAINT, Vector3(0, 0.15, 0), "c", Vector3(0, 0, 90)],  # boyalı üst tahta: kahve yolda seçilsin
	[Vector3(0.1, 1.6, 0.1), WOOD_LIGHT, Vector3(0, -0.1, 0), "c", Vector3(0, 0, 90)],
]

# Varil: kök yerden 0.8 yukarıda, toplam yükseklik 1.6 kalmalı.
const BARREL := [
	[Vector3(0.9, 1.6, 0.9), WOOD, Vector3(0, 0, 0), "y"],
	[Vector3(1.0, 1.3, 1.0), WOOD, Vector3(0, 0, 0), "s"],                               # ortadaki şişkinlik
	[Vector3(0.98, 0.08, 0.98), METAL, Vector3(0, 0.5, 0), "t"],                          # demir çemberler
	[Vector3(0.98, 0.08, 0.98), METAL, Vector3(0, -0.5, 0), "t"],
	[Vector3(0.8, 0.02, 0.8), WOOD_LIGHT, Vector3(0, 0.8, 0), "y"],                      # kapak
]

# --- Dünya (Faz 4). Kökler yer seviyesinde (y = 0). Hepsi "deco": çarpışmaya girmez. ---
const GRASS := Color(0.43, 0.66, 0.3)        # 86C160'tan koyu: gri tonlamada yoldan ve tavşandan ayrılsın
const ROAD := Color(0.74, 0.55, 0.37)        # D8B07A'dan koyu: krem tavşan yolda seçilsin
const ROAD_LINE := Color(0.93, 0.83, 0.64)
const TREE_DARK := Color(0.247, 0.541, 0.227)  # 3F8A3A
const TREE_LIGHT := Color(0.31, 0.604, 0.251)  # 4F9A40
const HILL_A := Color(0.44, 0.64, 0.31)      # 7FB35A'dan koyu
const HILL_B := Color(0.36, 0.56, 0.25)      # 6AA04A'dan koyu
const DIRT_DARK := Color(0.18, 0.12, 0.08)

const TREE := [
	[Vector3(0.3, 1.2, 0.3), WOOD, Vector3(0, 0.6, 0), "y"],
	[Vector3(1.4, 1.3, 1.4), TREE_DARK, Vector3(0, 1.6, 0), "s"],
	[Vector3(0.9, 0.8, 0.9), TREE_LIGHT, Vector3(0.25, 2.2, 0.1), "s"],
]
const BUSH := [
	[Vector3(0.9, 0.6, 0.8), TREE_DARK, Vector3(0, 0.25, 0), "s"],
	[Vector3(0.6, 0.5, 0.6), TREE_LIGHT, Vector3(0.35, 0.3, 0.15), "s"],
	[Vector3(0.5, 0.45, 0.5), TREE_LIGHT, Vector3(-0.35, 0.25, -0.1), "s"],
]
const FLOWERS := [
	[Vector3(0.6, 0.18, 0.5), TREE_LIGHT, Vector3(0, 0.05, 0), "s"],
	[Vector3(0.14, 0.14, 0.14), Color(0.96, 0.6, 0.7), Vector3(-0.15, 0.2, 0.05), "s"],
	[Vector3(0.14, 0.14, 0.14), Color(1.0, 0.85, 0.35), Vector3(0.12, 0.22, -0.08), "s"],
	[Vector3(0.12, 0.12, 0.12), TAIL, Vector3(0.05, 0.18, 0.15), "s"],
]

# Zemin + yol + uzak tepeler: tavşanla birlikte kayan katmanın içeriği (kök: tavşanın z'si, y = 0).
const GROUND := [
	[Vector3(240, 0.2, 200), GRASS, Vector3(0, -0.1, -60)],
	[Vector3(6.4, 0.2, 200), ROAD, Vector3(0, -0.09, -60)],
	[Vector3(0.08, 0.02, 200), ROAD_LINE, Vector3(-1, 0.015, -60)],   # şerit sınırları
	[Vector3(0.08, 0.02, 200), ROAD_LINE, Vector3(1, 0.015, -60)],
	[Vector3(26, 10, 34), HILL_A, Vector3(-26, 0, -50), "s"],
	[Vector3(22, 7, 28), HILL_B, Vector3(23, 0, -40), "s"],
	[Vector3(30, 12, 40), HILL_B, Vector3(-30, 0, -95), "s"],
	[Vector3(32, 11, 40), HILL_A, Vector3(28, 0, -100), "s"],
	[Vector3(20, 6, 24), HILL_A, Vector3(-28, 0, -10), "s"],
	[Vector3(18, 5, 22), HILL_B, Vector3(27, 0, 0), "s"],
]

# Yuva: tepenin içinde tavşan deliği, önünde havuç yığını. Kök yer seviyesinde, delik +z'ye (kameraya) bakar.
const BURROW := [
	[Vector3(12, 6, 8), HILL_A, Vector3(0, 0, -3), "s"],
	[Vector3(2.2, 1.8, 0.4), DIRT_DARK, Vector3(0, 0.9, 0.75), "s"],
	[Vector3(0.26, 0.5, 0.26), CARROT_C, Vector3(-0.9, 0.15, 1.8), "k", Vector3(80, 0, 20)],
	[Vector3(0.26, 0.5, 0.26), CARROT_C, Vector3(0.8, 0.15, 1.7), "k", Vector3(80, 0, -30)],
	[Vector3(0.26, 0.5, 0.26), CARROT_C, Vector3(-0.6, 0.15, 2.1), "k", Vector3(90, 40, 0)],
]

# --- Halil'in eşya etkileri (PLAN-mekanikler.md T1). Önerilen kök y değeri her modelin üstünde. ---
const EGG_WHITE := Color(0.97, 0.96, 0.9)
const YOLK := Color(1.0, 0.78, 0.2)
const CABBAGE_LIGHT := Color(0.55, 0.8, 0.4)
const CABBAGE_DARK := Color(0.36, 0.62, 0.28)
const CABBAGE_ODD := Color(0.7, 0.85, 0.3)   # dönüş görünsün diye farklı tonda tek yaprak
const DUST_C := Color(0.95, 0.86, 0.68)
const DIRT := Color(0.55, 0.4, 0.26)

# Kırılmış yumurta, kaygan alan (~1.2 x 1.2 m). Kök y = 0 (yer).
const EGG_SPLAT := [
	[Vector3(1.0, 0.04, 0.8), EGG_WHITE, Vector3(0, 0.02, 0), "s"],
	[Vector3(0.6, 0.04, 0.5), EGG_WHITE, Vector3(0.38, 0.02, 0.3), "s"],
	[Vector3(0.5, 0.04, 0.45), EGG_WHITE, Vector3(-0.38, 0.02, -0.3), "s"],
	[Vector3(0.32, 0.1, 0.32), YOLK, Vector3(0.05, 0.05, 0), "s"],
	[Vector3(0.14, 0.1, 0.14), EGG_WHITE, Vector3(-0.35, 0.05, 0.25), "k"],   # kabuk parçaları
	[Vector3(0.12, 0.08, 0.12), EGG_WHITE, Vector3(0.45, 0.04, -0.2), "k", Vector3(0, 0, 40)],
]

# Yere saplanmış tırmık: sap yerde, diş sırası yukarı bakıyor. Kök y = 0 (yer); gövde 0.6, dişler biraz taşar.
const RAKE_STUCK := [
	[Vector3(0.45, 0.12, 0.45), DIRT, Vector3(0, 0.02, 0), "s"],               # toprak tümseği
	[Vector3(0.07, 0.6, 0.07), WOOD, Vector3(0, 0.3, 0), "y"],                 # sap
	[Vector3(0.08, 0.9, 0.1), METAL, Vector3(0, 0.62, 0), "c", Vector3(0, 0, 90)],  # diş tabanı (uzunluk y, 90° ile yatar)
	[Vector3(0.05, 0.2, 0.05), METAL, Vector3(-0.36, 0.74, 0), "k"],           # dişler
	[Vector3(0.05, 0.2, 0.05), METAL, Vector3(-0.18, 0.74, 0), "k"],
	[Vector3(0.05, 0.2, 0.05), METAL, Vector3(0, 0.74, 0), "k"],
	[Vector3(0.05, 0.2, 0.05), METAL, Vector3(0.18, 0.74, 0), "k"],
	[Vector3(0.05, 0.2, 0.05), METAL, Vector3(0.36, 0.74, 0), "k"],
]

# Yuvarlanan lahana. Kök = merkez (yuvarlanırken kökü x ekseninde döndür), önerilen kök y = 0.28.
const CABBAGE := [
	[Vector3(0.5, 0.48, 0.5), CABBAGE_LIGHT, Vector3(0, 0, 0), "s"],
	[Vector3(0.5, 0.44, 0.18), CABBAGE_DARK, Vector3(0, 0, 0.2), "s", Vector3(-10, 0, 0)],
	[Vector3(0.5, 0.44, 0.18), CABBAGE_DARK, Vector3(0, 0, -0.2), "s", Vector3(10, 0, 0)],
	[Vector3(0.18, 0.44, 0.5), CABBAGE_DARK, Vector3(-0.2, 0, 0), "s", Vector3(0, 0, 10)],
	[Vector3(0.18, 0.44, 0.5), CABBAGE_ODD, Vector3(0.2, 0, 0), "s", Vector3(0, 0, -10)],
]

# Tavşanın kafasına ters geçen kova. Tavşan köküne göre (RABBIT kafası (0, 0.3, -0.3)); kulaklar tepeden taşar.
const BUCKET_HAT := [
	[Vector3(0.52, 0.4, 0.52), METAL, Vector3(0, 0.42, -0.3), "y"],
	[Vector3(0.58, 0.05, 0.58), METAL, Vector3(0, 0.23, -0.3), "t"],           # ağız kenarı
	[Vector3(0.56, 0.04, 0.56), METAL, Vector3(0, 0.38, -0.3), "t", Vector3(0, 0, 90)],  # sap
]


# --- Grafik (PLAN-grafik.md) ---
# G2 temas gölgesi: yere yapışık yarı saydam disk. Kök y = 0.02; tavşanın x/z'sini izler, zıplarken küçülür.
const SHADOW_C := Color(0.2, 0.12, 0.25, 0.3)   # siyah değil, mora kayık koyu
const SHADOW_BLOB := [[Vector3(0.8, 0.02, 0.9), SHADOW_C, Vector3.ZERO, "y"]]
const SHADOW_SHRINK := 0.35   # tepe noktasında (~1.2 m) ölçek 1 - bu değer olur

# G5 bulutlar: 3-4 basık beyaz küre öbeği. scenery içinde yüksekte, yavaş kayar.
const CLOUD_C := Color(1.0, 0.96, 0.93)
const CLOUD := [
	[Vector3(9, 3, 5), CLOUD_C, Vector3(0, 0, 0), "s"],
	[Vector3(6, 3.4, 4.5), CLOUD_C, Vector3(-3.5, 0.6, 0.3), "s"],
	[Vector3(7, 3.8, 5), CLOUD_C, Vector3(3, 0.8, -0.2), "s"],
	[Vector3(4, 2.2, 3.5), CLOUD_C, Vector3(6, -0.2, 0.4), "s"],
]

# --- Bölüm 1 karakterleri ve bölge süsleri (PLAN-bolum1.md) ---
const DOG_BLACK := Color(0.2, 0.15, 0.14)
const DOG_TAN := Color(0.62, 0.4, 0.22)
const DOG_WHITE := Color(0.95, 0.93, 0.88)
const COLLAR := Color(0.82, 0.22, 0.2)
const GOOSE_C := Color(0.87, 0.87, 0.85)    # tavuktan (HEN) daha gri: ikisi karışmasın
const GOOSE_WING := Color(0.6, 0.6, 0.63)
const BILL := Color(1.0, 0.55, 0.15)
const COOP_RED := Color(0.72, 0.3, 0.25)
const ROOF := Color(0.42, 0.28, 0.24)
const SIGN_C := Color(0.96, 0.76, 0.3)
const WARN_C := Color(1.0, 0.72, 0.2, 0.45)
const WARN_BAR := Color(0.55, 0.3, 0.1, 0.6)
const TARGET_C := Color(0.95, 0.3, 0.3, 0.55)

# Karabaş, Halil'in köpeği: arkadan gelir, sırtı ve kıvrık kuyruğu okunmalı. Kök y = 0.3 (tavşan gibi).
const DOG := [
	[Vector3(0.32, 0.72, 0.32), DOG_BLACK, Vector3(0, 0.02, 0.05), "c", Vector3(90, 0, 0)],   # gövde
	[Vector3(0.22, 0.22, 0.12), DOG_WHITE, Vector3(0, 0, -0.28), "s"],                        # göğüs lekesi
	[Vector3(0.34, 0.31, 0.34), DOG_BLACK, Vector3(0, 0.26, -0.38), "s"],                     # kafa
	[Vector3(0.17, 0.13, 0.2), DOG_TAN, Vector3(0, 0.2, -0.55), "s"],                         # burun kemiği
	[Vector3(0.07, 0.05, 0.04), EYE, Vector3(0, 0.24, -0.65), "s"],                           # burun
	[Vector3(0.05, 0.06, 0.03), EYE, Vector3(-0.08, 0.31, -0.53), "s"],                       # gözler
	[Vector3(0.05, 0.06, 0.03), EYE, Vector3(0.08, 0.31, -0.53), "s"],
	[Vector3(0.11, 0.2, 0.06), DOG_BLACK, Vector3(-0.1, 0.47, -0.36), "k", Vector3(0, 0, 12)],  # dik kulaklar
	[Vector3(0.11, 0.2, 0.06), DOG_BLACK, Vector3(0.1, 0.47, -0.36), "k", Vector3(0, 0, -12)],
	[Vector3(0.3, 0.05, 0.3), COLLAR, Vector3(0, 0.12, -0.32), "t", Vector3(-30, 0, 0)],      # tasma
	[Vector3(0.09, 0.3, 0.09), DOG_TAN, Vector3(-0.1, -0.17, -0.2), "y"],                     # bacaklar
	[Vector3(0.09, 0.3, 0.09), DOG_TAN, Vector3(0.1, -0.17, -0.2), "y"],
	[Vector3(0.09, 0.3, 0.09), DOG_TAN, Vector3(-0.1, -0.17, 0.28), "y"],
	[Vector3(0.09, 0.3, 0.09), DOG_TAN, Vector3(0.1, -0.17, 0.28), "y"],
	[Vector3(0.06, 0.32, 0.06), DOG_BLACK, Vector3(0, 0.24, 0.44), "c", Vector3(35, 0, 0)],  # yukarı kıvrık kuyruk
	[Vector3(0.14, 0.08, 0.2), DOG_TAN, Vector3(0, 0.17, 0.12), "s"],                         # sırttaki açık leke
]

# Kaz: uzun boyunlu, gri-beyaz, turuncu gaga. Kök y = 0 (yer).
const GOOSE := [
	[Vector3(0.42, 0.36, 0.6), GOOSE_C, Vector3(0, 0.32, 0.05), "s"],                         # gövde
	[Vector3(0.1, 0.24, 0.42), GOOSE_WING, Vector3(-0.2, 0.36, 0.08), "s"],                   # kanatlar
	[Vector3(0.1, 0.24, 0.42), GOOSE_WING, Vector3(0.2, 0.36, 0.08), "s"],
	[Vector3(0.11, 0.42, 0.11), GOOSE_C, Vector3(0, 0.62, -0.2), "c", Vector3(-15, 0, 0)],    # boyun
	[Vector3(0.16, 0.15, 0.2), GOOSE_C, Vector3(0, 0.85, -0.26), "s"],                        # kafa
	[Vector3(0.08, 0.16, 0.07), BILL, Vector3(0, 0.83, -0.4), "k", Vector3(-90, 0, 0)],       # gaga
	[Vector3(0.04, 0.05, 0.03), EYE, Vector3(-0.06, 0.88, -0.3), "s"],
	[Vector3(0.04, 0.05, 0.03), EYE, Vector3(0.06, 0.88, -0.3), "s"],
	[Vector3(0.04, 0.16, 0.04), BILL, Vector3(-0.08, 0.08, 0.05), "y"],                       # bacaklar
	[Vector3(0.04, 0.16, 0.04), BILL, Vector3(0.08, 0.08, 0.05), "y"],
	[Vector3(0.1, 0.03, 0.14), BILL, Vector3(-0.08, 0.01, 0.0), "s"],                         # perdeli ayaklar
	[Vector3(0.1, 0.03, 0.14), BILL, Vector3(0.08, 0.01, 0.0), "s"],
	[Vector3(0.2, 0.14, 0.14), GOOSE_WING, Vector3(0, 0.4, 0.36), "s", Vector3(30, 0, 0)],    # kuyruk
]

# Kümes: kümes bölgesinin yol kenarı işareti. Kök y = 0 (yer), kapısı +z'ye (kameraya) bakar.
const COOP := [
	[Vector3(1.8, 1.1, 1.4), COOP_RED, Vector3(0, 0.8, 0)],
	[Vector3(1.05, 0.08, 1.6), ROOF, Vector3(-0.44, 1.56, 0), "b", Vector3(0, 0, 30)],
	[Vector3(1.05, 0.08, 1.6), ROOF, Vector3(0.44, 1.56, 0), "b", Vector3(0, 0, -30)],
	[Vector3(0.1, 0.3, 0.1), WOOD, Vector3(-0.8, 0.15, -0.6), "y"],                           # ayaklar
	[Vector3(0.1, 0.3, 0.1), WOOD, Vector3(0.8, 0.15, -0.6), "y"],
	[Vector3(0.1, 0.3, 0.1), WOOD, Vector3(-0.8, 0.15, 0.6), "y"],
	[Vector3(0.1, 0.3, 0.1), WOOD, Vector3(0.8, 0.15, 0.6), "y"],
	[Vector3(0.42, 0.5, 0.04), DIRT_DARK, Vector3(0, 0.62, 0.71)],                           # kapı
	[Vector3(0.36, 0.04, 0.8), WOOD_LIGHT, Vector3(0, 0.22, 1.05), "b", Vector3(-22, 0, 0)],  # rampa
]

# Bölge tabelası (yazısız; metin HUD'da pop ile). Kök y = 0 (yer).
const SIGN := [
	[Vector3(0.1, 1.3, 0.1), WOOD, Vector3(0, 0.65, 0), "y"],
	[Vector3(0.8, 0.4, 0.06), WOOD, Vector3(0, 1.2, 0)],
	[Vector3(0.66, 0.28, 0.08), SIGN_C, Vector3(0, 1.2, 0)],
]

# Karabaş'ın şerit uyarısı: atış hedef diskinden farklı, uzun sarı-turuncu şerit. Kök y = 0.03.
const WARN_STRIP := [
	[Vector3(1.3, 0.03, 4.0), WARN_C, Vector3.ZERO, "y"],
	[Vector3(0.9, 0.035, 0.14), WARN_BAR, Vector3(0, 0.005, -1.0)],   # çapraz çizgiler: renge değil desene de bakılsın (renk körlüğü)
	[Vector3(1.1, 0.035, 0.14), WARN_BAR, Vector3(0, 0.005, 0)],
	[Vector3(0.9, 0.035, 0.14), WARN_BAR, Vector3(0, 0.005, 1.0)],
]

# --- Hikaye anları ve bölge dekorları (DEGERLENDIRME.md D3). Kökler yer seviyesinde (y = 0). ---
const HAY := Color(0.86, 0.74, 0.4)
const HAY_BAND := Color(0.6, 0.45, 0.22)
const ROCK_C := Color(0.6, 0.58, 0.56)
const CAP_RED := Color(0.85, 0.3, 0.25)

# Tarla: havuç sırası (toprak tümsek + yeşil sap + turuncu uç)
const CROPS := [
	[Vector3(1.2, 0.25, 0.7), DIRT, Vector3(0, 0.02, 0), "s"],
	[Vector3(0.1, 0.08, 0.1), CARROT_C, Vector3(-0.35, 0.17, 0), "k", Vector3(180, 0, 0)],
	[Vector3(0.1, 0.08, 0.1), CARROT_C, Vector3(0, 0.18, 0.05), "k", Vector3(180, 0, 0)],
	[Vector3(0.1, 0.08, 0.1), CARROT_C, Vector3(0.35, 0.17, -0.05), "k", Vector3(180, 0, 0)],
	[Vector3(0.06, 0.24, 0.06), LEAF, Vector3(-0.35, 0.26, 0), "c"],
	[Vector3(0.06, 0.26, 0.06), LEAF, Vector3(0, 0.28, 0.05), "c"],
	[Vector3(0.06, 0.24, 0.06), LEAF, Vector3(0.35, 0.26, -0.05), "c"],
]
# Köpek bölgesi: köpek kulübesi ve mama kabı
const DOGHOUSE := [
	[Vector3(1.1, 0.8, 1.0), WOOD_LIGHT, Vector3(0, 0.4, 0)],
	[Vector3(0.68, 0.07, 1.15), COOP_RED, Vector3(-0.27, 0.98, 0), "b", Vector3(0, 0, 32)],
	[Vector3(0.68, 0.07, 1.15), COOP_RED, Vector3(0.27, 0.98, 0), "b", Vector3(0, 0, -32)],
	[Vector3(0.42, 0.5, 0.05), DIRT_DARK, Vector3(0, 0.3, 0.5), "s"],                # kapı
	[Vector3(0.28, 0.08, 0.28), METAL, Vector3(0.6, 0.04, 0.75), "y"],               # mama kabı
]
# Saman balyası (köpek ve kümes bölgesi)
const HAYBALE := [
	[Vector3(0.9, 0.8, 0.9), HAY, Vector3(0, 0.45, 0), "y", Vector3(0, 0, 90)],
	[Vector3(0.92, 0.05, 0.92), HAY_BAND, Vector3(-0.2, 0.45, 0), "t", Vector3(0, 0, 90)],
	[Vector3(0.92, 0.05, 0.92), HAY_BAND, Vector3(0.2, 0.45, 0), "t", Vector3(0, 0, 90)],
]
# Kümes bölgesi: yumurta sepeti
const BASKET := [
	[Vector3(0.5, 0.3, 0.5), WOOD_LIGHT, Vector3(0, 0.15, 0), "y"],
	[Vector3(0.14, 0.18, 0.14), EGG_WHITE, Vector3(-0.1, 0.32, 0), "s"],
	[Vector3(0.14, 0.18, 0.14), EGG_WHITE, Vector3(0.1, 0.33, 0.05), "s"],
	[Vector3(0.14, 0.18, 0.14), EGG_WHITE, Vector3(0, 0.34, -0.1), "s"],
]
# Son düzlük (yuvaya yakın, vahşi): kaya ve mantarlar
const ROCK := [
	[Vector3(0.9, 0.5, 0.7), ROCK_C, Vector3(0, 0.15, 0), "s"],
	[Vector3(0.5, 0.35, 0.45), ROCK_C, Vector3(0.45, 0.1, 0.2), "s"],
]
const MUSHROOM := [
	[Vector3(0.12, 0.25, 0.12), EGG_WHITE, Vector3(0, 0.12, 0), "y"],
	[Vector3(0.36, 0.2, 0.36), CAP_RED, Vector3(0, 0.28, 0), "s"],
	[Vector3(0.08, 0.16, 0.08), EGG_WHITE, Vector3(0.25, 0.08, 0.15), "y"],
	[Vector3(0.22, 0.13, 0.22), CAP_RED, Vector3(0.25, 0.18, 0.15), "s"],
]
# Bölgeye göre kenar dekoru (anahtarlar main.gd zone() adlarıyla aynı). Ağaç (TREE) yine yoldan uzak durur.
const ZONE_DECO := {
	"tarla": [CROPS, CROPS, TREE, FLOWERS],
	"kopek": [DOGHOUSE, HAYBALE, BUSH, TREE],
	"kumes": [HAYBALE, BASKET, BUSH, FLOWERS],
	"son": [ROCK, MUSHROOM, TREE, BUSH],
}


# Çiftlik binaları: yol kenarında ve menünün arkasında. Kök yer seviyesinde, kapı +z yönünde.
const WALL_CREAM := Color(0.96, 0.9, 0.78)
const WINDOW_C := Color(0.62, 0.8, 0.92)
const SILO_C := Color(0.74, 0.78, 0.83)
const HOUSE := [
	[Vector3(4.0, 2.6, 3.6), WALL_CREAM, Vector3(0, 1.3, 0)],
	[Vector3(4.6, 0.16, 2.4), ROOF, Vector3(0, 3.12, 0.9), "b", Vector3(30, 0, 0)],
	[Vector3(4.6, 0.16, 2.4), ROOF, Vector3(0, 3.12, -0.9), "b", Vector3(-30, 0, 0)],
	[Vector3(0.6, 1.2, 0.6), DIRT_DARK, Vector3(1.3, 3.6, -0.6)],                      # baca
	[Vector3(0.8, 1.5, 0.08), WOOD, Vector3(0, 0.75, 1.82)],                           # kapı
	[Vector3(0.8, 0.8, 0.08), WINDOW_C, Vector3(-1.3, 1.5, 1.82)],
	[Vector3(0.8, 0.8, 0.08), WINDOW_C, Vector3(1.3, 1.5, 1.82)],
]
const BARN := [
	[Vector3(5.4, 3.4, 4.6), COOP_RED, Vector3(0, 1.7, 0)],
	[Vector3(6.0, 0.18, 3.1), ROOF, Vector3(0, 4.15, 1.2), "b", Vector3(33, 0, 0)],
	[Vector3(6.0, 0.18, 3.1), ROOF, Vector3(0, 4.15, -1.2), "b", Vector3(-33, 0, 0)],
	[Vector3(2.0, 2.4, 0.08), TAIL, Vector3(0, 1.2, 2.32)],                            # büyük kapı
	[Vector3(1.7, 0.14, 0.1), COOP_RED, Vector3(0, 1.2, 2.38), "b", Vector3(0, 0, 40)],
	[Vector3(1.7, 0.14, 0.1), COOP_RED, Vector3(0, 1.2, 2.38), "b", Vector3(0, 0, -40)],
]
const SILO := [
	[Vector3(1.9, 5.2, 1.9), SILO_C, Vector3(0, 2.6, 0), "y"],
	[Vector3(1.9, 1.2, 1.9), ROOF, Vector3(0, 5.4, 0), "s"],
]
const FARM := [HOUSE, BARN, SILO]

# Menünün arkası ve kenarları: [model, konum (tavşana göre), y dönüşü (derece), ölçek]. Kamera -z'den +z'ye baktığı için ön yüzler -z'ye (180).
const FARM_SCALE := 1.3  # arka plan çiftliği oyundaki binalardan büyük dursun
const FARM_SET := [
	[HOUSE, Vector3(-9, 0, 11), 180, FARM_SCALE], [BARN, Vector3(-1, 0, 17), 180, FARM_SCALE], [SILO, Vector3(3.5, 0, 14), 0, FARM_SCALE],
	[BARN, Vector3(-17, 0, 17), 180, FARM_SCALE], [HOUSE, Vector3(-21, 0, 8), 115, FARM_SCALE], [SILO, Vector3(-14, 0, 24), 0, FARM_SCALE],
	[HOUSE, Vector3(7, 0, 24), 180, FARM_SCALE], [BARN, Vector3(14, 0, 28), 200, FARM_SCALE], [SILO, Vector3(18, 0, 22), 0, FARM_SCALE],
	[HOUSE, Vector3(-10, 0, -8), 90, FARM_SCALE], [HOUSE, Vector3(10, 0, -4), -90, FARM_SCALE],
	[TREE, Vector3(-5, 0, 7), 0, 1.0], [TREE, Vector3(-13, 0, 12), 40, 1.0], [TREE, Vector3(8, 0, 12), 90, 1.0], [BUSH, Vector3(-6, 0, 12), 0, 1.0],
	[FENCE, Vector3(-5, 0.3, 21), 90, 1.0], [FENCE, Vector3(-9, 0.3, 21), 90, 1.0], [FENCE, Vector3(2, 0.3, 21), 90, 1.0],
]
