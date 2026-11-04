from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
from xml.sax.saxutils import escape
from datetime import datetime, timezone

OUT = Path(__file__).resolve().parents[1] / 'docs' / 'SOYLE_practical_work_04.docx'

def run(text, bold=False, size=None):
    props = ('<w:b/>' if bold else '') + (f'<w:sz w:val="{size}"/>' if size else '')
    return f'<w:r><w:rPr>{props}</w:rPr><w:t xml:space="preserve">{escape(text)}</w:t></w:r>'

def p(text='', style=None, align=None, bold=False, size=None, after=100):
    props = (f'<w:pStyle w:val="{style}"/>' if style else '') + (f'<w:jc w:val="{align}"/>' if align else '') + f'<w:spacing w:after="{after}"/>'
    return f'<w:p><w:pPr>{props}</w:pPr>{run(text,bold,size)}</w:p>'

def heading(text): return p(text, 'Heading1', after=160)
def bullet(text): return p('• ' + text, after=90)
def page(): return '<w:p><w:r><w:br w:type="page"/></w:r></w:p>'
def table(headers, rows, widths):
    grid = ''.join(f'<w:gridCol w:w="{v}"/>' for v in widths)
    def row(values, header=False):
        cells = []
        for text, width in zip(values, widths):
            fill = '<w:shd w:fill="EAF0F7"/>' if header else ''
            cells.append(f'<w:tc><w:tcPr><w:tcW w:w="{width}" w:type="dxa"/>{fill}</w:tcPr>' + p(text,bold=header,size=21,after=65) + '</w:tc>')
        return '<w:tr><w:trPr><w:cantSplit/>' + ('<w:tblHeader/>' if header else '') + '</w:trPr>' + ''.join(cells) + '</w:tr>'
    return '<w:tbl><w:tblPr><w:tblW w:w="0" w:type="auto"/><w:tblBorders>' + ''.join(f'<w:{side} w:val="single" w:sz="4" w:color="BCC7D4"/>' for side in ['top','left','bottom','right','insideH','insideV']) + '</w:tblBorders><w:tblCellMar><w:top w:w="65" w:type="dxa"/><w:left w:w="85" w:type="dxa"/><w:bottom w:w="65" w:type="dxa"/><w:right w:w="85" w:type="dxa"/></w:tblCellMar></w:tblPr><w:tblGrid>'+grid+'</w:tblGrid>'+row(headers,True)+''.join(row(r) for r in rows)+'</w:tbl>'

body=[]
body += [p('Қазақстан Республикасы',align='center',size=28),p('________________________________________',align='center'),p('(оқу орнының атауы)',align='center',size=24)]
body += [p('',after=500),p('ПРАКТИКАЛЫҚ ЖҰМЫС №4',align='center',bold=True,size=34,after=220),p('Пайдаланушы интерфейсінің макеттерін әзірлеу',align='center',bold=True,size=30,after=220),p('SOYLE мобильді қосымшасы',align='center',bold=True,size=28),p('Локалды деректер қоры және деректермен жұмыс істеу',align='center',size=26)]
body += [p('',after=550),p('Орындаған: __________________________',align='right'),p('Тобы: _______________________________',align='right'),p('Тексерген: ___________________________',align='right'),p('',after=650),p('__________________ — 2026 жыл',align='center')]
body += [page(),heading('1. Жұмыстың мақсаты және енгізілген өзгерістер')]
body += [p('Мақсаты — SOYLE қосымшасына интернетсіз жұмыс істейтін локалды деректер қорын енгізу және деректерді қосу, оқу, өзгерту, өшіру, іздеу, сүзгілеу мен сұрыптау мүмкіндіктерін іске асыру.')]
body += [p('SOYLE — қазақ тілін үйренуге арналған Flutter қосымшасы. Интерфейс орыс және ағылшын тілдерінде жұмыс істейді. Бұрынғы сабақтар, деңгейлер мен оқу сценарийлері сақталып, осы жұмыста деректерді сақтау қабаты және жеке оқу жазбалары қосылды.')]
for text in ['Hive CE кітапханалары орнатылып, қор қолданба іске қосылғанда инициализацияланады.', 'Деректермен жұмыс істеуге арналған LearningRepository қабаты құрылды.', 'Профильге «Мои заметки / My notebook» бөлімі, сабаққа жеке жазбаларды ашу батырмасы қосылды.', 'Профиль, сабақтар, прогресс, таңдаулылар және жеке жазбалар Hive арқылы сақталады.', 'Бұрынғы оқу прогресі мен таңдаулыларды көшіру іске асырылды. Құпиясөз хэштері secure storage ішінде қалды.']:
    body.append(bullet(text))
