import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppLocale extends ChangeNotifier {
  static final instance = AppLocale();
  static const _key = 'soyle.interface.language';
  String _language = 'ru';
  String get language => _language;
  bool get isEnglish => _language == 'en';
  Future<void> initialize() async {
    try {
      final saved = await const FlutterSecureStorage().read(key: _key);
      if (saved == 'en' || saved == 'ru') _language = saved!;
    } catch (_) {
      /* The interface remains usable when storage is unavailable. */
    }
  }

  Future<void> setLanguage(String language) async {
    if (!['ru', 'en'].contains(language) || language == _language) return;
    _language = language;
    notifyListeners();
    try {
      await const FlutterSecureStorage().write(key: _key, value: language);
    } catch (_) {
      /* Keep the selected language for this session. */
    }
  }
}

String tr(String key, [Map<String, Object> values = const {}]) {
  final pair = messages[key];
  assert(pair != null, 'Missing interface translation: $key');
  var text = pair == null ? key : pair[AppLocale.instance.isEnglish ? 1 : 0];
  if (key == 'days' && values['n'] == 1 && AppLocale.instance.isEnglish) {
    text = text.replaceAll('days', 'day');
  }
  if ((key == 'lessonsCount' || key == 'courseMore') && values['n'] is int) {
    final n = values['n'] as int;
    text = text.replaceAll(
      AppLocale.instance.isEnglish ? 'lessons' : 'уроков',
      lessonNoun(n, AppLocale.instance.isEnglish),
    );
  }
  for (final entry in values.entries) {
    text = text.replaceAll('{${entry.key}}', '${entry.value}');
  }
  return text;
}

String lessonNoun(int count, bool english) {
  if (english) return count == 1 ? 'lesson' : 'lessons';
  final n = count.abs();
  if (n % 100 >= 11 && n % 100 <= 14) return 'уроков';
  if (n % 10 == 1) return 'урок';
  if (n % 10 >= 2 && n % 10 <= 4) return 'урока';
  return 'уроков';
}

String bilingual(String ru, String en) =>
    AppLocale.instance.isEnglish ? en : ru;

