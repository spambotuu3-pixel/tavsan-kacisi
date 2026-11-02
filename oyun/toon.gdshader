// Yumuşak iki bantlı çizgi film malzemesi (PLAN-grafik.md G3). Tek yönlü güneş için yazıldı.
// Saydam parçalar (hedef diski, blob gölge) bunu değil StandardMaterial3D kullanır.
shader_type spatial;

uniform vec4 albedo : source_color = vec4(1.0);
uniform vec3 shade_tint : source_color = vec3(0.62, 0.55, 0.85); // gölge tarafı: mora kayık (gün batımının tamamlayıcısı)
uniform float shade_light = 0.35;   // gölge tarafına düşen güneş payı; 0 olursa sadece ortam ışığı kalır
uniform float light_scale = 0.75;  // StandardMaterial'a göre güneş daha parlak düşüyor, dengeler
uniform float band_soft = 0.08;     // ışık-gölge geçişinin genişliği (0'a yakın = keskin)
uniform float rim_amount = 0.35;
uniform float bottom_dark = 0.12;   // yere yakın kısımlar bu oranda koyu: nesneler yere oturur
uniform bool sway = false;          // ağaç tacı ve çalılar için rüzgar (G5)
uniform bool vcol_srgb = true;       // köşe rengi sRGB ise doğrusala çevir (Compatibility renderer zaten doğrusal veriyor)
uniform bool vcol = false;          // birleşik model: renk köşe renginden (sRGB) gelir

varying float world_y;
varying vec3 base;

void vertex() {
	if (sway) {
		VERTEX.x += sin(TIME * 1.5 + NODE_POSITION_WORLD.z) * 0.05 * (VERTEX.y + 0.5);
	}
	vec3 c = COLOR.rgb;
	vec3 lin = mix(pow((c + 0.055) / 1.055, vec3(2.4)), c / 12.92, step(c, vec3(0.04045)));
	base = vcol ? (vcol_srgb ? lin : c) : albedo.rgb;
	world_y = (MODEL_MATRIX * vec4(VERTEX, 1.0)).y;
}

void fragment() {
	ALBEDO = base * mix(1.0 - bottom_dark, 1.0, clamp(world_y / 1.2, 0.0, 1.0));
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}

void light() {
	float lit = smoothstep(-band_soft, band_soft, dot(NORMAL, LIGHT));
	lit *= smoothstep(0.3, 0.7, ATTENUATION);  // gölgeler de aynı yumuşak bantla
	DIFFUSE_LIGHT += LIGHT_COLOR / PI * light_scale * mix(shade_tint * shade_light, vec3(1.0), lit);
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0) * rim_amount * lit;
	rim *= mix(0.1, 1.0, smoothstep(0.0, 0.15, dot(base, vec3(0.3, 0.6, 0.1))));  // simsiyah kürk parlamasın: koyu renklerde kenar ışığı zayıf
	SPECULAR_LIGHT += rim * LIGHT_COLOR / PI;
}
