-- Public shared flashcard deck and review data. No user accounts are required.
-- Card content is readable by all visitors; progress and reviews are public too.

-- Card text is public and visitors can edit front/back from the website; IDs and order are fixed.
create table if not exists public.shared_flashcards (
  card_id text primary key,
  front text not null,
  back text not null,
  category text not null,
  sort_order integer not null unique,
  updated_at timestamptz not null default now()
);

alter table public.shared_flashcards enable row level security;
revoke all privileges on table public.shared_flashcards from public, anon, authenticated;
drop policy if exists "Public read shared flashcards" on public.shared_flashcards;
create policy "Public read shared flashcards"
  on public.shared_flashcards for select to anon, authenticated
  using (true);
grant select on public.shared_flashcards to anon, authenticated;

-- Visitors can edit card text from the website. IDs, categories and order remain read-only.
drop policy if exists "Public edit shared flashcard text" on public.shared_flashcards;
create policy "Public edit shared flashcard text"
  on public.shared_flashcards for update to anon, authenticated
  using (true)
  with check (true);
grant update (front, back) on public.shared_flashcards to anon, authenticated;

insert into public.shared_flashcards (card_id, front, back, category, sort_order)
values
  ('story-1-1-dar-un-paseo', 'прогуляться', 'dar un paseo', 'Un paseo por la ciudad', 1),
  ('story-1-2-hace-buen-tiempo', 'хорошая погода', 'hace buen tiempo', 'Un paseo por la ciudad', 2),
  ('story-1-3-pan-recien-hecho', 'свежеиспечённый хлеб', 'pan recién hecho', 'Un paseo por la ciudad', 3),
  ('story-1-4-un-banco-libre', 'свободная скамейка', 'un banco libre', 'Un paseo por la ciudad', 4),
  ('story-1-5-de-repente', 'вдруг', 'de repente', 'Un paseo por la ciudad', 5),
  ('story-1-6-mover-la-cola', 'вилять хвостом', 'mover la cola', 'Un paseo por la ciudad', 6),
  ('story-2-1-que-tal', 'Как дела?', '¿Qué tal?', 'Un café con Ana', 7),
  ('story-2-2-quieres', 'Хочешь…?', '¿Quieres…?', 'Un café con Ana', 8),
  ('story-2-3-para-mi-para-ti', 'для меня / для тебя', 'para mí / para ti', 'Un café con Ana', 9),
  ('story-2-4-son-las-nueve-y-media', 'Сейчас половина десятого.', 'Son las nueve y media.', 'Un café con Ana', 10),
  ('story-2-5-tener-que-infinitivo', 'нужно что-то сделать', 'tener que + infinitivo', 'Un café con Ana', 11),
  ('story-2-6-la-cuenta-por-favor', 'Счёт, пожалуйста.', 'La cuenta, por favor.', 'Un café con Ana', 12),
  ('story-2-7-cuanto-es', 'Сколько с меня / с нас?', '¿Cuánto es?', 'Un café con Ana', 13),
  ('story-2-8-vale', 'хорошо, ладно', 'vale', 'Un café con Ana', 14),
  ('story-3-1-hay-no-hay', 'есть / нет', 'hay / no hay', 'La compra de Marta', 15),
  ('story-3-2-hacer-la-compra', 'покупать продукты', 'hacer la compra', 'La compra de Marta', 16),
  ('story-3-3-coger-una-bolsa', 'взять сумку', 'coger una bolsa', 'La compra de Marta', 17),
  ('story-3-4-al-lado-de', 'рядом с', 'al lado de', 'La compra de Marta', 18),
  ('story-3-5-a-la-derecha', 'справа', 'a la derecha', 'La compra de Marta', 19),
  ('story-3-6-puedo-pagar-con-tarjeta', 'Можно заплатить картой?', '¿Puedo pagar con tarjeta?', 'La compra de Marta', 20),
  ('story-3-7-si-claro', 'Да, конечно.', 'Sí, claro.', 'La compra de Marta', 21),
  ('story-3-8-tener-hambre', 'хотеть есть', 'tener hambre', 'La compra de Marta', 22),
  ('story-4-1-que-haces', 'Что делаешь?', '¿Qué haces?', 'Una tarde en el parque', 23),
  ('story-4-2-vamos-al-parque', 'Пойдём в парк?', '¿Vamos al parque?', 'Una tarde en el parque', 24),
  ('story-4-3-a-que-hora', 'Во сколько?', '¿A qué hora?', 'Una tarde en el parque', 25),
  ('story-4-4-ir-a-pie', 'идти пешком', 'ir a pie', 'Una tarde en el parque', 26),
  ('story-4-5-no-esta-lejos', 'находится недалеко', 'no está lejos', 'Una tarde en el parque', 27),
  ('story-4-6-tener-sed', 'хотеть пить', 'tener sed', 'Una tarde en el parque', 28),
  ('story-4-7-me-gusta', 'Мне нравится…', 'Me gusta…', 'Una tarde en el parque', 29),
  ('story-4-8-a-mi-tambien', 'Мне тоже.', 'A mí también.', 'Una tarde en el parque', 30),
  ('story-5-1-ir-al-centro', 'ехать / идти в центр', 'ir al centro', 'El autobús al centro', 31),
  ('story-5-2-comer-juntos', 'обедать вместе', 'comer juntos', 'El autobús al centro', 32),
  ('story-5-3-la-parada', 'остановка', 'la parada', 'El autobús al centro', 33),
  ('story-5-4-un-billete-por-favor', 'Один билет, пожалуйста.', 'Un billete, por favor.', 'El autobús al centro', 34),
  ('story-5-5-junto-a-la-ventana', 'у окна', 'junto a la ventana', 'El autobús al centro', 35),
  ('story-5-6-bajar-del-autobus', 'выйти из автобуса', 'bajar del autobús', 'El autobús al centro', 36),
  ('story-5-7-el-menu-del-dia', 'комплексный обед дня', 'el menú del día', 'El autobús al centro', 37),
  ('story-5-8-es-hora-de-comer', 'Пора обедать.', 'Es hora de comer.', 'El autobús al centro', 38),
  ('story-6-1-el-piso', 'квартира', 'el piso', 'Las llaves de Diego', 39),
  ('story-6-2-tener-sueno', 'хотеть спать', 'tener sueño', 'Las llaves de Diego', 40),
  ('story-6-3-tener-que-salir', 'нужно выходить', 'tener que salir', 'Las llaves de Diego', 41),
  ('story-6-4-buscar', 'искать', 'buscar', 'Las llaves de Diego', 42),
  ('story-6-5-debajo-de', 'под', 'debajo de', 'Las llaves de Diego', 43),
  ('story-6-6-detras-de', 'за, позади', 'detrás de', 'Las llaves de Diego', 44),
  ('story-6-7-tener-prisa', 'спешить', 'tener prisa', 'Las llaves de Diego', 45),
  ('story-6-8-tener-suerte', 'везти', 'tener suerte', 'Las llaves de Diego', 46),
  ('story-7-1-el-barrio', 'район', 'el barrio', 'La bolsa de naranjas', 47),
  ('story-7-3-la-terraza', 'открытая площадка кафе', 'la terraza', 'La bolsa de naranjas', 48),
  ('story-7-4-el-zumo-de-naranja', 'апельсиновый сок', 'el zumo de naranja', 'La bolsa de naranjas', 49),
  ('story-7-5-pesar-mucho', 'быть тяжёлым', 'pesar mucho', 'La bolsa de naranjas', 50),
  ('story-7-6-el-suelo', 'земля, пол', 'el suelo', 'La bolsa de naranjas', 51),
  ('story-7-7-recoger', 'поднимать, собирать', 'recoger', 'La bolsa de naranjas', 52),
  ('story-7-8-esta-muy-bueno', 'Очень вкусно.', 'Está muy bueno.', 'La bolsa de naranjas', 53),
  ('story-8-1-el-ruido', 'шум', 'el ruido', 'Un sitio junto a la ventana', 54),
  ('story-8-2-la-biblioteca', 'библиотека', 'la biblioteca', 'Un sitio junto a la ventana', 55),
  ('story-8-3-estar-abierto', 'быть открытым', 'estar abierto', 'Un sitio junto a la ventana', 56),
  ('story-8-4-al-fondo', 'в глубине, в конце', 'al fondo', 'Un sitio junto a la ventana', 57),
  ('story-8-5-junto-a', 'рядом с, у', 'junto a', 'Un sitio junto a la ventana', 58),
  ('story-8-6-empezar-a-leer', 'начинать читать', 'empezar a leer', 'Un sitio junto a la ventana', 59),
  ('story-8-7-entender', 'понимать', 'entender', 'Un sitio junto a la ventana', 60),
  ('story-8-8-volver', 'возвращаться', 'volver', 'Un sitio junto a la ventana', 61),
  ('story-9-1-cambiarse-de-ropa', 'переодеваться', 'cambiarse de ropa', 'La ropa de Isabel', 62),
  ('story-9-2-el-armario', 'шкаф', 'el armario', 'La ropa de Isabel', 63),
  ('story-9-3-demasiado-largo', 'слишком длинный', 'demasiado largo', 'La ropa de Isabel', 64),
  ('story-9-4-los-vaqueros', 'джинсы', 'los vaqueros', 'La ropa de Isabel', 65),
  ('story-9-5-probarse', 'примерять', 'probarse', 'La ropa de Isabel', 66),
  ('story-9-6-quedar-bien', 'быть впору; хорошо смотреться', 'quedar bien', 'La ropa de Isabel', 67),
  ('story-9-7-no-pasa-nada', 'Ничего страшного.', 'No pasa nada.', 'La ropa de Isabel', 68),
  ('story-9-8-en-vez-de', 'вместо', 'en vez de', 'La ropa de Isabel', 69),
  ('story-9-9-las-zapatillas', 'кроссовки', 'las zapatillas', 'La ropa de Isabel', 70),
  ('story-9-10-no-hace-falta-infinitivo', 'Не нужно / необязательно что-то делать', 'No hace falta + infinitivo', 'La ropa de Isabel', 71),
  ('story-9-11-estar-a-gusto', 'чувствовать себя комфортно', 'estar a gusto', 'La ropa de Isabel', 72),
  ('story-9-12-hace-fresco', 'прохладно', 'hace fresco', 'La ropa de Isabel', 73),
  ('story-9-13-por-fin', 'наконец', 'por fin', 'La ropa de Isabel', 74),
  ('story-10-1-pedir-cita', 'записаться на приём', 'pedir cita', 'Una cita con la médica', 75),
  ('story-10-2-el-centro-de-salud', 'поликлиника, медицинский центр', 'el centro de salud', 'Una cita con la médica', 76),
  ('story-10-3-queria', 'я хотел(а) бы… — вежливая просьба', 'quería…', 'Una cita con la médica', 77),
  ('story-10-4-te-viene-bien', 'Тебе удобно?', '¿Te viene bien?', 'Una cita con la médica', 78),
  ('story-10-5-la-tarjeta-sanitaria', 'медицинская карта для доступа к системе здравоохранения', 'la tarjeta sanitaria', 'Una cita con la médica', 79),
  ('story-10-6-la-sala-de-espera', 'зал ожидания', 'la sala de espera', 'Una cita con la médica', 80),
  ('story-10-7-que-te-pasa', 'Что тебя беспокоит?', '¿Qué te pasa?', 'Una cita con la médica', 81),
  ('story-10-8-me-duele-la-garganta', 'У меня болит горло.', 'Me duele la garganta.', 'Una cita con la médica', 82),
  ('story-10-9-tener-tos-fiebre', 'иметь кашель / повышенную температуру', 'tener tos / fiebre', 'Una cita con la médica', 83),
  ('story-10-10-desde-cuando', 'С каких пор?', '¿Desde cuándo?', 'Una cita con la médica', 84),
  ('story-10-11-desde-ayer', 'со вчерашнего дня', 'desde ayer', 'Una cita con la médica', 85),
  ('story-10-12-no-lo-se', 'Я не знаю.', 'No lo sé.', 'Una cita con la médica', 86),
  ('story-10-13-tomar-la-temperatura', 'измерять температуру', 'tomar la temperatura', 'Una cita con la médica', 87),
  ('story-10-14-la-consulta', 'приём у врача', 'la consulta', 'Una cita con la médica', 88),
  ('story-11-1-irse-de-viaje', 'отправляться в путешествие', 'irse de viaje', 'Un día especial en Bilbao', 89),
  ('story-11-2-tener-ganas-de-infinitivo', 'хотеть что-то сделать', 'tener ganas de + infinitivo', 'Un día especial en Bilbao', 90),
  ('story-11-3-otra-vez', 'снова', 'otra vez', 'Un día especial en Bilbao', 91),
  ('story-11-4-asi-que', 'поэтому', 'así que', 'Un día especial en Bilbao', 92),
  ('story-11-5-cual-es-el-mio', 'Какой из них мой?', '¿Cuál es el mío?', 'Un día especial en Bilbao', 93),
  ('story-11-6-una-hora-y-media', 'полтора часа', 'una hora y media', 'Un día especial en Bilbao', 94),
  ('story-11-7-todo-recto', 'всё время прямо', 'todo recto', 'Un día especial en Bilbao', 95),
  ('story-11-8-a-la-izquierda', 'налево', 'a la izquierda', 'Un día especial en Bilbao', 96),
  ('story-11-9-me-puedo-sentar-aqui', 'Можно мне здесь сесть?', '¿Me puedo sentar aquí?', 'Un día especial en Bilbao', 97),
  ('story-11-10-que-rico', 'Как вкусно!', '¡Qué rico!', 'Un día especial en Bilbao', 98),
  ('story-11-11-que-raro', 'Как странно!', '¡Qué raro!', 'Un día especial en Bilbao', 99),
  ('story-11-12-manana-por-la-manana', 'завтра утром', 'mañana por la mañana', 'Un día especial en Bilbao', 100),
  ('story-11-13-ir-a-infinitivo', 'собираться что-то сделать', 'ir a + infinitivo', 'Un día especial en Bilbao', 101),
  ('story-11-14-quedarse-en-casa', 'оставаться дома', 'quedarse en casa', 'Un día especial en Bilbao', 102),
  ('story-11-15-a-dormir', 'Пора спать!', '¡A dormir!', 'Un día especial en Bilbao', 103),
  ('story-12-1-el-cumpleanos', 'день рождения', 'el cumpleaños', 'Una sorpresa para mi hermana', 104),
  ('story-12-2-preparar-una-sorpresa', 'приготовить сюрприз', 'preparar una sorpresa', 'Una sorpresa para mi hermana', 105),
  ('story-12-3-tener-muchas-cosas-que-hacer', 'иметь много дел', 'tener muchas cosas que hacer', 'Una sorpresa para mi hermana', 106),
  ('story-12-4-cuanto-cuesta-esto', 'Сколько это стоит?', '¿Cuánto cuesta esto?', 'Una sorpresa para mi hermana', 107),
  ('story-12-5-dinero-suficiente', 'достаточно денег', 'dinero suficiente', 'Una sorpresa para mi hermana', 108),
  ('story-12-6-al-final', 'в конце концов', 'al final', 'Una sorpresa para mi hermana', 109),
  ('story-12-7-por-eso', 'поэтому', 'por eso', 'Una sorpresa para mi hermana', 110),
  ('story-12-8-a-veces', 'иногда', 'a veces', 'Una sorpresa para mi hermana', 111),
  ('story-12-9-llegar-tarde', 'опаздывать', 'llegar tarde', 'Una sorpresa para mi hermana', 112),
  ('story-12-10-no-te-preocupes', 'Не переживай.', 'No te preocupes.', 'Una sorpresa para mi hermana', 113),
  ('story-12-11-todavia-tenemos-tiempo', 'У нас ещё есть время.', 'Todavía tenemos tiempo.', 'Una sorpresa para mi hermana', 114),
  ('story-12-12-son-las-dos-y-cuarto', 'Сейчас два пятнадцать.', 'Son las dos y cuarto.', 'Una sorpresa para mi hermana', 115),
  ('story-12-13-feliz-cumpleanos', 'С днём рождения!', '¡Feliz cumpleaños!', 'Una sorpresa para mi hermana', 116),
  ('story-12-14-lo-dices-en-serio', 'Ты серьёзно?', '¿Lo dices en serio?', 'Una sorpresa para mi hermana', 117),
  ('story-12-15-por-supuesto-que-si', 'Конечно да!', '¡Por supuesto que sí!', 'Una sorpresa para mi hermana', 118),
  ('story-12-16-pasar-tiempo-con-alguien', 'проводить время с кем-то', 'pasar tiempo con alguien', 'Una sorpresa para mi hermana', 119),
  ('story-13-1-los-fines-de-semana', 'по выходным', 'los fines de semana', 'Un sábado lleno de sorpresas', 120),
  ('story-13-2-esta-nublado', 'Облачно.', 'Está nublado.', 'Un sábado lleno de sorpresas', 121),
  ('story-13-3-sin-embargo', 'однако, несмотря на это', 'sin embargo', 'Un sábado lleno de sorpresas', 122),
  ('story-13-4-darse-la-vuelta', 'обернуться', 'darse la vuelta', 'Un sábado lleno de sorpresas', 123),
  ('story-13-5-venga', 'Давай!', '¡Venga!', 'Un sábado lleno de sorpresas', 124),
  ('story-13-6-ir-andando', 'идти пешком', 'ir andando', 'Un sábado lleno de sorpresas', 125),
  ('story-13-7-perderse', 'заблудиться', 'perderse', 'Un sábado lleno de sorpresas', 126),
  ('story-13-8-girar-en-la-siguiente-calle', 'повернуть на следующую улицу', 'girar en la siguiente calle', 'Un sábado lleno de sorpresas', 127),
  ('story-13-9-puedes-repetirlo-por-favor', 'Можете повторить, пожалуйста?', '¿Puedes repetirlo, por favor?', 'Un sábado lleno de sorpresas', 128),
  ('story-13-10-habla-mas-despacio-por-favor', 'Говорите медленнее, пожалуйста.', 'Habla más despacio, por favor.', 'Un sábado lleno de sorpresas', 129),
  ('story-13-11-socorro-ayudame', 'На помощь! Помогите мне!', '¡Socorro! ¡Ayúdame!', 'Un sábado lleno de sorpresas', 130),
  ('story-13-12-el-dueno', 'хозяин', 'el dueño', 'Un sábado lleno de sorpresas', 131),
  ('story-13-13-el-collar', 'ошейник', 'el collar', 'Un sábado lleno de sorpresas', 132),
  ('story-13-14-que-me-recomiendas', 'Что вы порекомендуете?', '¿Qué me recomiendas?', 'Un sábado lleno de sorpresas', 133),
  ('story-13-15-las-gambas-al-ajillo', 'креветки с чесноком', 'las gambas al ajillo', 'Un sábado lleno de sorpresas', 134),
  ('story-13-16-ser-alergico-a-a-los-cacahuetes', 'иметь аллергию на арахис', 'ser alérgico/a a los cacahuetes', 'Un sábado lleno de sorpresas', 135),
  ('story-13-17-que-aproveche', 'Приятного аппетита!', '¡Que aproveche!', 'Un sábado lleno de sorpresas', 136),
  ('story-13-18-la-cuenta-cuando-pueda-por-favor', 'Счёт, когда сможете, пожалуйста.', 'La cuenta cuando pueda, por favor.', 'Un sábado lleno de sorpresas', 137),
  ('story-13-19-el-martes-que-viene', 'в следующий вторник', 'el martes que viene', 'Un sábado lleno de sorpresas', 138),
  ('story-13-20-pasar-un-buen-rato', 'хорошо провести время', 'pasar un buen rato', 'Un sábado lleno de sorpresas', 139),
  ('story-14-1-queria-reservar-una-habitacion', 'Я хотела бы забронировать номер.', 'Quería reservar una habitación.', 'Una habitación en Sevilla', 140),
  ('story-14-2-por-noche', 'за ночь', 'por noche', 'Una habitación en Sevilla', 141),
  ('story-14-3-con-desayuno', 'с завтраком', 'con desayuno', 'Una habitación en Sevilla', 142),
  ('story-14-4-me-quedo-aqui', 'Я остановлюсь здесь.', 'Me quedo aquí.', 'Una habitación en Sevilla', 143),
  ('story-14-5-el-documento-de-identidad', 'документ, удостоверяющий личность', 'el documento de identidad', 'Una habitación en Sevilla', 144),
  ('story-14-6-puede-escribirlo-por-favor', 'Можете это записать, пожалуйста?', '¿Puede escribirlo, por favor?', 'Una habitación en Sevilla', 145),
  ('story-14-7-los-horarios', 'расписание', 'los horarios', 'Una habitación en Sevilla', 146),
  ('story-14-8-al-final-del-pasillo', 'в конце коридора', 'al final del pasillo', 'Una habitación en Sevilla', 147),
  ('story-14-9-encantada-de-conocerte', 'Рада познакомиться.', 'Encantada de conocerte.', 'Una habitación en Sevilla', 148),
  ('story-14-10-igualmente', 'Взаимно.', 'Igualmente.', 'Una habitación en Sevilla', 149),
  ('story-14-11-de-donde-eres', 'Откуда ты?', '¿De dónde eres?', 'Una habitación en Sevilla', 150),
  ('story-14-12-a-que-te-dedicas', 'Чем ты занимаешься?', '¿A qué te dedicas?', 'Una habitación en Sevilla', 151),
  ('story-14-13-al-aire-libre', 'на открытом воздухе', 'al aire libre', 'Una habitación en Sevilla', 152),
  ('story-14-14-estoy-ocupada', 'Я занята.', 'Estoy ocupada.', 'Una habitación en Sevilla', 153),
  ('story-14-15-estoy-libre', 'Я свободна.', 'Estoy libre.', 'Una habitación en Sevilla', 154),
  ('story-15-1-cambiar-de-peinado', 'сменить причёску', 'cambiar de peinado', 'El nuevo peinado de Paula', 155),
  ('story-15-2-pedir-hora', 'записаться на приём', 'pedir hora', 'El nuevo peinado de Paula', 156),
  ('story-15-3-cortarse-el-pelo', 'подстричься', 'cortarse el pelo', 'El nuevo peinado de Paula', 157),
  ('story-15-4-mantener-el-color-natural', 'сохранить естественный цвет', 'mantener el color natural', 'El nuevo peinado de Paula', 158),
  ('story-15-5-el-flequillo', 'чёлка', 'el flequillo', 'El nuevo peinado de Paula', 159),
  ('story-15-6-el-reflejo', 'отражение', 'el reflejo', 'El nuevo peinado de Paula', 160),
  ('story-15-7-te-queda-muy-bien', 'тебе очень идёт', 'te queda muy bien', 'El nuevo peinado de Paula', 161)