const messages = <String, List<String>>{
  'studyRoom': ['Учебный чат', 'Study room'],
  'chatWelcome': [
    'Общайтесь об уроках с другими учениками. Новые сообщения появляются сразу.',
    'Discuss lessons with other learners. New messages appear instantly.',
  ],
  'chatConnecting': ['Подключение…', 'Connecting…'],
  'chatOnline': ['В сети', 'Online'],
  'chatOffline': ['Чат не подключён', 'Chat is offline'],
  'chatReconnectHint': [
    'Проверьте, что локальный сервер SOYLE запущен. Приложение подключится снова автоматически.',
    'Check that the local SOYLE server is running. The app will reconnect automatically.',
  ],
  'chatInputHint': ['Напишите сообщение…', 'Write a message…'],
  'chatSend': ['Отправить сообщение', 'Send message'],
  'chatSendError': [
    'Не удалось отправить сообщение. Попробуйте ещё раз.',
    'Message was not sent. Try again.',
  ],
  'chatDataError': [
    'Не удалось прочитать сообщение сервера.',
    'Could not read a server message.',
  ],
  'chatConnectionError': [
    'Не удалось подключиться к учебному чату.',
    'Could not connect to the study room.',
  ],
  'invalidChatMessage': [
    'Введите сообщение длиной не более 500 символов.',
    'Enter a message of at most 500 characters.',
  ],
  'adminAnnouncement': ['Объявление SOYLE', 'SOYLE announcement'],
  'nameTooShort': [
    'Имя должно содержать не менее 2 символов',
    'Your name must contain at least 2 characters',
  ],
  'emailRequired': [
    'Введите адрес электронной почты',
    'Enter your email address',
  ],
  'emailInvalid': [
    'Введите корректный адрес, например name@gmail.com',
    'Enter a valid address, such as name@gmail.com',
  ],
  'passwordTooShort': [
    'Пароль должен содержать не менее 6 символов',
    'Your password must contain at least 6 characters',
  ],
  'passwordTooLong': [
    'Пароль должен содержать не более 128 символов',
    'Your password must contain no more than 128 characters',
  ],
  'passwordNeedsUppercase': [
    'Добавьте хотя бы одну заглавную букву',
    'Include at least one uppercase letter',
  ],
  'passwordHasSpaces': [
    'Пароль не должен содержать пробелы',
    'Your password must not contain spaces',
  ],
  'pleaseWait': ['Пожалуйста, подождите', 'Please wait'],
  'emailAlreadyRegistered': [
    'Этот адрес уже зарегистрирован. Войдите в аккаунт.',
    'This email is already registered. Please sign in.',
  ],
  'tooManyLoginAttempts': [
    'Слишком много попыток. Повторите через 30 секунд.',
    'Too many attempts. Please try again in 30 seconds.',
  ],
  'invalidCredentials': [
    'Неверная почта или пароль. Если вы ещё не зарегистрированы, создайте аккаунт.',
    'Incorrect email or password. If you have not registered yet, create an account first.',
  ],
  'scanLessonQr': ['Сканировать QR-код урока', 'Scan a lesson QR code'],
  'scanLessonQrHint': [
    'Наведите камеру на QR-код SOYLE вида soyle://lesson/ID, чтобы открыть урок.',
    'Point the camera at a SOYLE QR code like soyle://lesson/ID to open a lesson.',
  ],
  'invalidLessonQr': [
    'QR-кодта жарамды сабақ жоқ.',
    'This QR code does not contain a valid lesson.',
  ],
  'cameraPermissionDenied': [
    'Камераға рұқсат берілмеді. Рұқсатты құрылғы баптауынан қосып, қайта көріңіз.',
    'Camera permission was denied. Enable it in device settings and try again.',
  ],
  'cameraUnavailable': [
    'Камера қолжетімсіз. Құрылғыны тексеріп, қайта көріңіз.',
    'Camera is unavailable. Check the device and try again.',
  ],
  'home': ['Главная', 'Home'],
  'courses': ['Курсы', 'Courses'],
  'search': ['Поиск', 'Search'],
  'saved': ['Избранное', 'Favorites'],
  'profile': ['Профиль', 'Profile'],
  'settings': ['Настройки', 'Settings'],
  'login': ['Войти', 'Sign in'],
  'register': ['Создать аккаунт', 'Create account'],
  'email': ['Электронная почта', 'Email address'],
  'password': ['Пароль', 'Password'],
  'name': ['Имя', 'Name'],
  'confirmPassword': ['Повторите пароль', 'Confirm password'],
  'passwordHint': [
    'От 6 символов, хотя бы одна заглавная буква',
    'At least 6 characters and one uppercase letter',
  ],
  'welcome': ['Рады видеть вас снова', 'Welcome back'],
  'join': ['Ваш казахский начинается здесь', 'Your Kazakh journey starts here'],
  'loginIntro': [
    'Продолжите с того места, где остановились.',
    'Pick up where you left off.',
  ],
  'registerIntro': [
    'Учитесь в своём темпе. Сохраняйте каждый результат.',
    'Learn at your own pace. Keep every achievement.',
  ],
  'noAccount': [
    'Ещё нет аккаунта? Зарегистрироваться',
    'New here? Create an account',
  ],
  'haveAccount': [
    'Уже есть аккаунт? Войти',
    'Already have an account? Sign in',
  ],
  'showPassword': ['Показать пароль', 'Show password'],
  'hidePassword': ['Скрыть пароль', 'Hide password'],
  'intro': ['Как устроено обучение', 'How learning works'],
  'next': ['Далее', 'Continue'],
  'back': ['Назад', 'Back'],
  'skip': ['Пропустить', 'Skip'],
  'start': ['Начать обучение', 'Start learning'],
  'continue': ['Продолжить', 'Continue learning'],
  'greeting': ['Здравствуйте, {name}', 'Hello, {name}'],
  'heroTitle': ['Говорите\nпо-казахски.', 'Speak\nKazakh.'],
  'heroSubtitle': [
    'Понятные объяснения и практика для реальной жизни. От A1 до C1.',
    'Clear explanations and real-world practice. From A1 to C1.',
  ],
  'yourCourse': ['ВАШ СЛЕДУЮЩИЙ УРОК', 'YOUR NEXT LESSON'],
  'level': ['Уровень', 'Level'],
  'allLevels': ['Все уровни', 'All levels'],
  'lessonsCount': ['{n} уроков', '{n} lessons'],
  'minutes': ['{n} мин', '{n} min'],
  'progress': ['Ваш прогресс', 'Your progress'],
  'completed': ['Завершено', 'Completed'],
  'completedCount': [
    'Завершено: {done} из {total}',
    '{done} of {total} completed',
  ],
  'dailyGoal': ['Цель на сегодня', 'Today’s goal'],
  'goalDone': [
    'Цель достигнута. Отличная работа!',
    'Daily goal reached. Well done!',
  ],
  'goalHint': [
    'Новый пройденный урок — 100 XP.',
    'Complete a new lesson to earn 100 XP.',
  ],
  'totalXp': ['Всего XP', 'Total XP'],
  'streak': ['Серия дней', 'Day streak'],
  'days': ['{n} дн.', '{n} days'],
  'rank': ['Ступень {n}', 'Rank {n}'],
  'rank0': ['Начало пути', 'Getting started'],
  'rank1': ['Исследователь', 'Explorer'],
  'rank2': ['Знаток слов', 'Wordsmith'],
  'rank3': ['Увлечённый ученик', 'Dedicated learner'],
  'explore': ['Программа обучения', 'Explore the curriculum'],
  'allCourses': ['Все курсы', 'All courses'],
  'review': ['Повторение слов', 'Vocabulary review'],
  'reviewHint': [
    'Карточки по изученным и сохранённым урокам',
    'Flashcards from completed and saved lessons',
  ],
  'achievements': ['Достижения', 'Achievements'],
  'certificates': ['Сертификаты', 'Certificates'],
  'achievementsHint': [
    'Ваши навыки, значки и сертификаты',
    'Your skills, badges and certificates',
  ],
  'journey': ['Мой учебный путь', 'My learning path'],
  'journeyHint': [
    'Каждый урок приближает к свободной речи.',
    'Every lesson brings you closer to confident speech.',
  ],
  'curriculumHint': [
    'Каждый курс включает объяснения, диалоги и упражнения. Для завершения урока нужно набрать не менее 70%.',
    'Each course includes explanations, dialogues and exercises. Score at least 70% to complete a lesson.',
  ],
  'A1': ['Первые шаги', 'First steps'],
  'A2': ['Повседневная речь', 'Everyday conversations'],
  'B1': ['Самостоятельное общение', 'Independent communication'],
  'B2': ['Уверенная речь', 'Confident expression'],
  'C1': ['Точность и глубина', 'Precision and depth'],
  'wordOfDay': ['Фраза дня', 'Phrase of the day'],
  'dailyPractice': ['Практика на сегодня', 'Today’s speaking practice'],
  'dailyPracticeTip': [
    'Короткая фраза для повседневного общения. Потратьте на неё пять минут.',
    'A useful everyday phrase. Spend five minutes practising it.',
  ],
  'dailyStep1': [
    'Прочитайте фразу вслух три раза.',
    'Read the phrase aloud three times.',
  ],
  'dailyStep2': [
    'Закройте перевод и вспомните значение.',
    'Hide the translation and recall its meaning.',
  ],
  'dailyStep3': [
    'Замените одно слово своим вариантом.',
    'Replace one word with your own example.',
  ],
  'dailyOpenLesson': ['Открыть урок', 'Open the lesson'],
  'searchHint': ['Тема, слово или перевод', 'Topic, word or translation'],
  'noResults': ['Ничего не найдено', 'No results found'],
  'searchAgain': [
    'Попробуйте другой запрос или уровень.',
    'Try a different search term or level.',
  ],
  'noSaved': ['Сохраните то, что важно', 'Keep what matters'],
  'noSavedHint': [
    'Нажмите на закладку в уроке, чтобы вернуться к нему позже.',
    'Tap the bookmark in a lesson to come back to it later.',
  ],
  'saveLesson': ['Сохранить урок', 'Save lesson'],
  'unsaveLesson': ['Убрать из избранного', 'Remove from saved'],
  'overview': ['Объяснение', 'Overview'],
  'vocabulary': ['Фразы', 'Phrases'],
  'dialogue': ['Диалог', 'Dialogue'],
  'practice': ['Практика', 'Practice'],
  'grammar': ['Разбираем по шагам', 'Understand the pattern'],
  'examples': ['Примеры в контексте', 'Examples in context'],
  'reading': ['Читаем и понимаем', 'Read and understand'],
  'translation': ['Перевод', 'Translation'],
  'showTranslation': ['Показать перевод', 'Show translation'],
  'hideTranslation': ['Скрыть перевод', 'Hide translation'],
  'vocabHint': [
    'Прочитайте фразу вслух. Закройте перевод и вспомните значение.',
    'Read each phrase aloud. Hide the translation and recall the meaning.',
  ],
  'dialogueHint': [
    'Прочитайте диалог по ролям. Затем повторите его, не глядя на перевод.',
    'Read both roles aloud. Then repeat the dialogue without looking at the translation.',
  ],
  'independent': ['Самостоятельная работа', 'Independent practice'],
  'speakTask': [
    'Повторите фразы вслух, заменяя имена, места и детали своими.',
    'Say the phrases aloud, replacing names, places and details with your own.',
  ],
  'writeTask': [
    'Напишите свой короткий диалог по теме: не менее шести реплик.',
    'Write your own dialogue on this topic with at least six lines.',
  ],
  'recallTask': [
    'Вернитесь к уроку завтра и попробуйте восстановить диалог по памяти.',
    'Come back tomorrow and try to recall the dialogue from memory.',
  ],
  'goPractice': ['Проверить себя', 'Test yourself'],
  'bestScore': ['Лучший результат: {n}%', 'Best score: {n}%'],
  'questionCount': ['Вопрос {n} из {total}', 'Question {n} of {total}'],
  'chooseTranslation': [
    'Выберите перевод фразы «{phrase}».',
    'Choose the translation of “{phrase}”.',
  ],
  'chooseKazakh': [
    'Как сказать по-казахски: «{phrase}»?',
    'How do you say “{phrase}” in Kazakh?',
  ],
  'correct': ['Верно!', 'Correct!'],
  'incorrect': [
    'Пока не совсем. Посмотрите объяснение.',
    'Not quite. Take a look at the explanation.',
  ],
  'nextQuestion': ['Следующий вопрос', 'Next question'],
  'seeResults': ['Посмотреть результат', 'See results'],
  'lessonComplete': ['Ещё один шаг вперёд!', 'One more step forward!'],
  'tryAgain': ['Давайте попробуем ещё раз', 'Let’s try again'],
  'taskGap': [
    'Заполните пропуск: {phrase}\nПодсказка: {hint}',
    'Fill the gap: {phrase}\nHint: {hint}',
  ],
  'taskDialogue': [
    'Продолжите диалог: «{phrase}»\nНамерение ответа: {hint}',
    'Continue the dialogue: “{phrase}”\nReply intention: {hint}',
  ],
  'taskOrder': [
    'Восстановите порядок слов: {phrase}',
    'Restore the word order: {phrase}',
  ],
  'meaning': ['Понимание', 'Comprehension'],
  'grammarSkill': ['Пропущенное слово', 'Missing word'],
  'dialogueSkill': ['Общение', 'Conversation'],
  'syntaxSkill': ['Порядок слов', 'Word order'],
  'skillsReport': ['Ваши навыки', 'Your skills'],
  'startChallenge': ['Начать тренировку', 'Start practice'],
  'challengeIntro': [
    '8 заданий: понимание, пропуски, диалоги и порядок слов. Таймер продолжает идти при переключении вкладки. Выход потребует подтверждения.',
    '8 tasks: comprehension, missing words, dialogues and word order. The timer keeps running when you switch tabs. Leaving requires confirmation.',
  ],
  'timeLeft': ['Осталось {time}', '{time} remaining'],
  'timeExpired': [
    'Время вышло. Неотвеченные задания засчитаны как ошибки.',
    'Time is up. Unanswered tasks count as incorrect.',
  ],
  'unanswered': ['Нет ответа', 'No answer'],
  'leavePractice': ['Прервать тренировку?', 'Leave practice?'],
  'leavePracticeHint': [
    'Текущая попытка не будет сохранена. Лучше закончить задания и получить результат.',
    'This attempt will not be saved. Finish the tasks to record your result.',
  ],
  'stayPractice': ['Продолжить', 'Keep learning'],
  'leaveNow': ['Выйти', 'Leave'],
  'notebook': ['Мои заметки', 'My notebook'],
  'notebookIntro': [
    'Личные записи к урокам, доступные офлайн',
    'Personal lesson notes, available offline',
  ],
  'lessonNotes': ['Заметки к уроку', 'Lesson notes'],
  'addNote': ['Добавить заметку', 'Add a note'],
  'editNote': ['Изменить заметку', 'Edit note'],
  'noteTitle': ['Название', 'Title'],
  'noteBody': ['Моя запись', 'My note'],
  'noteTitleError': ['Введите от 3 до 80 символов', 'Enter 3–80 characters'],
  'noteBodyError': ['Введите от 1 до 2000 символов', 'Enter 1–2000 characters'],
  'noteLesson': ['Урок', 'Lesson'],
  'notePriority': ['Важность', 'Priority'],
  'priority1': ['Обычная', 'Normal'],
  'priority2': ['Важная', 'Important'],
  'priority3': ['Повторить в первую очередь', 'Review first'],
  'notesEmpty': ['Заметок пока нет', 'No notes yet'],
  'notesEmptyHint': [
    'Сохраните пример или вопрос к уроку. Запись останется на этом устройстве.',
    'Save an example or question about a lesson. It stays on this device.',
  ],
  'notesSearch': ['Поиск по названию и тексту', 'Search title and text'],
  'sortUpdated': ['Сначала новые изменения', 'Recently updated'],
  'sortTitle': ['По названию', 'By title'],
  'sortPriority': ['По важности', 'By priority'],
  'onlyFavorites': ['Только избранное', 'Favorites only'],
  'deleteNote': ['Удалить заметку?', 'Delete this note?'],
  'deleteNoteHint': ['Удаление нельзя отменить.', 'This cannot be undone.'],
  'noteSaved': ['Заметка сохранена на устройстве', 'Note saved on this device'],
  'databaseError': [
    'Не удалось открыть или сохранить локальные данные. Проверьте свободное место и повторите попытку.',
    'Could not open or save local data. Check available storage and try again.',
  ],
  'restApi': ['Практика REST API', 'REST API practice'],
  'apiEndpoints': [
    'GET оқу · POST қосу · PUT өзгерту · DELETE өшіру. Сервер жазбаларды демо үшін ғана қабылдайды; өзгерістер осы құрылғыда Hive арқылы сақталады.',
    'GET load · POST create · PUT update · DELETE remove. The demo server simulates writes; changes are kept on this device in Hive.',
  ],
  'apiRefresh': ['Серверден жаңарту', 'Refresh from server'],
  'apiAdd': ['Серверге жазба қосу', 'Add server post'],
  'apiLoaded': ['GET сәтті орындалды', 'GET completed successfully'],
  'apiCreated': ['POST сәтті орындалды', 'POST completed successfully'],
  'apiUpdated': ['PUT сәтті орындалды', 'PUT completed successfully'],
  'apiDeleted': ['DELETE сәтті орындалды', 'DELETE completed successfully'],
  'apiDeleteTitle': ['Сервер жазбасын өшіру керек пе?', 'Delete server post?'],
  'apiLocalAccount': ['жергілікті аккаунт кэші', 'local account cache'],
  'apiOffline': [
    'Интернет жоқ. Жергілікті сақталған жазбалар көрсетілді.',
    'You are offline. Showing locally cached posts.',
  ],
  'apiTimeout': [
    'Сервер 10 секунд ішінде жауап бермеді. Қайталап көріңіз.',
    'The server did not respond within 10 seconds. Try again.',
  ],
  'apiServerError': [
    'Сервер қатесі. Жергілікті деректер сақталды.',
    'Server error. Local data was preserved.',
  ],
  'apiBadData': [
    'Серверден келген деректерді оқу мүмкін болмады.',
    'The server returned data in an unexpected format.',
  ],
  'apiRequestError': [
    'Сұрауды орындау мүмкін болмады. Қайталап көріңіз.',
    'The request failed. Please try again.',
  ],
  'apiEmpty': ['Серверде әзірге жазба жоқ.', 'No server posts yet.'],
  'apiRequired': ['Бұл өрісті толтырыңыз.', 'This field is required.'],
  'apiRetry': ['Қайталау', 'Retry'],
  'loading': ['Жүктелуде…', 'Loading…'],
  'offlineReady': ['Доступно без интернета', 'Available offline'],
  'noteDelete': ['Удалить', 'Delete'],
  'noteCancel': ['Отмена', 'Cancel'],
  'noteSave': ['Сохранить', 'Save'],
  'adminLogin': ['Вход администратора', 'Administrator sign in'],
  'adminUnavailable': [
    'Не удалось открыть панель. Запустите локальный сервер администратора.',
    'Could not open the panel. Start the local admin server.',
  ],
  'levelLocked': [
    'Следующий уровень откроется после завершения всех уроков предыдущего уровня с результатом от 70%.',
    'Complete every lesson in the previous level with at least 70% to unlock the next level.',
  ],
  'certificateThreshold': [
    'Для сертификата завершите все уроки уровня. Средний результат должен быть не ниже 85%.',
    'Complete every lesson in this level with an average score of at least 85% to earn a certificate.',
  ],
  'passHint': [
    'Для завершения урока нужно не менее 70% правильных ответов.',
    'You need at least 70% correct answers to complete this lesson.',
  ],
  'result': [
    'Верно: {correct} из {total} · {percent}%',
    '{correct} of {total} correct · {percent}%',
  ],
  'earnedXp': ['+{n} XP за новый результат', '+{n} XP for a new milestone'],
  'retry': ['Повторить упражнение', 'Try the exercise again'],
  'yourAnswer': ['Ваш ответ: {answer}', 'Your answer: {answer}'],
  'reviewTitle': [
    'Помните больше.\nГоворите увереннее.',
    'Remember more.\nSpeak with confidence.',
  ],
  'reviewInstructions': [
    'Сначала вспомните перевод, затем откройте карточку. Сложные фразы встретятся ещё раз.',
    'Try to recall the translation before revealing it. Difficult phrases will come back for another try.',
  ],
  'mastered': ['Запомнили: {done} из {total}', '{done} of {total} recalled'],
  'kazakh': ['КАЗАХСКИЙ', 'KAZAKH'],
  'tapReveal': [
    'Нажмите, чтобы открыть перевод',
    'Tap to reveal the translation',
  ],
  'know': ['Помню', 'I remember'],
  'again': ['Повторить позже', 'Show again'],
  'reviewDone': ['Отличная тренировка!', 'Great practice!'],
  'reviewResult': [
    'Повторено: {n} · +{xp} XP',
    '{n} phrases reviewed · +{xp} XP',
  ],
  'bonusClaimed': [
    'Сегодняшний бонус уже получен. Повторять можно сколько угодно.',
    'You have already earned today’s bonus. You can keep practising as often as you like.',
  ],
  'bonusEarned': [
    'Бонус за сегодняшнее повторение получен.',
    'You have earned today’s review bonus.',
  ],
  'done': ['Готово', 'Done'],
  'badgeEarned': ['Получен', 'Earned'],
  'badgeLocked': ['Впереди', 'Still to come'],
  'badges': ['Значки', 'Badges'],
  'badgeFirst': ['Первый шаг', 'First step'],
  'badgeFirstHint': ['Завершите первый урок', 'Complete your first lesson'],
  'badgePerfect': ['Точно в цель', 'Right on target'],
  'badgePerfectHint': [
    'Наберите 100% в упражнении',
    'Score 100% in an exercise',
  ],
  'badgeCollector': ['Своя коллекция', 'Your collection'],
  'badgeCollectorHint': ['Сохраните три урока', 'Save three lessons'],
  'badgeStreak': ['Постоянство', 'Consistency'],
  'badgeStreakHint': ['Учитесь три дня подряд', 'Learn three days in a row'],
  'certificate': ['Сертификат', 'Certificate'],
  'myCertificate': ['Мой сертификат', 'My certificate'],
  'certificateLocked': [
    'Ваш результат\nполучит признание.',
    'Your progress\ndeserves recognition.',
  ],
  'certificateRequirements': [
    'Завершите все уроки курса {level} со средним результатом от 85%. Сертификат появится автоматически.',
    'Complete every lesson in the {level} course with an average score of at least 85%. Your certificate will be issued automatically.',
  ],
  'certificateReady': ['Ваш сертификат готов', 'Your certificate is ready'],
  'certificateCongrats': [
    'Вы завершили курс.\nЭто ваше достижение.',
    'You completed the course.\nThis is your achievement.',
  ],
  'certificateSubtitle': [
    'Сохраните подтверждение пройденного пути.',
    'Keep a record of the journey you have completed.',
  ],
  'downloadPdf': ['Скачать PDF', 'Download PDF'],
  'courseCertificate': ['Сертификат курса SOYLE', 'SOYLE course certificate'],
  'certCompletion': [
    'успешно завершил(а) учебный курс казахского языка',
    'has successfully completed the Kazakh language course',
  ],
  'issued': ['Дата выдачи', 'Issued on'],
  'average': ['Средний результат', 'Average score'],
  'certNote': [
    'Внутренний сертификат курса SOYLE',
    'An internal SOYLE course certificate',
  ],
  'certNumber': ['Номер сертификата', 'Certificate number'],
  'pdfError': [
    'Не удалось сохранить PDF. Попробуйте ещё раз.',
    'Could not save the PDF. Please try again.',
  ],
  'courseMore': [
    'До сертификата: {n} уроков',
    '{n} lessons to your certificate',
  ],
  'openCertificate': ['Открыть сертификат', 'View certificate'],
  'editName': ['Ваше имя', 'Your name'],
  'save': ['Сохранить', 'Save changes'],
  'language': ['Язык интерфейса', 'Interface language'],
  'languageHint': [
    'Объяснения и переводы будут на выбранном языке.',
    'Explanations and translations follow your chosen language.',
  ],
  'learningOnly': [
    'Ваше пространство для изучения казахского',
    'Your space to learn Kazakh',
  ],
  'logout': ['Выйти из аккаунта', 'Sign out'],
  'completedLessons': ['Завершённые уроки', 'Completed lessons'],
  'localAccount': [
    'Учебные результаты сохраняются на этом устройстве.',
    'Your learning progress is saved on this device.',
  ],
  'nameSaved': ['Изменения сохранены', 'Changes saved'],
  'readOnly': [
    'Этот раздел доступен только редактору курса.',
    'This section is reserved for the course editor.',
  ],
  'notFound': ['Страница не найдена', 'Page not found'],
  'onboard1': ['Понимайте, а не угадывайте', 'Understand, don’t just guess'],
  'onboard1Hint': [
    'Объяснения на вашем языке. Казахские фразы с понятным переводом.',
    'Explanations in your language. Kazakh phrases with clear translations.',
  ],
  'onboard2': ['Учитесь для реальной жизни', 'Learn for real life'],
  'onboard2Hint': [
    'От знакомства и покупок до работы, дискуссий и сложных текстов.',
    'From introductions and shopping to work, discussions and complex texts.',
  ],
  'onboard3': ['Замечайте свой прогресс', 'See how far you have come'],
  'onboard3Hint': [
    'Возвращайтесь к трудным темам и получайте сертификат за завершённый курс.',
    'Revisit difficult topics and earn a certificate for each completed course.',
  ],
  'Email енгізіңіз': ['Введите электронную почту', 'Enter your email address'],
  'Email қате. Мысалы: name@gmail.com': [
    'Введите корректный адрес, например name@gmail.com',
    'Enter a valid address, such as name@gmail.com',
  ],
  'Құпиясөз кемінде 6 таңба болуы керек': [
    'Пароль должен содержать не менее 6 символов',
    'Your password must contain at least 6 characters',
  ],
  'Құпиясөз 128 таңбадан аспауы керек': [
    'Пароль должен содержать не более 128 символов',
    'Your password must contain no more than 128 characters',
  ],
  'Кемінде бір үлкен әріп қосыңыз': [
    'Добавьте хотя бы одну заглавную букву',
    'Include at least one uppercase letter',
  ],
  'Құпиясөзде бос орын болмауы керек': [
    'В пароле не должно быть пробелов',
    'Your password must not contain spaces',
  ],
  'Өтініш, күтіңіз': ['Пожалуйста, подождите', 'Please wait'],
  'Атыңыз кемінде 2 таңба болсын': [
    'Имя должно содержать не менее 2 символов',
    'Your name must contain at least 2 characters',
  ],
  'Атыңызды енгізіңіз': ['Введите имя', 'Enter your name'],
  'Бұл email тіркелген. Кіру бетін пайдаланыңыз.': [
    'Этот адрес уже зарегистрирован. Войдите в аккаунт.',
    'This email is already registered. Please sign in.',
  ],
  'Тым көп қате әрекет. 30 секундтан кейін қайталаңыз.': [
    'Слишком много попыток. Повторите через 30 секунд.',
    'Too many attempts. Please try again in 30 seconds.',
  ],
  'Email немесе құпиясөз қате': [
    'Неверная почта или пароль',
    'Incorrect email or password',
  ],
  'Email немесе құпиясөз қате. Тіркелмесеңіз, алдымен аккаунт құрыңыз.': [
    'Неверная почта или пароль. Если вы ещё не зарегистрированы, создайте аккаунт.',
    'Incorrect email or password. If you have not registered yet, create an account first.',
  ],
  'passwordMismatch': ['Пароли не совпадают', 'Passwords do not match'],
  'storageError': [
    'Не удалось сохранить данные. Проверьте доступ к хранилищу устройства.',
    'Could not save your data. Check access to your device storage.',
  ],
  'authError': [
    'Не удалось войти. Попробуйте ещё раз.',
    'Could not sign in. Please try again.',
  ],
  'sentenceBuilder': ['Конструктор фраз', 'Sentence builder'],
  'sentenceHint': [
    'Соберите казахскую фразу по переводу. Нажмите на слова в правильном порядке.',
    'Build the Kazakh sentence from its translation. Tap the words in the correct order.',
  ],
  'checkSentence': ['Проверить фразу', 'Check the sentence'],
};