body += [heading('2. Деректер модельдері және байланыстары')]
body += [table(['Модель','Негізгі өрістер','Байланысы'],[
('LearnerRecord','id: String; name: String; learningData: Map','Пайдаланушының жазбалары мен оқу нәтижелері'),
('CourseRecord','id: String (A1–C1); position: int','Бір деңгейге бірнеше сабақ тиесілі'),
('Lesson','id: int; level: String; title: String; minutes: int; words: List','level → CourseRecord.id'),
('StudyNote','id/ownerId: String; lessonId: int; title/body: String; priority: int; favorite: bool; createdAt/updatedAt: DateTime','ownerId → LearnerRecord.id; lessonId → Lesson.id'),
('FavoriteRecord','id/ownerId: String; lessonId: int','Пайдаланушы мен таңдаған сабақ'),
('LessonProgressRecord','id/ownerId: String; lessonId: int; score: int; completed: bool','Пайдаланушы мен сабақ нәтижесі'),
], [1900,3700,3750])]
body += [page(),heading('3. Қосылған функционал')]
body += [table(['Операция','Қосымшада орындалуы'],[
('Create — қосу','«Мои заметки» бөліміндегі «Добавить заметку / Add a note» арқылы атауы, сабақ, мәтін және маңыздылығы енгізіледі.'),
('Read — оқу','Сақталған жазбалар тізімде көрсетіледі. Сабақ, деңгей, мәтін және маңыздылық беріледі.'),
('Update — өзгерту','«Изменить заметку / Edit note» арқылы бар жазбаның атауы, мәтіні, сабағы және маңыздылығы жаңартылады.'),
('Delete — өшіру','Себет белгішесі арқылы жою диалогі ашылады. Жазба пайдаланушы растағаннан кейін ғана өшіріледі.'),
('Іздеу','Атау мен жазба мәтінінен ізделеді; әріп регистрі ескерілмейді.'),
('Сүзгілеу','Деңгей, нақты сабақ және таңдаулы жазбалар бойынша сүзгілерді бірге қолдануға болады.'),
('Сұрыптау','Атауы бойынша, соңғы өзгертілген уақыты бойынша және маңыздылығы бойынша үш нұсқа бар.'),
('Favorites','Жұлдызша жеке жазбаны таңдаулыға қосады. Сабақтардың бұрынғы таңдаулы функциясы да Hive қорында сақталады.'),
],[2400,6950])]
body += [p('Маңызды шектеу: оқушы тек өзінің жеке жазбаларын өзгертеді. Жарияланған сабақтарды қосу немесе өңдеу құқығы оқушыға берілмейді.',bold=True,after=160)]
body += [heading('4. Валидация және қате өңдеу')]
for text in ['Атау 3–80 символ, жазба мәтіні 1–2000 символ болуы тиіс. Маңыздылық 1–3 аралығында таңдалады.', 'Жазба нақты пайдаланушыға және бар сабаққа байланысады. Басқа аккаунттың жазбасын өңдеуге немесе өшіруге жол берілмейді.', 'Жазба жоқ болса, түсінікті бос күй көрсетіледі. Іздеу нәтижесіз болса, «Ничего не найдено / No results» хабарламасы беріледі.', 'Қор ашылмаса немесе сақтау қатесі туындаса, қате туралы хабарлама көрсетіледі. Сақтау кезінде қайталанған батырма басулары шектеледі.']:
    body.append(bullet(text))
