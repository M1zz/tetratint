#!/usr/bin/env python3
"""Mac App Store 스크린샷 합성: 창 캡처 + 헤드라인 → 2880x1800. HTML → 헤드리스 Chrome.

사용법: python3 scripts/make_marketing_screenshots.py [로케일 ...]
  원본: docs/screenshots/raw/<로케일>/NN-….png   (1440x840pt 창을 screencapture -o -l 로 뜬 것, 2880x1680)
  제출: docs/screenshots/marketing/<로케일>/NN-….png  (2880x1800, DeployBar 가 올린다)
원본은 그 언어로 띄운 앱 화면이어야 한다(-AppleLanguages "(ko)" / "(en)").
"""
import subprocess, sys, pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
RAW = ROOT / "docs" / "screenshots" / "raw"
OUTROOT = ROOT / "docs" / "screenshots" / "marketing"
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
W, H = 2880, 1800

# 헤드라인은 언어마다 따로 쓴다(직역 금지). 앱에 있는 기능만.
SHOTS = {
    "ko": [
        ("01-generator.png",    "색 하나로 다크와 고대비까지", "라이트 색 하나에서 네 가지 변형을 만들고 .colorset으로 내보내요"),
        ("02-contrast.png",     "고대비 대응이 필요한 색만 골라내기", "앱에서 쓰는 색을 붙여넣으면 WCAG 기준으로 바로 판정해요"),
        ("03-color-vision.png", "색각이상 사용자의 눈으로 확인", "적색맹, 녹색맹, 청색맹, 흑백 시뮬레이션과 구분 불가 경고"),
        ("04-dynamic-type.png", "커스텀 폰트도 다이나믹 타입으로", "크기 표와 SwiftUI, UIKit 코드를 한 화면에서"),
        ("05-system-colors.png", "시스템 색상의 네 가지 모습을 한눈에", "라이트, 다크, 고대비 값을 나란히 보고 바로 복사해요"),
    ],
    "en-US": [
        ("01-generator.png",    "One color in. Dark and high contrast out.", "Derive four variants from a single light color and export a .colorset"),
        ("02-contrast.png",     "Find the colors that fail contrast", "Paste the colors your app uses and get a WCAG verdict for each"),
        ("03-color-vision.png", "See your palette through other eyes", "Simulate protanopia, deuteranopia, tritanopia and grayscale"),
        ("04-dynamic-type.png", "Dynamic Type for your custom fonts", "Size tables and ready-to-paste SwiftUI and UIKit code"),
        ("05-system-colors.png", "Every system color, all four looks", "Light, dark and high contrast values side by side, ready to copy"),
    ],
    "en-GB": [
        ("01-generator.png",    "One colour in. Dark and high contrast out.", "Create four variants from a single light colour and export a .colorset"),
        ("02-contrast.png",     "Spot the colours that fall short on contrast", "Paste in your app's colours and get a WCAG verdict for each one"),
        ("03-color-vision.png", "See your palette as others see it", "Preview protanopia, deuteranopia, tritanopia and greyscale, with warnings for look-alike colours"),
        ("04-dynamic-type.png", "Dynamic Type for custom fonts, sorted", "Size tables plus SwiftUI and UIKit code, all on one screen"),
        ("05-system-colors.png", "Every system colour in all four looks", "Light, dark and high contrast values side by side, ready to copy"),
    ],
    "zh-Hans": [
        ("01-generator.png",    "一个颜色，生成深色与高对比度", "从一个浅色出发生成四种变体，并导出 .colorset"),
        ("02-contrast.png",     "找出对比度不达标的颜色", "粘贴 App 里用到的颜色，立即按 WCAG 标准给出判定"),
        ("03-color-vision.png", "用色觉障碍用户的眼睛来检查", "模拟红色盲、绿色盲、蓝色盲和灰度，难以分辨时自动提醒"),
        ("04-dynamic-type.png", "自定义字体也能支持动态字体", "字号对照表与 SwiftUI、UIKit 代码，一屏搞定"),
        ("05-system-colors.png", "系统颜色的四种面貌，一目了然", "浅色、深色、高对比度的取值并排展示，点一下即可复制"),
    ],
    "zh-Hant": [
        ("01-generator.png",    "一個顏色，生成深色與高對比", "從一個淺色出發產生四種變體，並匯出 .colorset"),
        ("02-contrast.png",     "找出對比不足的顏色", "貼上 App 使用的顏色，馬上依 WCAG 標準給出判定"),
        ("03-color-vision.png", "用色覺障礙使用者的眼睛來檢查", "模擬紅色盲、綠色盲、藍色盲與灰階，難以分辨時會提出警示"),
        ("04-dynamic-type.png", "自訂字體也能支援動態字體", "字級對照表與 SwiftUI、UIKit 程式碼，一個畫面全看到"),
        ("05-system-colors.png", "系統顏色的四種樣貌，一目瞭然", "淺色、深色、高對比的數值並排顯示，一鍵就能複製"),
    ],
    "ja": [
        ("01-generator.png",    "1色から、ダークも高コントラストも", "ライトカラー1色から4つのバリエーションを作り、.colorset で書き出せます"),
        ("02-contrast.png",     "コントラスト不足の色を見つけ出す", "アプリで使う色を貼り付けるだけで、WCAG 基準で即判定します"),
        ("03-color-vision.png", "色覚特性のある人の見え方でチェック", "P型・D型・T型・グレースケールをシミュレートし、区別しにくい色は警告します"),
        ("04-dynamic-type.png", "カスタムフォントもDynamic Typeに対応", "サイズ表と SwiftUI・UIKit のコードを1画面で確認できます"),
        ("05-system-colors.png", "システムカラーの4つの表情をひと目で", "ライト・ダーク・高コントラストの値を並べて表示し、そのままコピーできます"),
    ],
    "ru": [
        ("01-generator.png",    "Один цвет: и тёмная тема, и высокий контраст", "Создайте четыре варианта из одного светлого цвета и экспортируйте .colorset"),
        ("02-contrast.png",     "Найдите цвета, которым не хватает контраста", "Вставьте цвета своего приложения и сразу узнайте оценку по WCAG"),
        ("03-color-vision.png", "Палитра глазами людей с нарушением цветового зрения", "Протанопия, дейтеранопия, тританопия и оттенки серого, плюс предупреждения о неразличимых цветах"),
        ("04-dynamic-type.png", "Dynamic Type для собственных шрифтов", "Таблицы размеров и код для SwiftUI и UIKit на одном экране"),
        ("05-system-colors.png", "Системные цвета в четырёх вариантах", "Значения для светлой, тёмной тем и высокого контраста рядом, копируются в один клик"),
    ],
    "es-MX": [
        ("01-generator.png",    "Un solo color, y listo el oscuro y el alto contraste", "Crea cuatro variantes a partir de un color claro y expórtalas como .colorset"),
        ("02-contrast.png",     "Detecta los colores con poco contraste", "Pega los colores de tu app y obtén al instante el resultado según WCAG"),
        ("03-color-vision.png", "Mira tu paleta con otros ojos", "Simula protanopía, deuteranopía, tritanopía y escala de grises, con aviso si dos colores se confunden"),
        ("04-dynamic-type.png", "Dynamic Type también para tus fuentes", "Tablas de tamaños y código de SwiftUI y UIKit en una sola pantalla"),
        ("05-system-colors.png", "Los colores del sistema en sus cuatro versiones", "Valores en claro, oscuro y alto contraste lado a lado, listos para copiar"),
    ],
    "de-DE": [
        ("01-generator.png",    "Eine Farbe rein, Dark Mode und Kontrast raus", "Aus einer hellen Farbe vier Varianten erzeugen und als .colorset exportieren"),
        ("02-contrast.png",     "Farben mit zu wenig Kontrast aufspüren", "Farben aus deiner App einfügen und sofort die WCAG-Bewertung sehen"),
        ("03-color-vision.png", "Deine Palette mit anderen Augen sehen", "Simulation von Rot-, Grün- und Blauschwäche sowie Graustufen, inklusive Warnung bei Verwechslungsgefahr"),
        ("04-dynamic-type.png", "Dynamic Type auch für eigene Schriften", "Größentabellen und fertiger Code für SwiftUI und UIKit auf einen Blick"),
        ("05-system-colors.png", "Alle Systemfarben in vier Ausführungen", "Hell, Dunkel und erhöhter Kontrast nebeneinander, direkt kopierbar"),
    ],
    "fr-FR": [
        ("01-generator.png",    "Une couleur, et le sombre et le contraste élevé suivent", "Générez quatre variantes à partir d'une seule couleur claire et exportez un .colorset"),
        ("02-contrast.png",     "Repérez les couleurs au contraste insuffisant", "Collez les couleurs de votre app et obtenez aussitôt un verdict WCAG"),
        ("03-color-vision.png", "Votre palette vue autrement", "Simulez protanopie, deutéranopie, tritanopie et niveaux de gris, avec alerte si deux couleurs se confondent"),
        ("04-dynamic-type.png", "Dynamic Type pour vos polices personnalisées", "Tableaux de tailles et code SwiftUI et UIKit réunis sur un seul écran"),
        ("05-system-colors.png", "Chaque couleur système sous ses quatre aspects", "Valeurs clair, sombre et contraste élevé côte à côte, prêtes à copier"),
    ],
    "it": [
        ("01-generator.png",    "Un solo colore, e arrivano scuro e alto contrasto", "Crea quattro varianti da un unico colore chiaro ed esporta un .colorset"),
        ("02-contrast.png",     "Trova i colori con poco contrasto", "Incolla i colori della tua app e ottieni subito il verdetto WCAG"),
        ("03-color-vision.png", "La tua palette vista da altri occhi", "Simula protanopia, deuteranopia, tritanopia e scala di grigi, con avviso se due colori si confondono"),
        ("04-dynamic-type.png", "Dynamic Type anche per i font personalizzati", "Tabelle delle dimensioni e codice SwiftUI e UIKit in un'unica schermata"),
        ("05-system-colors.png", "Ogni colore di sistema nelle sue quattro versioni", "Valori chiaro, scuro e alto contrasto affiancati, pronti da copiare"),
    ],
    "pt-BR": [
        ("01-generator.png",    "Uma cor só, e saem o escuro e o alto contraste", "Gere quatro variações a partir de uma cor clara e exporte um .colorset"),
        ("02-contrast.png",     "Descubra as cores com contraste insuficiente", "Cole as cores do seu app e veja na hora o resultado pelo WCAG"),
        ("03-color-vision.png", "Veja sua paleta com outros olhos", "Simule protanopia, deuteranopia, tritanopia e tons de cinza, com alerta quando duas cores se confundem"),
        ("04-dynamic-type.png", "Dynamic Type também para fontes personalizadas", "Tabelas de tamanhos e código em SwiftUI e UIKit numa tela só"),
        ("05-system-colors.png", "Cada cor do sistema em suas quatro versões", "Valores de claro, escuro e alto contraste lado a lado, prontos para copiar"),
    ],
    "th": [
        ("01-generator.png",    "สีเดียว ได้ทั้งโหมดมืดและคอนทราสต์สูง", "สร้างสีสี่แบบจากสีโหมดสว่างสีเดียว แล้วส่งออกเป็น .colorset"),
        ("02-contrast.png",     "ค้นหาสีที่คอนทราสต์ไม่ผ่านเกณฑ์", "วางสีที่แอปใช้ แล้วดูผลตามมาตรฐาน WCAG ได้ทันที"),
        ("03-color-vision.png", "ดูจานสีผ่านสายตาของผู้ที่ตาบอดสี", "จำลองภาพแบบตาบอดสีแดง เขียว น้ำเงิน และขาวดำ พร้อมเตือนเมื่อแยกสีไม่ออก"),
        ("04-dynamic-type.png", "ฟอนต์ที่คุณทำเองก็รองรับ Dynamic Type", "ตารางขนาดตัวอักษรพร้อมโค้ด SwiftUI และ UIKit ในหน้าเดียว"),
        ("05-system-colors.png", "สีของระบบทั้งสี่แบบ เห็นครบในที่เดียว", "ค่าสีโหมดสว่าง โหมดมืด และคอนทราสต์สูง เรียงข้างกัน คัดลอกได้เลย"),
    ],
    "vi": [
        ("01-generator.png",    "Một màu gốc, đủ cả nền tối và tương phản cao", "Tạo bốn biến thể từ một màu sáng rồi xuất ra .colorset"),
        ("02-contrast.png",     "Tìm ra những màu chưa đủ độ tương phản", "Dán các màu trong ứng dụng để nhận kết quả theo chuẩn WCAG ngay"),
        ("03-color-vision.png", "Xem bảng màu qua mắt người mù màu", "Mô phỏng mù màu đỏ, xanh lục, xanh lam và thang xám, kèm cảnh báo khi khó phân biệt"),
        ("04-dynamic-type.png", "Phông chữ riêng cũng hỗ trợ Dynamic Type", "Bảng cỡ chữ cùng mã SwiftUI và UIKit trên một màn hình"),
        ("05-system-colors.png", "Màu hệ thống ở cả bốn dạng, nhìn là thấy", "Giá trị sáng, tối và tương phản cao đặt cạnh nhau, sao chép được ngay"),
    ],
    "cs": [
        ("01-generator.png",    "Z jedné barvy tmavý režim i vysoký kontrast", "Vytvořte čtyři varianty z jedné světlé barvy a exportujte je jako .colorset"),
        ("02-contrast.png",     "Najděte barvy s nedostatečným kontrastem", "Vložte barvy ze své aplikace a hned uvidíte hodnocení podle WCAG"),
        ("03-color-vision.png", "Paleta očima lidí s poruchou barvocitu", "Simulace protanopie, deuteranopie, tritanopie a odstínů šedi s upozorněním na nerozlišitelné barvy"),
        ("04-dynamic-type.png", "Dynamic Type i pro vlastní písma", "Tabulky velikostí a kód pro SwiftUI a UIKit na jedné obrazovce"),
        ("05-system-colors.png", "Systémové barvy ve všech čtyřech podobách", "Hodnoty pro světlý, tmavý režim a vysoký kontrast vedle sebe, připravené ke zkopírování"),
    ],
    "da": [
        ("01-generator.png",    "Én farve ind, mørk og høj kontrast ud", "Lav fire varianter ud fra én lys farve og eksportér et .colorset"),
        ("02-contrast.png",     "Find de farver, der mangler kontrast", "Indsæt appens farver og få en WCAG-vurdering med det samme"),
        ("03-color-vision.png", "Se din palet med andres øjne", "Simulér rød-, grøn- og blåblindhed samt gråtoner, med advarsel når farver ikke kan skelnes"),
        ("04-dynamic-type.png", "Dynamic Type til dine egne skrifttyper", "Størrelsestabeller og kode til SwiftUI og UIKit på ét skærmbillede"),
        ("05-system-colors.png", "Alle systemfarver i fire udgaver", "Lys, mørk og høj kontrast side om side, klar til at kopiere"),
    ],
    "el": [
        ("01-generator.png",    "Ένα χρώμα, και βγαίνουν σκούρο και υψηλή αντίθεση", "Δημιουργήστε τέσσερις παραλλαγές από ένα ανοιχτό χρώμα και εξαγάγετε .colorset"),
        ("02-contrast.png",     "Βρείτε τα χρώματα με ανεπαρκή αντίθεση", "Επικολλήστε τα χρώματα της εφαρμογής σας και δείτε αμέσως την κρίση κατά WCAG"),
        ("03-color-vision.png", "Η παλέτα σας με τα μάτια των άλλων", "Προσομοίωση πρωτανοπίας, δευτερανοπίας, τριτανοπίας και αποχρώσεων του γκρι, με προειδοποίηση για μη διακρίσιμα χρώματα"),
        ("04-dynamic-type.png", "Dynamic Type και για τις δικές σας γραμματοσειρές", "Πίνακες μεγεθών και κώδικας SwiftUI και UIKit σε μία οθόνη"),
        ("05-system-colors.png", "Τα χρώματα συστήματος στις τέσσερις όψεις τους", "Τιμές για φωτεινό, σκούρο και υψηλή αντίθεση δίπλα δίπλα, έτοιμες για αντιγραφή"),
    ],
    "fi": [
        ("01-generator.png",    "Yhdestä värista tumma tila ja korkea kontrasti", "Luo neljä muunnelmaa yhdestä vaaleasta väristä ja vie ne .colorset-tiedostoksi"),
        ("02-contrast.png",     "Löydä värit, joiden kontrasti on liian heikko", "Liitä sovelluksesi värit ja saat heti WCAG-arvion"),
        ("03-color-vision.png", "Paletti toisten silmin", "Simuloi punavihersokeutta, sinikeltasokeutta ja harmaasävyjä, ja saat varoituksen erottumattomista väreistä"),
        ("04-dynamic-type.png", "Dynamic Type myös omille fonteille", "Kokotaulukot sekä SwiftUI- ja UIKit-koodi samalla näytöllä"),
        ("05-system-colors.png", "Järjestelmävärit kaikissa neljässä asussa", "Vaalea, tumma ja korkea kontrasti vierekkäin, valmiina kopioitavaksi"),
    ],
    "id": [
        ("01-generator.png",    "Satu warna, jadi mode gelap dan kontras tinggi", "Buat empat varian dari satu warna terang, lalu ekspor sebagai .colorset"),
        ("02-contrast.png",     "Temukan warna yang kontrasnya kurang", "Tempel warna yang dipakai aplikasimu dan langsung lihat penilaian WCAG-nya"),
        ("03-color-vision.png", "Lihat palet warnamu lewat mata orang lain", "Simulasi buta warna merah, hijau, biru, dan skala abu-abu, lengkap dengan peringatan jika warna sulit dibedakan"),
        ("04-dynamic-type.png", "Dynamic Type untuk font buatanmu sendiri", "Tabel ukuran plus kode SwiftUI dan UIKit dalam satu layar"),
        ("05-system-colors.png", "Warna sistem dalam empat tampilan sekaligus", "Nilai mode terang, gelap, dan kontras tinggi berdampingan, siap disalin"),
    ],
    "no": [
        ("01-generator.png",    "Én farge inn, mørk og høy kontrast ut", "Lag fire varianter fra én lys farge og eksporter et .colorset"),
        ("02-contrast.png",     "Finn fargene som mangler kontrast", "Lim inn fargene appen bruker og få en WCAG-vurdering med en gang"),
        ("03-color-vision.png", "Se paletten med andres øyne", "Simuler rød-, grønn- og blåblindhet og gråtoner, med advarsel når farger ikke kan skilles"),
        ("04-dynamic-type.png", "Dynamic Type for dine egne skrifttyper", "Størrelsestabeller og kode for SwiftUI og UIKit på én skjerm"),
        ("05-system-colors.png", "Alle systemfarger i fire utgaver", "Lys, mørk og høy kontrast side om side, klare til å kopieres"),
    ],
    "nl-NL": [
        ("01-generator.png",    "Eén kleur erin, donker en hoog contrast eruit", "Maak vier varianten van één lichte kleur en exporteer een .colorset"),
        ("02-contrast.png",     "Ontdek welke kleuren te weinig contrast hebben", "Plak de kleuren uit je app en zie direct de WCAG-beoordeling"),
        ("03-color-vision.png", "Zie je palet door andere ogen", "Simuleer protanopie, deuteranopie, tritanopie en grijstinten, met een waarschuwing bij kleuren die niet te onderscheiden zijn"),
        ("04-dynamic-type.png", "Dynamic Type voor je eigen lettertypen", "Groottetabellen en code voor SwiftUI en UIKit op één scherm"),
        ("05-system-colors.png", "Elke systeemkleur in vier uitvoeringen", "Licht, donker en hoog contrast naast elkaar, klaar om te kopiëren"),
    ],
    "pl": [
        ("01-generator.png",    "Jeden kolor, a wychodzi ciemny motyw i wysoki kontrast", "Stwórz cztery warianty z jednego jasnego koloru i wyeksportuj plik .colorset"),
        ("02-contrast.png",     "Znajdź kolory o zbyt niskim kontraście", "Wklej kolory z aplikacji i od razu sprawdź ocenę według WCAG"),
        ("03-color-vision.png", "Twoja paleta oczami innych", "Symulacja protanopii, deuteranopii, tritanopii i skali szarości z ostrzeżeniem o kolorach nie do odróżnienia"),
        ("04-dynamic-type.png", "Dynamic Type także dla własnych czcionek", "Tabele rozmiarów oraz kod SwiftUI i UIKit na jednym ekranie"),
        ("05-system-colors.png", "Każdy kolor systemowy w czterech odsłonach", "Wartości dla trybu jasnego, ciemnego i wysokiego kontrastu obok siebie, gotowe do skopiowania"),
    ],
    "sv": [
        ("01-generator.png",    "En färg in, mörkt läge och hög kontrast ut", "Skapa fyra varianter från en ljus färg och exportera en .colorset"),
        ("02-contrast.png",     "Hitta färgerna som saknar kontrast", "Klistra in appens färger och få ett WCAG-utlåtande direkt"),
        ("03-color-vision.png", "Se din palett med andras ögon", "Simulera röd-, grön- och blåblindhet samt gråskala, med varning när färger inte går att skilja åt"),
        ("04-dynamic-type.png", "Dynamic Type för dina egna typsnitt", "Storlekstabeller och kod för SwiftUI och UIKit på en och samma skärm"),
        ("05-system-colors.png", "Alla systemfärger i fyra skepnader", "Ljust, mörkt och hög kontrast sida vid sida, redo att kopiera"),
    ],
    "tr": [
        ("01-generator.png",    "Tek renk girin, koyu ve yüksek karşıtlık çıksın", "Tek bir açık renkten dört varyant üretin ve .colorset olarak dışa aktarın"),
        ("02-contrast.png",     "Karşıtlığı yetersiz renkleri bulun", "Uygulamanızın renklerini yapıştırın, WCAG sonucunu anında görün"),
        ("03-color-vision.png", "Paletinize başka gözlerle bakın", "Protanopi, döteranopi, tritanopi ve gri tonlama simülasyonu, ayırt edilemeyen renkler için uyarıyla"),
        ("04-dynamic-type.png", "Özel yazı tipleriniz için Dynamic Type", "Boyut tabloları ile SwiftUI ve UIKit kodu tek ekranda"),
        ("05-system-colors.png", "Sistem renklerinin dört hali bir arada", "Açık, koyu ve yüksek karşıtlık değerleri yan yana, kopyalamaya hazır"),
    ],
}

