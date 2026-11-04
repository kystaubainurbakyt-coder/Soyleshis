"""Create concise Word reports for SOYLE practical works 6 and 7."""

from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile
from xml.etree.ElementTree import Element, SubElement, register_namespace, tostring

ROOT = Path(__file__).resolve().parents[1]
DOCS = ROOT / "docs"
W = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
R = "http://schemas.openxmlformats.org/officeDocument/2006/relationships"
register_namespace("w", W)
register_namespace("r", R)


def q(name):
    return f"{{{W}}}{name}"


def element(parent, name, attrs=None):
    return SubElement(parent, q(name), attrs or {})


def run(parent, text, *, bold=False, size=28, color="000000", italic=False):
    node = element(parent, "r")
    props = element(node, "rPr")
    fonts = element(props, "rFonts")
    fonts.set(q("ascii"), "Times New Roman")
    fonts.set(q("hAnsi"), "Times New Roman")
    fonts.set(q("eastAsia"), "Times New Roman")
    fonts.set(q("cs"), "Times New Roman")
    element(props, "sz", {q("val"): str(size)})
    element(props, "color", {q("val"): color})
    if bold:
        element(props, "b")
    if italic:
        element(props, "i")
    element(node, "t").text = text
    return node


def paragraph(body, text="", *, style=None, align=None, bold=False, size=28,
              color="000000", before=0, after=140, italic=False):
    p = element(body, "p")
    ppr = element(p, "pPr")
    if style:
        element(ppr, "pStyle", {q("val"): style})
    if align:
        element(ppr, "jc", {q("val"): align})
    element(ppr, "spacing", {q("before"): str(before), q("after"): str(after),
                              q("line"): "340", q("lineRule"): "auto"})
    if text:
        run(p, text, bold=bold, size=size, color=color, italic=italic)
    return p


def heading(body, text, level=1):
    return paragraph(body, text, style=f"Heading{level}", bold=True,
                     size=30 if level == 1 else 26,
                     color="000000",
                     before=200, after=120)


def bullet(body, text):
    p = paragraph(body, after=90)
    run(p, "•  ", bold=True, color="000000")
    run(p, text)


def page_break(body):
    p = element(body, "p")
    run_node = element(p, "r")
    element(run_node, "br", {q("type"): "page"})