body += [page(),heading('5. Практикалық тапсырма кезеңдерінің нәтижелері')]
steps=[
('1','Негізгі ақпарат анықталды','Пайдаланушы, деңгей, сабақ, жазба, таңдаулы және прогресс.'),
('2','6 модель құрылды','LearnerRecord, CourseRecord, Lesson, StudyNote, FavoriteRecord, LessonProgressRecord.'),
('3','Өрістер мен типтер берілді','String, int, bool, DateTime, List, Map және тұрақты идентификаторлар.'),
('4','Байланыстар белгіленді','Пайдаланушы–жазба; деңгей–сабақ; пайдаланушы–сабақ нәтижесі.'),
('5','Сақтау технологиясы таңдалды','Hive CE локалды деректер қоры.'),
('6','Кітапханалар қосылды','hive_ce және hive_ce_flutter орнатылды.'),
('7','Қор инициализацияланды','Қолданба іске қосылғанда алты коллекция ашылады.'),
('8','Create орындалды','Жеке оқу жазбасын қосу.'),
('9','Read орындалды','Қордағы сабақтар мен жазбаларды оқу және көрсету.'),
('10','Update орындалды','Бар жазбаны және оқу күйін жаңарту.'),
('11','Delete орындалды','Растаудан кейін жеке жазбаны өшіру.'),
('12','Repository қабаты құрылды','LearningRepository сақтау операцияларын басқарады.'),
('13','Іздеу қосылды','Жазбаның атауы және мәтіні бойынша.'),
('14','Сүзгілеу қосылды','Деңгей, сабақ және таңдаулы бойынша.'),
('15','Сұрыптау қосылды','Атау, уақыт және маңыздылық бойынша.'),
('16','Favorites іске асырылды','Сабақтар мен жеке жазбалардың таңдаулылары сақталады.'),
('17','Бос күй өңделді','Жазба болмауы және іздеу нәтижесінің болмауы көрсетіледі.'),
('18','Қателер өңделді','Валидация, қор және сақтау қателері хабарланады.'),
('19','Желісіз операциялар тексерілді','Локалды тесттер желілік сұраусыз орындалды; телефондағы ұшақ режимі тексерілмеді.'),
('20','Сақталуы тексерілді','Нақты Hive файлдары жабылып, қайта ашылғаннан кейін деректер оқылды.'),
]
body += [table(['№','Кезең','Нақты нәтиже'], steps, [450,3250,5650])]
body += [page(),heading('6. Код құрылымы')]
for text in ['lib/core/database/learning_repository.dart — қорды ашу, каталогты толтыру, CRUD, сұраулар және сақтау.', 'lib/core/database/models/local_entities.dart — локалды деректер модельдері.', 'lib/features/notebook/presentation/screens/notebook_screen.dart — жазбалар тізімі, қосу/өзгерту формасы және басқару элементтері.', 'lib/core/state/app_state.dart — Hive арқылы оқу күйін сақтау, қалпына келтіру және ескі деректерді көшіру.', 'lib/main.dart — қорды қолданба іске қосылғанға дейін инициализациялау.', 'lib/app/router/app_routes.dart — /notebook маршруты; профиль мен сабақ экранынан өту.']:
    body.append(bullet(text))
body += [heading('7. Тексеру нәтижелері')]
body += [table(['Тексеру','Нәтиже'],[
('Деректер қорының тесттері','5 тест: алты коллекция, CRUD, аккаунттарды оқшаулау, іздеу/сүзгі/сұрыптау, қате жағдайлары, миграция және қайта ашылғандағы сақталу тексерілді.'),
('Интерфейс тесттері','2 тест: жазбаны қосу, міндетті өрістерді тексеру, өңдеу, іздеу, жоюды растау диалогі және қор қатесінің көрсетілуі тексерілді.'),
('Статикалық талдау','flutter analyze — қате табылған жоқ.'),
('Құрастыру','flutter build web --no-wasm-dry-run — веб-нұсқа сәтті жиналды.'),
('Тексеру шегі','Сақталу нақты локалды Hive файлдарымен тексерілді. Физикалық телефонды ұшақ режиміне ауыстыру және мобильді қосымшаны толық қайта іске қосу бұл ортада орындалмады.'),
],[2700,6650])]
body += [heading('8. Қорытынды')]
body += [p('Практикалық жұмыс барысында SOYLE қосымшасына локалды деректер қоры мен жеке оқу жазбалары енгізілді. Пайдаланушы жазбаларын қосып, оқып, өзгертіп, өшіре алады; оларды іздеп, сүзгілеп, сұрыптап және таңдаулыға сақтайды. Оқу деректері аккаунт бойынша бөлінеді. Қорды қайта ашқаннан кейін сақталған мәліметтердің қалпына келуі автоматтандырылған тесттермен расталды.')]
body += [p('Қосымшадағы жол: Профиль → «Мои заметки / My notebook». Нақты сабақтың жазбалары сабақ ішіндегі «Заметки к уроку / Lesson notes» батырмасынан ашылады.',bold=True)]