HTML = """<!doctype html><html lang="{lang}"><head><meta charset="utf-8"><style>
* {{ margin:0; padding:0; box-sizing:border-box; }}
html,body {{ width:{W}px; height:{H}px; overflow:hidden; }}
body {{ background:linear-gradient(160deg,#f6f4ff 0%,#eef3ff 55%,#fdf2f7 100%);
  font-family:-apple-system,"SF Pro Display","Apple SD Gothic Neo",sans-serif; position:relative; }}
.text {{ position:absolute; left:0; right:0; top:110px; text-align:center; padding:0 160px; }}
.headline {{ font-size:104px; font-weight:800; color:#1c1c2e; letter-spacing:-0.025em; line-height:1.1; word-break:keep-all; }}
.sub {{ margin-top:30px; font-size:48px; font-weight:500; color:#5e5e70; letter-spacing:-0.01em; word-break:keep-all; }}
.win {{ position:absolute; left:50%; top:470px; width:2380px; transform:translateX(-50%);
  border-radius:26px; overflow:hidden;
  box-shadow:0 50px 120px rgba(40,30,90,.22), 0 0 0 1px rgba(0,0,0,.08); }}
.win img {{ width:100%; display:block; }}
</style></head><body>
<div class="text"><div class="headline">{headline}</div><div class="sub">{sub}</div></div>
<div class="win"><img src="{img}"></div>
</body></html>"""