on conflict (card_id) do update set
  front = excluded.front,
  back = excluded.back,
  category = excluded.category,
  sort_order = excluded.sort_order,
  updated_at = now();

-- Public shared mode: all visitors share one deck. This intentionally permits
-- anonymous reads and writes, so do not store private data in these tables.
create table if not exists public.shared_flashcard_progress (
  card_id text primary key,
  fsrs_card jsonb not null,
  updated_at timestamptz not null default now()
);

create table if not exists public.shared_flashcard_reviews (
  id bigint generated always as identity primary key,
  card_id text not null,
  rating smallint not null check (rating between 1 and 4),
  reviewed_at timestamptz not null,
  due_at timestamptz not null,
  difficulty double precision not null,
  stability double precision not null,
  stability_fast double precision not null,
  revlog jsonb not null,
  created_at timestamptz not null default now()
);

alter table public.shared_flashcard_progress enable row level security;
alter table public.shared_flashcard_reviews enable row level security;

drop policy if exists "Public shared flashcard progress" on public.shared_flashcard_progress;
create policy "Public shared flashcard progress"
  on public.shared_flashcard_progress for all to anon, authenticated
  using (true)
  with check (true);

drop policy if exists "Public shared flashcard reviews" on public.shared_flashcard_reviews;
create policy "Public shared flashcard reviews"
  on public.shared_flashcard_reviews for all to anon, authenticated
  using (true)
  with check (true);