def table(body, rows):
    t = element(body, "tbl")
    props = element(t, "tblPr")
    element(props, "tblW", {q("w"): "9360", q("type"): "dxa"})
    borders = element(props, "tblBorders")
    for side in ("top", "left", "bottom", "right", "insideH", "insideV"):
        element(borders, side, {q("val"): "single", q("sz"): "5", q("color"): "C5D0DC"})
    margins = element(props, "tblCellMar")
    for side, value in (("top", "90"), ("left", "110"), ("bottom", "90"), ("right", "110")):
        element(margins, side, {q("w"): value, q("type"): "dxa"})
    grid = element(t, "tblGrid")
    widths = [9360 // len(rows[0])] * len(rows[0])
    widths[-1] += 9360 - sum(widths)
    for width in widths:
        element(grid, "gridCol", {q("w"): str(width)})
    for ridx, values in enumerate(rows):
        tr = element(t, "tr")
        for cidx, text in enumerate(values):
            tc = element(tr, "tc")
            tcpr = element(tc, "tcPr")
            element(tcpr, "tcW", {q("w"): str(widths[cidx]), q("type"): "dxa"})
            element(tcpr, "shd", {q("fill"): "FFFFFF", q("val"): "clear"})
            p = element(tc, "p")
            ppr = element(p, "pPr")
            element(ppr, "spacing", {q("after"): "30"})
            run(p, str(text), bold=ridx == 0, size=24, color="000000")
    return t


def screenshot(body, title, where, what):
    paragraph(body, title, bold=True, size=28, color="000000", before=140, after=70)
    paragraph(body, f"Қайдан алу керек: {where}", size=28, color="000000", after=60)
    paragraph(body, f"Көрсетуі тиіс: {what}", size=28, color="000000", after=50)
    t = element(body, "tbl")
    props = element(t, "tblPr")
    element(props, "tblW", {q("w"): "9360", q("type"): "dxa"})
    borders = element(props, "tblBorders")
    for side in ("top", "left", "bottom", "right"):
        element(borders, side, {q("val"): "dashed", q("sz"): "10", q("color"): "9AAABD"})
    row = element(t, "tr")
    trpr = element(row, "trPr")
    element(trpr, "trHeight", {q("val"): "1700", q("hRule"): "atLeast"})
    cell = element(row, "tc")
    tcpr = element(cell, "tcPr")
    element(tcpr, "shd", {q("fill"): "FFFFFF", q("val"): "clear"})
    element(tcpr, "vAlign", {q("val"): "center"})
    p = element(cell, "p")
    ppr = element(p, "pPr")
    element(ppr, "jc", {q("val"): "center"})
    run(p, f"ОСЫ ЖЕРГЕ СКРИНШОТ ҚОЙЫҢЫЗ\n{title}", bold=True, size=24, color="000000")


def build_report(work_number, title, objective, blocks, screenshots, output_name):
    document = Element(q("document"))
    body = element(document, "body")
    paragraph(body, "ҚАЗАҚСТАН РЕСПУБЛИКАСЫ", align="center", bold=True, size=26, color="000000", after=90)
    paragraph(body, "____________________________________________", align="center", size=22, color="000000", after=40)
    paragraph(body, "(оқу орнының атауы)", align="center", size=21, color="000000", after=1300)
    paragraph(body, f"ПРАКТИКАЛЫҚ ЖҰМЫС №{work_number}", align="center", bold=True,
              size=36, color="000000", after=180)
    paragraph(body, title, align="center", bold=True, size=29, color="000000", after=220)
    paragraph(body, "SOYLE — қазақ тілін үйренуге арналған мобильді қосымша",
              align="center", size=25, color="000000", after=1000)
    paragraph(body, "Орындаған: ______________________________", align="right", size=23, after=120)
    paragraph(body, "Тобы: ____________________________________", align="right", size=23, after=120)
    paragraph(body, "Тексерген: _______________________________", align="right", size=23, after=900)
    paragraph(body, "__________________ — 2026 жыл", align="center", size=23, color="000000")
    page_break(body)
    heading(body, "Жұмыстың мақсаты")
    paragraph(body, objective)
    for block in blocks:
        kind = block[0]
        if kind == "heading":
            heading(body, block[1], block[2] if len(block) > 2 else 1)
        elif kind == "p":
            paragraph(body, block[1])
        elif kind == "bullet":
            bullet(body, block[1])
        elif kind == "table":
            table(body, block[1])
        elif kind == "page":
            page_break(body)
    heading(body, "Скриншоттар")
    paragraph(body, "Төмендегі бос орындарға көрсетілген экрандардың скриншоттарын өзіңіз қойыңыз. Суретті қою кезінде осы нұсқаулық жолдарын алып тастауға болады.")
    for item in screenshots:
        screenshot(body, *item)
    heading(body, "Қорытынды")
    paragraph(body, blocks[-1][-1] if blocks[-1][0] == "conclusion" else "Жұмыс барысында тапсырмада көрсетілген негізгі функциялар SOYLE жобасына енгізілді.")

    sect = element(body, "sectPr")
    element(sect, "pgSz", {q("w"): "11906", q("h"): "16838"})
    element(sect, "pgMar", {q("top"): "1134", q("right"): "1134", q("bottom"): "1134",
                             q("left"): "1417", q("header"): "567", q("footer"): "567", q("gutter"): "0"})
    styles = Element(q("styles"))
    for style_id, name, size, color in (("Normal", "Normal", 28, "000000"),
                                        ("Heading1", "heading 1", 30, "000000"),
                                        ("Heading2", "heading 2", 26, "000000")):
        style = element(styles, "style", {q("type"): "paragraph", q("styleId"): style_id})
        element(style, "name", {q("val"): name})
        ppr = element(style, "pPr")
        element(ppr, "spacing", {q("after"): "140", q("line"): "340", q("lineRule"): "auto"})
        rpr = element(style, "rPr")
        fonts = element(rpr, "rFonts")
        fonts.set(q("ascii"), "Times New Roman")
        fonts.set(q("hAnsi"), "Times New Roman")
        fonts.set(q("eastAsia"), "Times New Roman")
        element(rpr, "sz", {q("val"): str(size)})
        element(rpr, "color", {q("val"): color})
        if style_id != "Normal":
            element(rpr, "b")
    document_rels = (f'<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>'
        '</Relationships>').encode()
    root_rels = (f'<?xml version="1.0" encoding="UTF-8"?>'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>'
        '</Relationships>').encode()
    content_types = (f'<?xml version="1.0" encoding="UTF-8"?>'
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
        '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
        '<Default Extension="xml" ContentType="application/xml"/>'
        '<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>'
        '<Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>'
        '</Types>').encode()
    output = DOCS / output_name
    with ZipFile(output, "w", ZIP_DEFLATED) as archive:
        archive.writestr("[Content_Types].xml", content_types)
        archive.writestr("_rels/.rels", root_rels)
        archive.writestr("word/document.xml", tostring(document, encoding="utf-8", xml_declaration=True))
        archive.writestr("word/styles.xml", tostring(styles, encoding="utf-8", xml_declaration=True))
        archive.writestr("word/_rels/document.xml.rels", document_rels)
    with ZipFile(output) as archive:
        if archive.testzip() is not None:
            raise RuntimeError(f"Invalid DOCX: {output}")
    print(f"Created {output} ({output.stat().st_size} bytes)")


work6 = [
    ("heading", "Жобаның қысқаша сипаттамасы"),
    ("p", "SOYLE — қазақ тілін үйренуге арналған Flutter қосымшасы. Тіркелу, жүйеге кіру, профиль және жеке оқу прогресі бір қолданба аясында байланыстырылған."),
    ("heading", "Орындалған негізгі талаптар"),
    ("table", [["Талап", "Жобадағы орындалуы"],
        ["Registration және validation", "Аты, email, пароль және парольді растау өрістері бар. Міндетті өрістер мен формат тексеріледі."],
        ["Login және қате хабарламасы", "Email/пароль тексеріледі; қате дерек пен қайталанған әрекеттерге түсінікті хабарлама беріледі."],
        ["Сессияны сақтау/қалпына келтіру", "Құпиясөз secure storage-та хэш түрінде сақталады. Қолданба ашылғанда сессия тексеріледі."],
        ["Logout және Profile", "Шығу сессияны тазартады; профиль аты, email және жергілікті оқу прогресімен байланысқан."],
        ["State Management", "Provider және ChangeNotifier негізіндегі AppState ортақ күйді басқарады."],
        ["Күрделі құрылғы функциясы", "Камерамен QR сканері `soyle://lesson/<id>` сілтемесінен сабақ бетін ашады."],
    ]),
    ("heading", "QR сканерінің жұмыс логикасы"),
    ("bullet", "Сканер тек QR форматындағы кодты оқиды және `mobile_scanner` кітапханасын қолданады."),
    ("bullet", "Құрылғы камерасына рұқсат керек. Рұқсат берілмесе, камера қатесі көрсетіліп, қайта сұрау батырмасы беріледі."),
    ("bullet", "Тек SOYLE сабақ сілтемесі жарамды. Қате код оқушыны сабаққа өткізбейді және түсінікті қате көрсетеді."),
    ("bullet", "Жеке беттер маршрут деңгейінде қорғалған; авторизация жоқ кезде login экранына бағытталады."),
    ("heading", "Тексеру нәтижесі"),
    ("table", [["Тексеру", "Күтілетін нәтиже"],
        ["Бос/қате email немесе әлсіз пароль", "Тіркеу тоқтап, өрістің жанында түсіндірме шығады."],
        ["Қате пароль", "Қолданбаға кіргізбейді, қате хабарламасын көрсетеді."],
        ["Қолданбаны қайта ашу", "Сақталған сессия бар болса үй беті, болмаса кіру беті ашылады."],
        ["Logout", "Сессия жойылып, авторизацияланған маршруттар жабылады."],
        ["QR рұқсаты жоқ/берілген", "Рұқсат жоқта қайта сұрау ұсынылады; барда QR танылып, сабақ ашылады."],
    ]),
    ("p", "Автоматты тесттер тіркеу, validation, қате login, сессияны қалпына келтіру және аккаунт прогресінің бөлінуін тексереді. Камера рұқсатын беру/бермеу нақты Android құрылғысында қолмен тексеріледі."),
    ("conclusion", "SOYLE қосымшасына Registration, Login, Logout және Profile ағындары, Provider күй басқаруы және камераға рұқсат сұрайтын QR сканері біріктірілді. QR сканері жарамды сабақ сілтемесін тікелей сабақ экранына апарады; сессия қайта іске қосылғаннан кейін тексеріледі."),
]
screens6 = [
    ("1-сурет. Тіркелу формасы және validation", "Тіркелу экранына бос не қате email енгізіп, өріс validation хабарламалары көрінетіндей түсіріңіз.", "Қате дерекпен тіркеу орындалмайтынын және міндетті өрістер тексерілетінін."),
    ("2-сурет. Сәтті кіру және профиль", "Дұрыс тіркелгімен кіргеннен кейін Profile бетін ашыңыз.", "Пайдаланушы аты/email-і, оқу прогресі және Logout батырмасын."),
    ("3-сурет. QR сканері және камера рұқсаты", "Profile ішінен QR Scanner ашыңыз; рұқсат сұрауын немесе сканер ашылғанын түсіріңіз.", "Permission сұрауы/камера интерфейсі және сабақ QR-ін сканерлеу нәтижесін."),
]

work7 = [
    ("heading", "Жобаның нақты уақыттағы сценарийі"),
    ("p", "SOYLE оқу бөлмесінде оқушылардың мәтіндік чаты және әкімшінің хабарландыруы WebSocket арқылы таратылады. Оқушы жазған хабар барлық қосылған клиентте бірден көрсетіледі."),
    ("heading", "Технология және орындалу логикасы"),
    ("table", [["Бөлік", "Іске асырылуы"],
        ["Flutter клиенті", "`web_socket_channel` пакетінің көмегімен `ws://127.0.0.1:8767` адресіне қосылады."],
        ["Realtime сервері", "Python `websockets` қызметі қосылған клиенттер арасында чат пен хабарландыру таратады."],
        ["Хабарлама моделі", "ID, автор, мәтін, түрі және уақыт белгісі тексеріліп, Dart моделіне түрленеді."],
        ["Қайта қосылу", "Байланыс үзілгенде Offline/Connecting күйі көрсетіліп, автоматты retry орындалады."],
        ["Әкімші панелі", "Орысша/ағылшынша интерфейс; курс мазмұнын басқару және оқушыларға тікелей хабарландыру жіберу."],
    ]),
    ("heading", "Қате жағдайлары және лог жүргізу"),
    ("bullet", "Клиент offline болса, чат мәтінін енгізу өрісі өшіп, түсінікті күй және қайта қосылу әрекеті көрсетіледі."),
    ("bullet", "Сервер бос және 500 таңбадан ұзын хабарламаны қабылдамай, жіберу жиілігін шектейді."),
    ("bullet", "Сервер соңғы 100 хабарламаны жаңа қосылымға қайта жібереді және жад көлемін шектейді."),
    ("bullet", "Әкімші әрекеттері мен сервер қателері парольді және хабар мәтінін логқа жазбай тіркеледі."),
    ("heading", "Refactoring және тестілеу"),
    ("bullet", "WebSocket жұмысы UI-дан StudyChatController-ге, хабарлама талдауы StudyChatMessage моделіне бөлінді."),
    ("bullet", "Әкімші сервері каталог CRUD, сессияны тексеру және хабарландыру таратуға жауапты бөлек бөліктерге бөлінді."),
    ("table", [["Тест жиыны", "Нақты нәтиже"],
        ["Flutter чат моделі", "6 unit тест өтті: JSON оқу/жазу, хабарландыру түрі, қате деректер."],
        ["Python realtime хабы", "6 тест өтті: тарату, тарих, лимит, қате хабарлама және rate limit."],
        ["Python әкімші сервері", "8 тест өтті: кіру, рұқсат, login шегі, сабақ CRUD, backup, хабарландыру."],
        ["Flutter статикалық талдау", "`flutter analyze` — қате жоқ."],
    ]),
    ("p", "Байқалған іске қосу мәселесі: сервер қосылмаған кезде бұрын әкімші беті байланыс қатесін беретін. Қазір `python tool/admin_server.py` әкімші HTTP және WebSocket қызметтерін бірге іске қосады; құжатта екі терминалмен іске қосу қадамдары берілген."),
    ("p", "Толық Flutter тест жиынында жобаға дейіннен бар REST экран виджет тесті `pumpAndSettle timed out` қатесін береді, себебі экранда аяқталмайтын жүктеу анимациясы бар. Realtime unit және Python сервер тесттері одан бөлек сәтті өтті."),
    ("conclusion", "SOYLE жобасына сервер мен клиент арасында нақты уақыттағы оқу чаты, автоматты қайта қосылу, offline/error күйі, әкімші хабарландыруы және операциялық логтар енгізілді. Код клиент контроллері мен серверлік realtime модуліне бөлініп рефакторланды; realtime және әкімші жұмысының 20 тесті (6 Flutter + 14 Python) өтті."),
]
screens7 = [
    ("1-сурет. Онлайн оқу бөлмесі", "Бірінші браузер терезесінде Study room ашыңыз; екі терезе қолдансаңыз, екі клиенттің бірін-бірі көретінін көрсетіңіз.", "Online күйін, жіберілген хабарды және қабылдаған клиентті."),
    ("2-сурет. Әкімшінің хабарландыруы", "Әкімші панелінің жоғарғы жағындағы хабарландыру өрісіне қысқа мәтін енгізіп, Send/Отправить басыңыз.", "Көрінетін жіберу батырмасын және «жіберілді» растауын; екінші терезеде келген хабарды."),
    ("3-сурет. Offline және қайта қосылу", "Сервер терминалында Ctrl+C басып клиенттегі offline күйді түсіріңіз; серверді қайта қосып online болғанын түсіріңіз.", "Байланыс үзілген күйді және сервер қайта қосылғаннан кейінгі қалпына келуді."),
    ("4-сурет. Тест нәтижелері", "Терминалда Python unittest және `flutter test test/study_chat_message_test.dart` командаларын орындаңыз.", "Өткен realtime/әкімші тесттерінің қорытынды санын."),
]

build_report(6, "Пайдаланушыны тіркеу, авторизациялау және QR функциясы",
             "Registration, Login, Logout, Profile, Provider технологиясы және камера/QR функциясы бар мобильді қосымшаны әзірлеу; сессия мен экрандарға қолжетімділікті тексеру.",
             work6, screens6, "SOYLE_practical_work_06_black.docx")
build_report(7, "Нақты уақыттағы функция, рефакторинг және тестілеу",
             "WebSocket арқылы realtime функциясын қосу, offline/error және қайта қосылу күйлерін өңдеу, кодты рефакторлау және негізгі функцияларды unit/widget/server тесттерімен тексеру.",
             work7, screens7, "SOYLE_practical_work_07_black.docx")
