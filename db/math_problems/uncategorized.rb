def seed_uncategorized_questions
  questions = [
    {
      text: "В градината на баба Ани цъфнали 18 рози, от които 5 жълти, а останалите червени. Колко червени рози е откъснала малката Ани, ако след това в градината останали 8 червени рози?",
      answers: [ "10", "8", "5", "4", "3" ],
      correct_answer: "5",
      explanation: "Нека решим задачата стъпка по стъпка:\n1. Общо рози: 18\n2. Жълти рози: 5\n3. Червени рози първоначално: 18 - 5 = 13\n4. Останали червени рози: 8\n5. Откъснати червени рози: 13 - 8 = 5"
    },
    {
      text: "В класа на Петър има 25 ученика. 12 от тях са момчета, а останалите са момичета. Колко момичета има в класа?",
      answers: [ "13", "12", "14", "11", "15" ],
      correct_answer: "13",
      explanation: "За да намерим броя на момичетата:\n1. Общ брой ученици: 25\n2. Брой момчета: 12\n3. Брой момичета: 25 - 12 = 13"
    },
    {
      text: "В магазин имаше 30 ябълки. Продадени са 8 ябълки, а 5 са изгнили. Колко ябълки останаха в магазина?",
      answers: [ "17", "18", "16", "15", "19" ],
      correct_answer: "17",
      explanation: "Нека изчислим стъпка по стъпка:\n1. Начален брой ябълки: 30\n2. Продадени ябълки: 8\n3. Изгнили ябълки: 5\n4. Останали ябълки: 30 - 8 - 5 = 17"
    },
    {
      text: "Мария има 24 цветя в градината си. 9 от тях са рози, а останалите са лалета. Колко лалета има в градината?",
      answers: [ "15", "14", "16", "13", "17" ],
      correct_answer: "15",
      explanation: "За да намерим броя на лалетата:\n1. Общ брой цветя: 24\n2. Брой рози: 9\n3. Брой лалета: 24 - 9 = 15"
    },
    {
      text: "В парка имаше 20 птички. 7 отлетяха, а 3 се прибраха. Колко птички останаха в парка?",
      answers: [ "16", "15", "17", "14", "18" ],
      correct_answer: "16",
      explanation: "Нека изчислим:\n1. Начален брой птички: 20\n2. Отлетели птички: 7\n3. Прибрали се птички: 3\n4. Останали птички: 20 - 7 - 3 = 16"
    },
    {
      text: "В кутия имаше 16 бонбона. 6 са изядени, а 4 са дадени на приятели. Колко бонбона останаха в кутията?",
      answers: [ "6", "5", "7", "4", "8" ],
      correct_answer: "6",
      explanation: "Нека изчислим:\n1. Начален брой бонбони: 16\n2. Изядени бонбони: 6\n3. Дадени бонбони: 4\n4. Останали бонбони: 16 - 6 - 4 = 6"
    },
    {
      text: "В библиотеката имаше 35 книги. 12 са заети, а 8 са изгубени. Колко книги останаха в библиотеката?",
      answers: [ "15", "14", "16", "13", "17" ],
      correct_answer: "15",
      explanation: "Нека изчислим:\n1. Начален брой книги: 35\n2. Заети книги: 12\n3. Изгубени книги: 8\n4. Останали книги: 35 - 12 - 8 = 15"
    },
    {
      text: "В градината имаше 28 цветя. 10 са увяхнали, а 6 са откъснати. Колко цветя останаха в градината?",
      answers: [ "12", "11", "13", "10", "14" ],
      correct_answer: "12",
      explanation: "Нека изчислим:\n1. Начален брой цветя: 28\n2. Увяхнали цветя: 10\n3. Откъснати цветя: 6\n4. Останали цветя: 28 - 10 - 6 = 12"
    },
    {
      text: "В класа имаше 30 ученика. 8 са отсъстващи, а 5 са излезли за почивка. Колко ученика останаха в класа?",
      answers: [ "17", "16", "18", "15", "19" ],
      correct_answer: "17",
      explanation: "Нека изчислим:\n1. Начален брой ученици: 30\n2. Отсъстващи ученици: 8\n3. Излезли за почивка: 5\n4. Останали ученици: 30 - 8 - 5 = 17"
    },
    {
      text: "В магазин имаше 40 играчки. 15 са продадени, а 8 са повредени. Колко играчки останаха в магазина?",
      answers: [ "17", "16", "18", "15", "19" ],
      correct_answer: "17",
      explanation: "Нека изчислим:\n1. Начален брой играчки: 40\n2. Продадени играчки: 15\n3. Повредени играчки: 8\n4. Останали играчки: 40 - 15 - 8 = 17"
    },
    {
      text: "Асен, Боби, Вили и Гошо живеят в един вход. Асен живее на петия етаж. Боби живее 3 етажа над Асен. Вили живее 2 етажа под Боби. Гошо живее 4 етажа над Вили. На кой етаж живее Гошо?",
      answers: [ "на петия", "на седмия", "на деветия", "на десетия", "на четиринадесетия" ],
      correct_answer: "на десетия",
      explanation: "Нека проследим етажите стъпка по стъпка:\n1. Асен: 5-ти етаж\n2. Боби: 5 + 3 = 8-ми етаж\n3. Вили: 8 - 2 = 6-ти етаж\n4. Гошо: 6 + 4 = 10-ти етаж"
    },
    {
      text: "Петър, Иван, Мария и Стефан живеят в един вход. Петър живее на третия етаж. Иван живее 2 етажа над Петър. Мария живее 1 етаж под Иван. Стефан живее 3 етажа над Мария. На кой етаж живее Стефан?",
      answers: [ "на петия", "на шестия", "на седмия", "на осмия", "на деветия" ],
      correct_answer: "на седмия",
      explanation: "Нека проследим етажите стъпка по стъпка:\n1. Петър: 3-ти етаж\n2. Иван: 3 + 2 = 5-ти етаж\n3. Мария: 5 - 1 = 4-ти етаж\n4. Стефан: 4 + 3 = 7-ми етаж"
    },
    {
      text: "Георги, Димитър, Елена и Николай живеят в един вход. Георги живее на четвъртия етаж. Димитър живее 4 етажа над Георги. Елена живее 2 етажа под Димитър. Николай живее 1 етаж над Елена. На кой етаж живее Николай?",
      answers: [ "на петия", "на шестия", "на седмия", "на осмия", "на деветия" ],
      correct_answer: "на шестия",
      explanation: "Нека проследим етажите стъпка по стъпка:\n1. Георги: 4-ти етаж\n2. Димитър: 4 + 4 = 8-ми етаж\n3. Елена: 8 - 2 = 6-ти етаж\n4. Николай: 6 + 1 = 6-ти етаж"
    },
    {
      text: "Кристина, Лили, Мартин и Павел живеят в един вход. Кристина живее на втория етаж. Лили живее 3 етажа над Кристина. Мартин живее 1 етаж под Лили. Павел живее 2 етажа над Мартин. На кой етаж живее Павел?",
      answers: [ "на третия", "на четвъртия", "на петия", "на шестия", "на седмия" ],
      correct_answer: "на шестия",
      explanation: "Нека проследим етажите стъпка по стъпка:\n1. Кристина: 2-ри етаж\n2. Лили: 2 + 3 = 5-ти етаж\n3. Мартин: 5 - 1 = 4-ти етаж\n4. Павел: 4 + 2 = 6-ти етаж"
    },
    {
      text: "Ралица, Стефан, Тодор и Уляна живеят в един вход. Ралица живее на първия етаж. Стефан живее 5 етажа над Ралица. Тодор живее 2 етажа под Стефан. Уляна живее 3 етажа над Тодор. На кой етаж живее Уляна?",
      answers: [ "на четвъртия", "на петия", "на шестия", "на седмия", "на осмия" ],
      correct_answer: "на седмия",
      explanation: "Нека проследим етажите стъпка по стъпка:\n1. Ралица: 1-ви етаж\n2. Стефан: 1 + 5 = 6-ти етаж\n3. Тодор: 6 - 2 = 4-ти етаж\n4. Уляна: 4 + 3 = 7-ми етаж"
    },
    {
      text: "Христо, Яна, Златина и Борис живеят в един вход. Христо живее на шестия етаж. Яна живее 2 етажа под Христо. Златина живее 3 етажа над Яна. Борис живее 1 етаж под Златина. На кой етаж живее Борис?",
      answers: [ "на четвъртия", "на петия", "на шестия", "на седмия", "на осмия" ],
      correct_answer: "на четвъртия",
      explanation: "Нека проследим етажите стъпка по стъпка:\n1. Христо: 6-ти етаж\n2. Яна: 6 - 2 = 4-ти етаж\n3. Златина: 4 + 3 = 7-ми етаж\n4. Борис: 7 - 1 = 4-ти етаж"
    },
    {
      text: "Даниел, Емилия, Филип и Габриела живеят в един вход. Даниел живее на третия етаж. Емилия живее 4 етажа над Даниел. Филип живее 2 етажа под Емилия. Габриела живее 1 етаж над Филип. На кой етаж живее Габриела?",
      answers: [ "на четвъртия", "на петия", "на шестия", "на седмия", "на осмия" ],
      correct_answer: "на шестия",
      explanation: "Нека проследим етажите стъпка по стъпка:\n1. Даниел: 3-ти етаж\n2. Емилия: 3 + 4 = 7-ми етаж\n3. Филип: 7 - 2 = 5-ти етаж\n4. Габриела: 5 + 1 = 6-ти етаж"
    },
    {
      text: "Ивайло, Катя, Любомир и Милена живеят в един вход. Ивайло живее на петия етаж. Катя живее 3 етажа под Ивайло. Любомир живее 2 етажа над Катя. Милена живее 4 етажа над Любомир. На кой етаж живее Милена?",
      answers: [ "на четвъртия", "на петия", "на шестия", "на седмия", "на осмия" ],
      correct_answer: "на осмия",
      explanation: "Нека проследим етажите стъпка по стъпка:\n1. Ивайло: 5-ти етаж\n2. Катя: 5 - 3 = 2-ри етаж\n3. Любомир: 2 + 2 = 4-ти етаж\n4. Милена: 4 + 4 = 8-ми етаж"
    },
    {
      text: "Никола, Оля, Петър и Рая живеят в един вход. Никола живее на четвъртия етаж. Оля живее 2 етажа над Никола. Петър живее 3 етажа под Оля. Рая живее 1 етаж над Петър. На кой етаж живее Рая?",
      answers: [ "на третия", "на четвъртия", "на петия", "на шестия", "на седмия" ],
      correct_answer: "на третия",
      explanation: "Нека проследим етажите стъпка по стъпка:\n1. Никола: 4-ти етаж\n2. Оля: 4 + 2 = 6-ти етаж\n3. Петър: 6 - 3 = 3-ти етаж\n4. Рая: 3 + 1 = 3-ти етаж"
    },
    {
      text: "Светлана, Тома, Уляна и Васил живеят в един вход. Светлана живее на първия етаж. Тома живее 4 етажа над Светлана. Уляна живее 2 етажа под Тома. Васил живее 3 етажа над Уляна. На кой етаж живее Васил?",
      answers: [ "на третия", "на четвъртия", "на петия", "на шестия", "на седмия" ],
      correct_answer: "на шестия",
      explanation: "Нека проследим етажите стъпка по стъпка:\n1. Светлана: 1-ви етаж\n2. Тома: 1 + 4 = 5-ти етаж\n3. Уляна: 5 - 2 = 3-ти етаж\n4. Васил: 3 + 3 = 6-ти етаж"
    },
    {
      text: "Колко е 9 + 9?",
      answers: [],
      correct_answer: "18"
    },
    {
      text: "Колко е 9 + 8?",
      answers: [],
      correct_answer: "17"
    },
    {
      text: "Колко е 9 + 7?",
      answers: [],
      correct_answer: "16"
    },
    {
      text: "Колко е 9 + 6?",
      answers: [],
      correct_answer: "15"
    },
    {
      text: "Колко е 8 + 8?",
      answers: [],
      correct_answer: "16"
    },
    {
      text: "Колко е 8 + 7?",
      answers: [],
      correct_answer: "15"
    },
    {
      text: "Колко е 8 + 6?",
      answers: [],
      correct_answer: "14"
    },
    {
      text: "Колко е 7 + 7?",
      answers: [],
      correct_answer: "14"
    },
    {
      text: "Колко е 7 + 6?",
      answers: [],
      correct_answer: "13"
    },
    {
      text: "Колко е 6 + 6?",
      answers: [],
      correct_answer: "12"
    },
    {
      text: "Намерете липсващото число в редицата: 2, 5, 8, 11, ?, 17, 20",
      answers: [ "14", "15", "13", "16", "12" ],
      correct_answer: "14",
      explanation: "В тази редица всяко следващо число се получава като към предходното прибавим 3:\n1. 2 + 3 = 5\n2. 5 + 3 = 8\n3. 8 + 3 = 11\n4. 11 + 3 = 14\n5. 14 + 3 = 17\n6. 17 + 3 = 20"
    },
    {
      text: "Намерете липсващото число в редицата: 3, 6, 9, ?, 15, 18, 21",
      answers: [ "12", "11", "13", "14", "10" ],
      correct_answer: "12",
      explanation: "В тази редица всяко следващо число се получава като към предходното прибавим 3:\n1. 3 + 3 = 6\n2. 6 + 3 = 9\n3. 9 + 3 = 12\n4. 12 + 3 = 15\n5. 15 + 3 = 18\n6. 18 + 3 = 21"
    },
    {
      text: "Намерете липсващото число в редицата: 4, 8, 12, 16, ?, 24, 28",
      answers: [ "20", "21", "19", "22", "18" ],
      correct_answer: "20",
      explanation: "В тази редица всяко следващо число се получава като към предходното прибавим 4:\n1. 4 + 4 = 8\n2. 8 + 4 = 12\n3. 12 + 4 = 16\n4. 16 + 4 = 20\n5. 20 + 4 = 24\n6. 24 + 4 = 28"
    },
    {
      text: "Намерете липсващото число в редицата: 5, 10, 15, ?, 25, 30, 35",
      answers: [ "20", "22", "18", "21", "19" ],
      correct_answer: "20",
      explanation: "В тази редица всяко следващо число се получава като към предходното прибавим 5:\n1. 5 + 5 = 10\n2. 10 + 5 = 15\n3. 15 + 5 = 20\n4. 20 + 5 = 25\n5. 25 + 5 = 30\n6. 30 + 5 = 35"
    },
    {
      text: "Намерете липсващото число в редицата: 1, 3, 5, 7, ?, 11, 13",
      answers: [ "9", "8", "10", "6", "12" ],
      correct_answer: "9",
      explanation: "В тази редица всяко следващо число се получава като към предходното прибавим 2:\n1. 1 + 2 = 3\n2. 3 + 2 = 5\n3. 5 + 2 = 7\n4. 7 + 2 = 9\n5. 9 + 2 = 11\n6. 11 + 2 = 13"
    },
    {
      text: "Намерете липсващото число в редицата: 2, 4, 6, ?, 10, 12, 14",
      answers: [ "8", "7", "9", "5", "11" ],
      correct_answer: "8",
      explanation: "В тази редица всяко следващо число се получава като към предходното прибавим 2:\n1. 2 + 2 = 4\n2. 4 + 2 = 6\n3. 6 + 2 = 8\n4. 8 + 2 = 10\n5. 10 + 2 = 12\n6. 12 + 2 = 14"
    },
    {
      text: "Намерете липсващото число в редицата: 6, 12, 18, 24, ?, 36, 42",
      answers: [ "30", "32", "28", "34", "26" ],
      correct_answer: "30",
      explanation: "В тази редица всяко следващо число се получава като към предходното прибавим 6:\n1. 6 + 6 = 12\n2. 12 + 6 = 18\n3. 18 + 6 = 24\n4. 24 + 6 = 30\n5. 30 + 6 = 36\n6. 36 + 6 = 42"
    },
    {
      text: "Намерете липсващото число в редицата: 7, 14, 21, ?, 35, 42, 49",
      answers: [ "28", "27", "29", "30", "26" ],
      correct_answer: "28",
      explanation: "В тази редица всяко следващо число се получава като към предходното прибавим 7:\n1. 7 + 7 = 14\n2. 14 + 7 = 21\n3. 21 + 7 = 28\n4. 28 + 7 = 35\n5. 35 + 7 = 42\n6. 42 + 7 = 49"
    },
    {
      text: "Намерете липсващото число в редицата: 8, 16, 24, 32, ?, 48, 56",
      answers: [ "40", "42", "38", "44", "36" ],
      correct_answer: "40",
      explanation: "В тази редица всяко следващо число се получава като към предходното прибавим 8:\n1. 8 + 8 = 16\n2. 16 + 8 = 24\n3. 24 + 8 = 32\n4. 32 + 8 = 40\n5. 40 + 8 = 48\n6. 48 + 8 = 56"
    },
    {
      text: "Намерете липсващото число в редицата: 10, 20, 30, ?, 50, 60, 70",
      answers: [ "40", "45", "35", "42", "38" ],
      correct_answer: "40",
      explanation: "В тази редица всяко следващо число се получава като към предходното прибавим 10:\n1. 10 + 10 = 20\n2. 20 + 10 = 30\n3. 30 + 10 = 40\n4. 40 + 10 = 50\n5. 50 + 10 = 60\n6. 60 + 10 = 70"
    },
    {
      text: "Вече обядвахме и сега почиваме. Времето от обед (12:00 ч.) досега е с два чáса повече от времето между обед (12:00 ч.) и два чáса преди това. Колко е часът сега?",
      answers: [ "4:00 PM", "3:00 PM", "5:00 PM", "2:00 PM", "6:00 PM" ],
      correct_answer: "4:00 PM",
      explanation: "Нека решим задачата стъпка по стъпка:\n1. Два часа преди обяд е било 10:00 AM\n2. От 10:00 AM до 12:00 PM (обяд) са изминали 2 часа\n3. След обяд трябва да са изминали с 2 часа повече, тоест 4 часа\n4. От 12:00 PM + 4 часа = 4:00 PM"
    },
    {
      text: "Вече обядвахме и сега почиваме. Времето от обед (12:00 ч.) досега е с два чáса повече от времето между обед (12:00 ч.) и три чáса преди това. Колко е часът сега?",
      answers: [ "5:00 PM", "4:00 PM", "6:00 PM", "3:00 PM", "7:00 PM" ],
      correct_answer: "5:00 PM",
      explanation: "Нека решим задачата стъпка по стъпка:\n1. Три часа преди обяд е било 9:00 AM\n2. От 9:00 AM до 12:00 PM (обяд) са изминали 3 часа\n3. След обяд трябва да са изминали с 2 часа повече, тоест 5 часа\n4. От 12:00 PM + 5 часа = 5:00 PM"
    },
    {
      text: "Вече обядвахме и сега почиваме. Времето от обед (12:00 ч.) досега е с два чáса повече от времето между обед (12:00 ч.) и четири чáса преди това. Колко е часът сега?",
      answers: [ "6:00 PM", "5:00 PM", "7:00 PM", "4:00 PM", "8:00 PM" ],
      correct_answer: "6:00 PM",
      explanation: "Нека решим задачата стъпка по стъпка:\n1. Четири часа преди обяд е било 8:00 AM\n2. От 8:00 AM до 12:00 PM (обяд) са изминали 4 часа\n3. След обяд трябва да са изминали с 2 часа повече, тоест 6 часа\n4. От 12:00 PM + 6 часа = 6:00 PM"
    },
    {
      text: "Вече обядвахме и сега почиваме. Времето от обед (12:00 ч.) досега е с два чáса повече от времето между обед (12:00 ч.) и един час преди това. Колко е часът сега?",
      answers: [ "3:00 PM", "2:00 PM", "4:00 PM", "1:00 PM", "5:00 PM" ],
      correct_answer: "3:00 PM",
      explanation: "Нека решим задачата стъпка по стъпка:\n1. Един час преди обяд е било 11:00 AM\n2. От 11:00 AM до 12:00 PM (обяд) е изминал 1 час\n3. След обяд трябва да са изминали с 2 часа повече, тоест 3 часа\n4. От 12:00 PM + 3 часа = 3:00 PM"
    },
    {
      text: "Вече обядвахме и сега почиваме. Времето от обед (12:00 ч.) досега е с два чáса повече от времето между обед (12:00 ч.) и пет чáса преди това. Колко е часът сега?",
      answers: [ "7:00 PM", "6:00 PM", "8:00 PM", "5:00 PM", "9:00 PM" ],
      correct_answer: "7:00 PM",
      explanation: "Нека решим задачата стъпка по стъпка:\n1. Пет часа преди обяд е било 7:00 AM\n2. От 7:00 AM до 12:00 PM (обяд) са изминали 5 часа\n3. След обяд трябва да са изминали с 2 часа повече, тоест 7 часа\n4. От 12:00 PM + 7 часа = 7:00 PM"
    },
    {
      text: "Лила има 6 разноцветни чаши (бяла, зелена, червена, синя, жълта и кафява) и иска да ги подреди на рафт. Червената трябва да е най-вляво, жълтата най-вдясно, а синята да не е до червената или жълтата. По колко начина може да стане това?",
      answers: [ "24", "12", "36", "48", "6" ],
      correct_answer: "24",
      explanation: "Нека решим стъпка по стъпка:\n1. Червената трябва да е първа (1 начин)\n2. Жълтата трябва да е последна (1 начин)\n3. Синята не може да е втора (до червената) или пета (до жълтата)\n4. За синята остават 2 позиции (3-та или 4-та)\n5. За останалите 3 чаши (бяла, зелена, кафява) имаме 4 позиции\n6. Това прави: 2 (позиции за синята) × P(3,3) = 2 × 6 = 24 начина"
    },
    {
      text: "Лила има 6 разноцветни чаши (бяла, зелена, червена, синя, жълта и кафява). Червената трябва да е най-вляво, жълтата най-вдясно, а синята да е точно по средата. По колко начина може да подреди останалите чаши?",
      answers: [ "6", "12", "4", "8", "2" ],
      correct_answer: "6",
      explanation: "Нека анализираме:\n1. Червената е фиксирана първа\n2. Жълтата е фиксирана последна\n3. Синята е фиксирана в средата\n4. Остават 3 чаши (бяла, зелена, кафява) за 2 позиции\n5. Това е пермутация: P(3,2) = 6 начина"
    },
    {
      text: "Лила има 6 разноцветни чаши (бяла, зелена, червена, синя, жълта и кафява). Червената трябва да е най-вляво, жълтата най-вдясно, а синята трябва да е до бялата. По колко начина може да подреди чашите?",
      answers: [ "12", "24", "8", "16", "4" ],
      correct_answer: "12",
      explanation: "Нека анализираме:\n1. Червената е фиксирана първа\n2. Жълтата е фиксирана последна\n3. Синята и бялата трябва да са заедно (2 позиции за тях)\n4. За останалите 2 чаши имаме 3 позиции\n5. Това прави: 2 (начина за подреждане на синя-бяла) × 6 (пермутации за останалите) = 12"
    },
    {
      text: "Лила има 6 разноцветни чаши (бяла, зелена, червена, синя, жълта и кафява). Червената трябва да е най-вляво, жълтата най-вдясно, а синята и кафявата трябва да са една до друга. По колко начина може да подреди чашите?",
      answers: [ "16", "12", "24", "8", "4" ],
      correct_answer: "16",
      explanation: "Нека анализираме:\n1. Червената е фиксирана първа\n2. Жълтата е фиксирана последна\n3. Синята и кафявата трябва да са заедно (3 позиции за тях)\n4. За останалите 2 чаши имаме 3 позиции\n5. Това прави: 2 (начина за подреждане на синя-кафява) × 4 (позиции за двойката) × 2 (пермутации за останалите) = 16"
    },
    {
      text: "Лила има 6 разноцветни чаши (бяла, зелена, червена, синя, жълта и кафява). Червената трябва да е най-вляво, жълтата най-вдясно, а зелената трябва да е между синята и кафявата. По колко начина може да подреди чашите?",
      answers: [ "8", "12", "16", "4", "24" ],
      correct_answer: "8",
      explanation: "Нека анализираме:\n1. Червената е фиксирана първа\n2. Жълтата е фиксирана последна\n3. Зелената трябва да е между синята и кафявата\n4. За тройката синя-зелена-кафява имаме 2 позиции\n5. Бялата може да заеме 4 позиции\n6. Това прави: 2 (начина за подреждане на синя-зелена-кафява) × 4 (позиции за бялата) = 8"
    },
    {
      text: "В училищно състезание по бягане, малко преди финала Мария успяла да задмине седмия отпред назад. На кое място е финиширала тя?",
      answers: [ "на четвъртото", "на петото", "на шестото", "на седмото", "на осмото" ],
      correct_answer: "на шестото",
      explanation: "Нека решим стъпка по стъпка:\n1. Мария е задминала седмия отпред назад\n2. Това означава, че преди изпреварването тя е била зад него\n3. След като го е задминала, тя заема неговата позиция (7-мо място отзад напред)\n4. 7-мо място отзад напред = 6-то място отпред назад\nСледователно, Мария е финиширала на 6-то място."
    },
    {
      text: "В училищно състезание по бягане, малко преди финала Петър успял да задмине петия отпред назад. На кое място е финиширал той?",
      answers: [ "на второто", "на третото", "на четвъртото", "на петото", "на шестото" ],
      correct_answer: "на четвъртото",
      explanation: "Нека решим стъпка по стъпка:\n1. Петър е задминал петия отпред назад\n2. Това означава, че преди изпреварването той е бил зад него\n3. След като го е задминал, той заема неговата позиция (5-то място отзад напред)\n4. 5-то място отзад напред = 4-то място отпред назад\nСледователно, Петър е финиширал на 4-то място."
    },
    {
      text: "В училищно състезание по бягане, малко преди финала Ана успяла да задмине третия отпред назад. На кое място е финиширала тя?",
      answers: [ "на първото", "на второто", "на третото", "на четвъртото", "на петото" ],
      correct_answer: "на второто",
      explanation: "Нека решим стъпка по стъпка:\n1. Ана е задминала третия отпред назад\n2. Това означава, че преди изпреварването тя е била зад него\n3. След като го е задминала, тя заема неговата позиция (3-то място отзад напред)\n4. 3-то място отзад напред = 2-ро място отпред назад\nСледователно, Ана е финиширала на 2-ро място."
    },
    {
      text: "В училищно състезание по бягане, малко преди финала Борис успял да задмине осмия отпред назад. На кое място е финиширал той?",
      answers: [ "на петото", "на шестото", "на седмото", "на осмото", "на деветото" ],
      correct_answer: "на седмото",
      explanation: "Нека решим стъпка по стъпка:\n1. Борис е задминал осмия отпред назад\n2. Това означава, че преди изпреварването той е бил зад него\n3. След като го е задминал, той заема неговата позиция (8-мо място отзад напред)\n4. 8-мо място отзад напред = 7-мо място отпред назад\nСледователно, Борис е финиширал на 7-мо място."
    },
    {
      text: "В училищно състезание по бягане, малко преди финала Лидия успяла да задмине десетия отпред назад. На кое място е финиширала тя?",
      answers: [ "на седмото", "на осмото", "на деветото", "на десетото", "на единадесетото" ],
      correct_answer: "на деветото",
      explanation: "Нека решим стъпка по стъпка:\n1. Лидия е задминала десетия отпред назад\n2. Това означава, че преди изпреварването тя е била зад него\n3. След като го е задминала, тя заема неговата позиция (10-то място отзад напред)\n4. 10-то място отзад напред = 9-то място отпред назад\nСледователно, Лидия е финиширала на 9-то място."
    }
  ]

  questions.each do |question_data|
    question = Question.create!(
      text: question_data[:text],
      answer: question_data[:correct_answer],
      explanation: question_data[:explanation]
    )

    question_data[:answers].each do |answer_text|
      PossibleAnswer.create!(
        question: question,
        value: answer_text
      )
    end
  end
end