grant select, insert, update, delete on public.shared_flashcard_progress to anon, authenticated;
grant select, insert, update, delete on public.shared_flashcard_reviews to anon, authenticated;
grant usage, select on sequence public.shared_flashcard_reviews_id_seq to anon, authenticated;

create or replace function public.review_shared_flashcard(
  p_card_id text,
  p_fsrs_card jsonb,
  p_review jsonb
) returns void
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if p_card_id is null or length(p_card_id) > 160 then
    raise exception 'Invalid card id';
  end if;
  if (p_review->>'rating')::smallint not between 1 and 4 then
    raise exception 'Invalid rating';
  end if;

  insert into public.shared_flashcard_progress (card_id, fsrs_card, updated_at)
  values (p_card_id, p_fsrs_card, now())
  on conflict (card_id) do update
    set fsrs_card = excluded.fsrs_card,
        updated_at = excluded.updated_at;

  insert into public.shared_flashcard_reviews (
    card_id, rating, reviewed_at, due_at,
    difficulty, stability, stability_fast, revlog
  ) values (
    p_card_id,
    (p_review->>'rating')::smallint,
    (p_review->>'reviewed_at')::timestamptz,
    (p_review->>'due_at')::timestamptz,
    (p_review->>'difficulty')::double precision,
    (p_review->>'stability')::double precision,
    (p_review->>'stability_fast')::double precision,
    p_review->'revlog'
  );
