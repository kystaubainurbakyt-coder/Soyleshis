# SOYLE — локалды деректер моделі

Қолданылатын технология: Hive CE (`hive_ce`, `hive_ce_flutter`). Flutter іске қосылғанда `LearningRepository.openFlutter()` алты коллекцияны ашады. Деректер адаптер генерациясын қажет етпейтін Map/List/String/int/bool түрінде сериализацияланады. Мобильді нұсқада файлдар қолданбаның documents каталогында, вебте браузердің IndexedDB қорында сақталады.

| Entity | Идентификатор және өрістер | Байланыс |
|---|---|---|
| LearnerRecord | id: String (email), name: String, learningData: Map | Бір пайдаланушының жазбалары, таңдаулылары және нәтижелері |
| CourseRecord | id: String (A1–C1), position: int | Бір деңгейде бірнеше сабақ |
| Lesson | id: int, level: String, title/titleRu/titleEn: String, ruleRu/ruleEn: String, minutes: int, words: List | level → CourseRecord.id; сөз тіркестері сабақтың ішіне енгізілген |
| StudyNote | id: String (кездейсоқ 128-bit), ownerId: String, lessonId: int, title/body: String, priority: int (1–3), favorite: bool, createdAt/updatedAt: DateTime | ownerId → LearnerRecord.id, lessonId → Lesson.id |
| FavoriteRecord | id: String (owner/lesson), ownerId: String, lessonId: int | Пайдаланушы мен таңдалған сабақ |
| LessonProgressRecord | id: String (owner/lesson), ownerId: String, lessonId: int, score: int, completed: bool | Пайдаланушының сабақ нәтижесі |

Hive коллекциялары: `soyle_v4_learners`, `courses`, `lessons`, `notes`, `favorites`, `progress` (соңғы бесеуінде де `soyle_v4_` префиксі бар). Құрама сақтау кілттері SHA-256 арқылы тұрақты ұзындыққа келтіріледі. Кілт хэші авторизацияны алмастырмайды: жеке жазбаға сұраулар ownerId бойынша шектеледі.

Сабақтар бекітілген каталогтан толтырылады. Оқушы сабақтарды өңдемейді. CRUD әрекеттері жеке оқу жазбаларына қолданылады: профильдегі «Мои заметки / My notebook» және сабақтағы «Заметки к уроку / Lesson notes». Бос міндетті өрістер тексеріледі; жою растауды талап етеді. Іздеу атау мен мәтін бойынша, сүзгі деңгей/сабақ/таңдаулы бойынша, сұрыптау атау/өзгертілген уақыт/маңыздылық бойынша орындалады.

Алдыңғы secure storage прогресі мен таңдаулылар Hive профилі әлі жоқ кезде көшіріледі. Құпиясөз хэштері secure storage ішінде қалады. Пайдаланушының оқу күйі Hive арқылы сақталып, қайта кіруде сол жерден оқылады. Қор қатесі бос тізім ретінде жасырылмайды: хабарлама және қайталау мүмкіндігі көрсетіледі.

`learning_repository_test.dart` нақты уақытша Hive файлдарымен CRUD, байланыстар, үш сұрыптау, аралас сүзгілер, аккаунттардың оқшаулануы, қате өңдеу, миграция және қорды жауып-қайта ашқандағы сақталуды тексереді. Бұл операциялар желілік сұраусыз орындалады. Физикалық телефондағы ұшақ режимі осы ортада тексерілмеді.