ns='xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"'
section='<w:sectPr><w:footerReference w:type="default" r:id="rIdFooter"/><w:titlePg/><w:pgSz w:w="11906" w:h="16838"/><w:pgMar w:top="1134" w:right="850" w:bottom="1134" w:left="1701" w:header="450" w:footer="500"/></w:sectPr>'
document='<?xml version="1.0" encoding="UTF-8" standalone="yes"?><w:document '+ns+'><w:body>'+''.join(body)+section+'</w:body></w:document>'
styles='''<?xml version="1.0" encoding="UTF-8" standalone="yes"?><w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:docDefaults><w:rPrDefault><w:rPr><w:rFonts w:ascii="Times New Roman" w:hAnsi="Times New Roman" w:cs="Times New Roman"/><w:sz w:val="26"/><w:lang w:val="kk-KZ"/></w:rPr></w:rPrDefault><w:pPrDefault><w:pPr><w:spacing w:after="100" w:line="264" w:lineRule="auto"/><w:jc w:val="both"/></w:pPr></w:pPrDefault></w:docDefaults><w:style w:type="paragraph" w:default="1" w:styleId="Normal"><w:name w:val="Normal"/></w:style><w:style w:type="paragraph" w:styleId="Heading1"><w:name w:val="heading 1"/><w:basedOn w:val="Normal"/><w:pPr><w:keepNext/><w:keepLines/><w:spacing w:before="140" w:after="160"/><w:jc w:val="left"/><w:outlineLvl w:val="0"/></w:pPr><w:rPr><w:b/><w:sz w:val="28"/></w:rPr></w:style></w:styles>'''
footer='<?xml version="1.0" encoding="UTF-8" standalone="yes"?><w:ftr '+ns+'><w:p><w:pPr><w:jc w:val="center"/></w:pPr><w:r><w:fldChar w:fldCharType="begin"/></w:r><w:r><w:instrText xml:space="preserve"> PAGE </w:instrText></w:r><w:r><w:fldChar w:fldCharType="end"/></w:r></w:p></w:ftr>'
contenttypes='''<?xml version="1.0" encoding="UTF-8"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/><Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/><Override PartName="/word/footer1.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.footer+xml"/><Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/></Types>'''
rootrels='''<?xml version="1.0" encoding="UTF-8"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/><Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/></Relationships>'''
rels='''<?xml version="1.0" encoding="UTF-8"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rIdStyles" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/><Relationship Id="rIdFooter" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/footer" Target="footer1.xml"/></Relationships>'''
core='''<?xml version="1.0" encoding="UTF-8"?><cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/"><dc:title>SOYLE — Практикалық жұмыс №4</dc:title><dc:subject>Локалды деректер қоры және жеке оқу жазбалары</dc:subject><dc:language>kk-KZ</dc:language></cp:coreProperties>'''
with ZipFile(OUT,'w',ZIP_DEFLATED) as archive:
    for name,data in {'[Content_Types].xml':contenttypes,'_rels/.rels':rootrels,'word/document.xml':document,'word/styles.xml':styles,'word/_rels/document.xml.rels':rels,'word/footer1.xml':footer,'docProps/core.xml':core}.items(): archive.writestr(name,data.encode('utf-8'))
# Validate every XML part and package integrity; the file is an editable DOCX.
from xml.etree import ElementTree
with ZipFile(OUT) as archive:
    assert archive.testzip() is None
    for name in archive.namelist(): ElementTree.fromstring(archive.read(name))
    tree=ElementTree.fromstring(archive.read('word/document.xml'))
    assert len(tree.findall('.//{http://schemas.openxmlformats.org/wordprocessingml/2006/main}tbl'))==4
print(f'Created: {OUT}\nSize: {OUT.stat().st_size} bytes; XML and DOCX package validated.')