end;
$$;

grant execute on function public.review_shared_flashcard(text, jsonb, jsonb) to anon, authenticated;

-- Vocabulary registry. Accents remain meaningful (sí and si are different words).
create or replace function public.normalize_spanish_word(value text)
returns text language sql immutable strict set search_path = ''
as $$ select lower(regexp_replace(btrim(normalize(value, NFC)), '[[:space:]]+', ' ', 'g')); $$;

create table if not exists public.words (
  id uuid primary key default gen_random_uuid(),
  word text not null,
  normalized_word text generated always as (public.normalize_spanish_word(word)) stored unique,
  created_at timestamptz not null default now()
);
alter table public.words enable row level security;
revoke all on public.words from public, anon, authenticated;
grant select, insert, update, delete on public.words to service_role;
alter table public.shared_flashcards add column if not exists word_id uuid references public.words(id);

-- Import already generated words without changing card IDs or review history.
insert into public.words(word)
select distinct split_part(category, ' · ', 2) from public.shared_flashcards
where category like 'AI word · %'
on conflict (normalized_word) do nothing;
update public.shared_flashcards c set word_id = w.id
from public.words w where c.category like 'AI word · %'
and public.normalize_spanish_word(split_part(c.category, ' · ', 2)) = w.normalized_word
and c.word_id is null;