def render(html_path, out_png):
    for _ in range(4):
        try:
            r = subprocess.run([CHROME, "--headless=new", f"--screenshot={out_png}",
                                f"--window-size={W},{H}", "--force-device-scale-factor=1",
                                "--hide-scrollbars", "--disable-gpu", "--virtual-time-budget=2000",
                                "--allow-file-access-from-files", html_path.as_uri()],
                               capture_output=True, timeout=90)
        except subprocess.TimeoutExpired:
            continue
        if r.returncode == 0:
            return
    raise SystemExit(f"Chrome 이 그리지 못했다: {out_png}")


def main(only=None):
    for loc, shots in SHOTS.items():
        if only and loc not in only:
            continue
        out = OUTROOT / loc
        out.mkdir(parents=True, exist_ok=True)
        for fname, headline, sub in shots:
            html = HTML.format(lang=loc[:2], W=W, H=H, headline=headline, sub=sub,
                               img=(RAW / loc / fname).as_uri())
            html_path = pathlib.Path("/tmp") / f"tetratint-{loc}-{fname.replace('.png', '.html')}"
            html_path.write_text(html, encoding="utf-8")
            render(html_path, out / fname)
            print(f"rendered {out / fname}")


if __name__ == "__main__":
    main(sys.argv[1:] or None)