-- Generated vocabulary is inserted by the generate-word-cards Edge Function
-- using its service role key. Visitors cannot write directly to the deck.
create or replace function public.add_generated_word_cards(
  p_word text,
  p_cards jsonb
) returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  next_order integer;
  vocabulary_id uuid;
  card jsonb;
  expected_types text[] := array['Recognition', 'Recall', 'Cloze'];
  actual_types text[];
begin
  if p_word is null or length(btrim(p_word)) not between 1 and 80 then
    raise exception 'Invalid word';
  end if;
  if jsonb_typeof(p_cards) <> 'array' or jsonb_array_length(p_cards) <> 3 then
    raise exception 'Exactly three generated cards are required';
  end if;

  select array_agg(value->>'type' order by value->>'type')
    into actual_types from jsonb_array_elements(p_cards);
  if actual_types is distinct from array['Cloze', 'Recall', 'Recognition']::text[] then
    raise exception 'Invalid generated card types';
  end if;
  for card in select value from jsonb_array_elements(p_cards) loop
    if coalesce(card->>'card_id', '') = '' or
       length(card->>'card_id') > 160 or
       coalesce(card->>'front', '') = '' or
       coalesce(card->>'back', '') = '' or
       coalesce(card->>'category', '') not like 'AI word · %' then
      raise exception 'Invalid generated card';
    end if;
  end loop;

  insert into public.words(word) values (p_word) returning id into vocabulary_id;

  perform pg_advisory_xact_lock(hashtext('shared_flashcards_sort_order'));
  select coalesce(max(sort_order), 0) + 1 into next_order
    from public.shared_flashcards;

  insert into public.shared_flashcards (card_id, front, back, category, sort_order, word_id)
  select generated.card->>'card_id', generated.card->>'front',
         generated.card->>'back', generated.card->>'category',
         next_order + row_number() over (order by generated.card->>'type')::integer - 1, vocabulary_id
    from jsonb_array_elements(p_cards) as generated(card);
end;
$$;

revoke all on function public.add_generated_word_cards(text, jsonb) from public, anon, authenticated;
grant execute on function public.add_generated_word_cards(text, jsonb) to service_role;

notify pgrst, 'reload schema';

-- Optional image per card, stored in the public card-images bucket.
alter table public.shared_flashcards add column if not exists image_path text;
alter table public.shared_flashcards add column if not exists image_side text not null default 'back' check (image_side in ('front','back'));
grant update (image_path, image_side) on public.shared_flashcards to anon, authenticated;
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values ('card-images','card-images',true,10485760,array['image/jpeg','image/png','image/webp','image/gif'])
on conflict (id) do update set public=true,file_size_limit=excluded.file_size_limit,allowed_mime_types=excluded.allowed_mime_types;
drop policy if exists "Visitors upload card images" on storage.objects;
create policy "Visitors upload card images" on storage.objects for insert to anon, authenticated
with check (bucket_id='card-images' and (storage.foldername(name))[1]='cards');
notify pgrst, 'reload schema';
