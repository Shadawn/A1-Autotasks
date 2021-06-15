﻿#Область Интерфейс
#Если НЕ Клиент Тогда
	
	// Создает пустую настройку автозадачи. Предназначена для использования в событии А1Автозадачи_ПриОпределенииНастроек.
	// 
	// Возвращаемое значение:
	//   - Структура класса "А1Автозадачи_Настройка".
	//
	Функция НовыйНастройка() Экспорт 
		Возврат А1Э_Структуры.Создать(
		"Класс", "А1Автозадачи_Настройка",
		"ТекстЗапроса", "",
		"ПараметрыЗапроса", Новый Структура, //Структура или Строка. Если строка - воспринимается как функция, которая должна вернуть структуру параметров.
		"Варианты", "", //Массив Строк или Строка, разделенная запятыми. Описывает тип автозадач. 
		"Ключи", "", //Массив Строк или Строка, разделенная запятыми. Перечень колонок, которые уникально идентифицируют задачу. 
		"Параметры", "", //Массив Строк или Строка, разделенная запятыми. Перечень колонок, которые описывают состояние задачи. Если одна из этих колонок меняется, задачу надо обновить. 
		"Источники", "", //Массив Строк или Строка, разделенная запятыми. Имена метаданных объектов, которые могут являться источниками.
		"Задача", "", //Строка. Имя метаданных объекта, который будет хранить задачу в системе.
		"Команда", "", //Строка. Если заполнено, то на форме задачи будет выведена кнонка, которая при нажании вызывает указанную функцию. При вызове в функцию передается форма.
		"РучноеВыполнение", Ложь, //Если установлено, то пользователь может отметить задачу как выполненную и система примет это. В противном случае система продолжит создавать задачи пока исходное состояние не будет исправлено.
		) 
	КонецФункции
	
	// Обновляет существующие автозадачи. Обычно выполняется в фоновом задании или при записи источника 
	//
	// Параметры:
	//  ТолькоИзмененные - Булево - если Истина, то обновляются только те автозадачи, у которых изменились ключи/параметры.
	//    Если Ложь, то обновляются все не завершенные автозадачи. Это полезно при изменении алгоритмов.
	//  Источник		 - ЛюбаяСсылка,А1Э_Идентификатор - источник автозадачи. 
	// 
	// Возвращаемое значение:
	//   - 
	//
	Функция Обновить(ТолькоИзмененные = Истина, Знач Источник = Неопределено) Экспорт
		УстановитьПривилегированныйРежим(Истина);
		НастройкиАвтозадач = ВсеНастройки();		
		Если Источник <> Неопределено Тогда
			ИсточникСсылка = А1Э_Метаданные.СсылкаПоИдентификатору(Источник);
			ИсточникИдентификатор = А1Э_Метаданные.ИдентификаторПоСсылке(Источник);
			ИмяМетаданныхИсточника = Источник.Метаданные().ПолноеИмя();
		КонецЕсли;
		
		Для Каждого Настройка Из НастройкиАвтозадач Цикл
			Условие = Новый Массив;
			Если Источник <> Неопределено Тогда
				Если Настройка.Источники.Найти(ИмяМетаданныхИсточника) = Неопределено Тогда Продолжить; КонецЕсли;
			КонецЕсли;
			Запрос = Новый Запрос;
			Запрос.Текст = Настройка.ТекстЗапроса;
			Если ЗначениеЗаполнено(Настройка.ПараметрыЗапроса) Тогда
				Если ТипЗнч(Настройка.ПараметрыЗапроса) = Тип("Структура") Тогда
					ПараметрыЗапроса = Настройка.ПараметрыЗапроса;
				ИначеЕсли ТипЗнч(Настройка.ПараметрыЗапроса) = Тип("Строка") Тогда
					ПараметрыЗапроса = Вычислить(Настройка.ПараметрыЗапроса + "()");
				Иначе
					А1Э_Служебный.СлужебноеИсключение("Параметры запроса автозадач должны быть структурой или строкой (именем функции, возвращающей параметры)");
				КонецЕсли;
			КонецЕсли;
			А1Э_Запросы.ПодставитьПараметрыВЗапрос(Запрос, ПараметрыЗапроса);
			АктуальныеЗадачи = Запрос.Выполнить().Выгрузить();
			ДополнитьТаблицуАктуальныхЗадач(АктуальныеЗадачи, Настройка);
			АктуальныеЗадачи.Индексы.Добавить("Вариант,Ключ");
			
			СтруктураВсехДанных = Новый Структура;
			Для Каждого Колонка Из АктуальныеЗадачи.Колонки Цикл
				СтруктураВсехДанных.Вставить(Колонка.Имя);
			КонецЦикла;
			
			Запрос = Новый Запрос;
			Запрос.Текст = ТекстЗапросаАнализаЗадач(ТолькоИзмененные);
			Запрос.УстановитьПараметр("АктуальныеЗадачи", АктуальныеЗадачи);
			Запрос.УстановитьПараметр("Варианты", Настройка.Варианты);
			Запрос.УстановитьПараметр("РучноеВыполнение", Настройка.РучноеВыполнение);
			Запрос.УстановитьПараметр("ИсточникИдентификатор", ИсточникИдентификатор);
			Выборка = Запрос.Выполнить().Выбрать();
			Пока Выборка.Следующий() Цикл
				СтруктураПоиска = Новый Структура("Вариант,Ключ");
				ЗаполнитьЗначенияСвойств(СтруктураПоиска, Выборка);
				СтрокиАктуальныхЗадач = АктуальныеЗадачи.НайтиСтроки(СтруктураПоиска);
				ВсеДанные = А1Э_Структуры.Скопировать(СтруктураВсехДанных);
				Если СтрокиАктуальныхЗадач.Количество() <> 0 Тогда
					ЗаполнитьЗначенияСвойств(ВсеДанные, СтрокиАктуальныхЗадач[0]);
				КонецЕсли;
				Если НЕ Выборка.ЗадачаАктуальна Тогда
					ЗавершитьЗадачу(Выборка, ВсеДанные);
				Иначе
					Если НЕ ЗначениеЗаполнено(Выборка.Задача) Тогда
						СоздатьЗадачу(Выборка, ВсеДанные, Настройка.Задача);
					Иначе
						ОбновитьЗадачу(Выборка, ВсеДанные, ТолькоИзмененные);
					КонецЕсли;
				КонецЕсли;
			КонецЦикла;
		КонецЦикла;
		УстановитьПривилегированныйРежим(Ложь);
	КонецФункции
	
	// Получает все настройки автозадач
	//
	// Параметры:
	//  ПовтИсп	 - Булево - признак повторного использования. Параметры запроса могут быть
	// 
	// Возвращаемое значение:
	//   - 
	//
	Функция ВсеНастройки(ПовтИсп = Ложь) Экспорт
		Если ПовтИсп = Истина Тогда Возврат А1Э_ПовторноеИспользование.РезультатФункции(ИмяМодуля() + ".ВсеНастройки", Ложь); КонецЕсли;
		
		НастройкиАвтозадач = Новый Массив;
		А1Э_Механизмы.ВыполнитьМеханизмыОбработчика("А1Автозадачи_ПриОпределенииНастроек", НастройкиАвтозадач);
		ПроверитьИДополнитьНастройки(НастройкиАвтозадач);
		Возврат НастройкиАвтозадач;
	КонецФункции
	
	// Получает настройку автозадач, соответствующую переданному варианту.
	//
	// Параметры:
	//  Вариант	 - Строка - имя варианта автозадач. 
	//  ПовтИсп	 - Булево - признак повторного использования.
	// 
	// Возвращаемое значение:
	//   - 
	//
	Функция НастройкаВарианта(Вариант, ПовтИсп = Истина) Экспорт
		Если ПовтИсп = Истина Тогда Возврат А1Э_ПовторноеИспользование.РезультатФункции(ИмяМодуля() + ".НастройкаВарианта", Вариант, Ложь); КонецЕсли;
		
		ВсеНастройки = ВсеНастройки(ПовтИсп);
		Для Каждого Настройка Из ВсеНастройки Цикл
			Если Настройка.Варианты.Найти(Вариант) = Неопределено Тогда Продолжить; КонецЕсли;
			Возврат Настройка;
		КонецЦикла;
		А1Э_Служебный.СлужебноеИсключение("Вариант " + Вариант + " не обнаружен в настройках автозадач!"); 
	КонецФункции
	
	Функция УстановитьПризнакНеЗаписывать(ЗадачаОбъект) Экспорт
		ЗадачаОбъект.ДополнительныеСвойства.Вставить("А1Автозадачи_НеЗаписывать", Истина);
	КонецФункции 
#КонецЕсли

#КонецОбласти 

#Область Механизм

Функция НастройкиМеханизма() Экспорт
	Настройки = А1Э_Механизмы.НовыйНастройкиМеханизма();
	
	Настройки.Обработчики.Вставить("А1Э_РегламентноеЗаданиеКаждыеПятьМинут", Истина);
	
	Возврат Настройки;
КонецФункции

#Если НЕ Клиент Тогда
	
	Функция А1Э_РегламентноеЗаданиеКаждыеПятьМинут() Экспорт 
		Обновить();
	КонецФункции 
	
#КонецЕсли

#КонецОбласти 

#Если НЕ Клиент Тогда
	
	Функция ПроверитьИДополнитьНастройки(НастройкиАвтозадач) 
		Для Каждого Настройка Из НастройкиАвтозадач Цикл
			Если А1Э_Структуры.Класс(Настройка) <> "А1Автозадачи_Настройка" Тогда
				А1Э_Служебный.СлужебноеИсключение("А1Авозадачи: настройка имеет неверный класс. Используйте конструктор А1Автозадачи.НовыйНастройка()");
			КонецЕсли;
			Настройка.Ключи = А1Э_Массивы.Массив(Настройка.Ключи);
			Настройка.Параметры = А1Э_Массивы.Массив(Настройка.Параметры);
			Настройка.Источники = А1Э_Массивы.Массив(Настройка.Источники);
			Настройка.Варианты = А1Э_Массивы.Массив(Настройка.Варианты);
		КонецЦикла;
	КонецФункции
	
	Функция ТекстЗапросаАнализаЗадач(ТолькоИзмененные) Экспорт
		Текст = 
		"ВЫБРАТЬ
		|	АктуальныеЗадачи.Вариант КАК Вариант,
		|	АктуальныеЗадачи.А1Автозадачи_ИсточникИдентификатор КАК Источник,
		|	АктуальныеЗадачи.Ключ КАК Ключ,
		|	АктуальныеЗадачи.Параметры КАК Параметры
		|ПОМЕСТИТЬ АктуальныеЗадачи
		|ИЗ
		|	&АктуальныеЗадачи КАК АктуальныеЗадачи
		|ГДЕ
		|	(АктуальныеЗадачи.А1Автозадачи_ИсточникИдентификатор = &ИсточникИдентификатор
		|			ИЛИ &ИсточникИдентификатор = НЕОПРЕДЕЛЕНО)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|ВЫБРАТЬ
		|	ОбщиеДанные.Вариант КАК Вариант,
		|	ОбщиеДанные.Ключ КАК Ключ,
		|	МАКСИМУМ(ОбщиеДанные.Источник) КАК Источник,
		|	МАКСИМУМ(ОбщиеДанные.Параметры) КАК Параметры,
		|	МАКСИМУМ(ОбщиеДанные.ЗадачаАктуальна) КАК ЗадачаАктуальна,
		|	МАКСИМУМ(ОбщиеДанные.Задача) КАК Задача,
		|	МАКСИМУМ(ОбщиеДанные.ВыполненаВручную) КАК ВыполненаВручную
		|ИЗ
		|	(ВЫБРАТЬ
		|		АктуальныеЗадачи.Источник КАК Источник,
		|		АктуальныеЗадачи.Вариант КАК Вариант,
		|		АктуальныеЗадачи.Ключ КАК Ключ,
		|		АктуальныеЗадачи.Параметры КАК Параметры,
		|		ИСТИНА КАК ЗадачаАктуальна,
		|		НЕОПРЕДЕЛЕНО КАК Задача,
		|		"""" КАК ПараметрыЗадачи,
		|		ЛОЖЬ КАК ВыполненаВручную
		|	ИЗ
		|		АктуальныеЗадачи КАК АктуальныеЗадачи
		|	
		|	ОБЪЕДИНИТЬ ВСЕ
		|	
		|	ВЫБРАТЬ
		|		ЗафиксированныеЗадачи.Источник,
		|		ЗафиксированныеЗадачи.Вариант,
		|		ЗафиксированныеЗадачи.Ключ,
		|		"""",
		|		ЛОЖЬ,
		|		ЗафиксированныеЗадачи.Задача,
		|		ЗафиксированныеЗадачи.Параметры,
		|		ЛОЖЬ
		|	ИЗ
		|		РегистрСведений.А1Автозадачи КАК ЗафиксированныеЗадачи
		|	ГДЕ
		|		ЗафиксированныеЗадачи.Вариант В(&Варианты)
		|		И ЗафиксированныеЗадачи.Завершена = ЛОЖЬ
		|		И (ЗафиксированныеЗадачи.Источник = &ИсточникИдентификатор
		|				ИЛИ &ИсточникИдентификатор = НЕОПРЕДЕЛЕНО)
		|	
		|	ОБЪЕДИНИТЬ ВСЕ
		|	
		|	ВЫБРАТЬ
		|		ЗафиксированныеЗадачи.Источник,
		|		ЗафиксированныеЗадачи.Вариант,
		|		ЗафиксированныеЗадачи.Ключ,
		|		"""",
		|		ЛОЖЬ,
		|		НЕОПРЕДЕЛЕНО,
		|		НЕОПРЕДЕЛЕНО,
		|		ИСТИНА
		|	ИЗ
		|		РегистрСведений.А1Автозадачи КАК ЗафиксированныеЗадачи
		|	ГДЕ
		|		&РучноеВыполнение
		|		И (ЗафиксированныеЗадачи.Источник = &ИсточникИдентификатор
		|				ИЛИ &ИсточникИдентификатор = НЕОПРЕДЕЛЕНО)
		|		И (ЗафиксированныеЗадачи.Вариант, ЗафиксированныеЗадачи.Ключ) В
		|				(ВЫБРАТЬ
		|					АктуальныеЗадачи.Вариант,
		|					АктуальныеЗадачи.Ключ
		|				ИЗ
		|					АктуальныеЗадачи)
		|		И ЗафиксированныеЗадачи.Завершена = ИСТИНА) КАК ОбщиеДанные
		|
		|СГРУППИРОВАТЬ ПО
		|	ОбщиеДанные.Вариант,
		|	ОбщиеДанные.Ключ
		|
		|ИМЕЮЩИЕ
		|	МАКСИМУМ(ОбщиеДанные.ВыполненаВручную) = ЛОЖЬ И
		|	&Условие";
		Условие = Новый Массив;
		Если ТолькоИзмененные Тогда
			Условие.Добавить("МАКСИМУМ(ОбщиеДанные.Параметры) <> МАКСИМУМ(ОбщиеДанные.ПараметрыЗадачи)");
		КонецЕсли;
		А1Э_Запросы.ПодставитьУсловие(Текст, "&Условие", Условие);
		Возврат Текст;
	КонецФункции 
	
	Функция ДополнитьТаблицуАктуальныхЗадач(АктуальныеЗадачи, Настройка)
		Если АктуальныеЗадачи.Колонки.Найти("Ключ") <> Неопределено Тогда
			А1Э_Служебный.СлужебноеИсключение("Неверный запрос автозадачи - результат запроса не может содержать колонку <Ключ>!");
		Иначе
			АктуальныеЗадачи.Колонки.Добавить("Ключ", А1Э_Строки.ОписаниеТипа(400));
		КонецЕсли;
		Если АктуальныеЗадачи.Колонки.Найти("Параметры") <> Неопределено Тогда
			А1Э_Служебный.СлужебноеИсключение("Неверный запрос автозадачи - результат запроса не может содержать колонку <Параметры>!");
		Иначе
			АктуальныеЗадачи.Колонки.Добавить("Параметры", А1Э_Строки.ОписаниеТипа(400));
		КонецЕсли;
		Если АктуальныеЗадачи.Колонки.Найти("Вариант") = Неопределено Тогда
			Если Настройка.Варианты.Количество() = 1 Тогда
				АктуальныеЗадачи.Колонки.Добавить("Вариант", А1Э_Строки.ОписаниеТипа(100));
				Вариант = Настройка.Варианты[0];
				Для Каждого Строка Из АктуальныеЗадачи Цикл
					Строка.Вариант = Вариант;
				КонецЦикла;
			Иначе
				А1Э_Служебный.СлужебноеИсключение("Неверный запрос автозадачи - результат запроса обязан содержать колонку <Вариант>!");
			КонецЕсли;
		КонецЕсли;
		
		ЕстьИсточник = АктуальныеЗадачи.Колонки.Найти("Источник") <> Неопределено;
		АктуальныеЗадачи.Колонки.Добавить("А1Автозадачи_ИсточникИдентификатор", А1Э_Строки.ОписаниеТипа(50));
		
		СтруктураКлюча = Новый Структура;
		А1Э_Структуры.ДобавитьКлючи(СтруктураКлюча, Настройка.Ключи);
		СтруктураПараметра = Новый Структура;
		А1Э_Структуры.ДобавитьКлючи(СтруктураПараметра, Настройка.Параметры);	
		
		Для Каждого Строка Из АктуальныеЗадачи Цикл
			ЗаполнитьЗначенияСвойств(СтруктураКлюча, Строка);
			СериализованныйКлюч = А1Э_Сериализация.СвернутьУниверсальныйЖСОН2(СтруктураКлюча);
			Если СтрДлина(СериализованныйКлюч) > 400 Тогда
				А1Э_Служебный.СлужебноеИсключение("В алгоритме автозадач превышена допустимая длина ключа. Уменьшите количество колонок!");
			КонецЕсли;
			Строка.Ключ = СериализованныйКлюч;
			ЗаполнитьЗначенияСвойств(СтруктураПараметра, Строка);
			СериализованныеПараметры = А1Э_Сериализация.СвернутьУниверсальныйЖСОН2(СтруктураПараметра);
			Если СтрДлина(СериализованныеПараметры) > 400 Тогда
				А1Э_Служебный.СлужебноеИсключение("В алгоритме автозадач превышена допустимая длина параметров. Уменьшите количество колонок!");
			КонецЕсли;
			Строка.Параметры = СериализованныеПараметры;
			Если ЕстьИсточник Тогда
				Строка.А1Автозадачи_ИсточникИдентификатор = А1Э_Метаданные.ИдентификаторПоСсылке(Строка.Источник);
			КонецЕсли;
		КонецЦикла;
	КонецФункции
	
	Функция СоздатьЗадачу(ДанныеЗадачи, ВсеДанные, ИмяМетаданных)
		НачатьТранзакцию();
		
		ОбъектЗадача = А1Э_Объекты.Создать(ИмяМетаданных);
		
		А1Э_Механизмы.ВыполнитьМеханизмыОбработчика("А1Автозадачи_ПриСозданииЗадачи", ОбъектЗадача, ВсеДанные);
		А1Э_Механизмы.ВыполнитьМеханизмыОбработчика("А1Автозадачи_ПриОбновленииЗадачи", ОбъектЗадача, ВсеДанные);
		
		А1Э_Объекты.Записать(ОбъектЗадача);
		
		МенеджерЗаписи = РегистрыСведений.А1Автозадачи.СоздатьМенеджерЗаписи();
		МенеджерЗаписи.Задача = А1Э_Метаданные.ИдентификаторПоСсылке(ОбъектЗадача.Ссылка);
		МенеджерЗаписи.Источник = А1Э_Метаданные.ИдентификаторПоСсылке(ДанныеЗадачи.Источник);
		МенеджерЗаписи.Вариант = ДанныеЗадачи.Вариант;
		МенеджерЗаписи.Ключ = ДанныеЗадачи.Ключ;
		МенеджерЗаписи.Параметры = ДанныеЗадачи.Параметры;
		МенеджерЗаписи.Записать();
		ЗафиксироватьТранзакцию();
	КонецФункции
	
	Функция ОбновитьЗадачу(ДанныеЗадачи, ВсеДанные, ТолькоИзмененные)
		НачатьТранзакцию();
		
		ОбъектЗадача = А1Э_Метаданные.СсылкаПоИдентификатору(ДанныеЗадачи.Задача).ПолучитьОбъект();
		
		Если НЕ ТолькоИзмененные Тогда
			А1Э_Механизмы.ВыполнитьМеханизмыОбработчика("А1Автозадачи_ПриСозданииЗадачи", ОбъектЗадача, ВсеДанные);
		КонецЕсли;
		А1Э_Механизмы.ВыполнитьМеханизмыОбработчика("А1Автозадачи_ПриОбновленииЗадачи", ОбъектЗадача, ВсеДанные);
		
		А1Э_Объекты.Записать(ОбъектЗадача);
		
		МенеджерЗаписи = РегистрыСведений.А1Автозадачи.СоздатьМенеджерЗаписи();
		МенеджерЗаписи.Задача = А1Э_Метаданные.ИдентификаторПоСсылке(ОбъектЗадача.Ссылка);
		МенеджерЗаписи.Прочитать();
		МенеджерЗаписи.Источник = А1Э_Метаданные.ИдентификаторПоСсылке(ДанныеЗадачи.Источник);
		МенеджерЗаписи.Параметры = ДанныеЗадачи.Параметры;
		МенеджерЗаписи.Записать();
		ЗафиксироватьТранзакцию();
	КонецФункции
	
	Функция ЗавершитьЗадачу(ДанныеЗадачи, ВсеДанные)
		НачатьТранзакцию();
		ОбъектЗадача = А1Э_Метаданные.СсылкаПоИдентификатору(ДанныеЗадачи.Задача).ПолучитьОбъект();
		
		А1Э_Механизмы.ВыполнитьМеханизмыОбработчика("А1Автозадачи_ПриЗавершенииЗадачи", ОбъектЗадача, ВсеДанные);
		Если НЕ А1Э_Общее.ЗначениеСвойства(ОбъектЗадача.ДополнительныеСвойства, "А1Автозадачи_НеЗаписывать") = Истина Тогда 
			//В некоторых случаях (например в ERP) выполненную задачу (пользователем вручную) повторно записать нельзя, в этом случае игнорируем запись.
			А1Э_Объекты.Записать(ОбъектЗадача);
		КонецЕсли;
		МенеджерЗаписи = РегистрыСведений.А1Автозадачи.СоздатьМенеджерЗаписи();
		МенеджерЗаписи.Задача = А1Э_Метаданные.ИдентификаторПоСсылке(ОбъектЗадача.Ссылка);
		МенеджерЗаписи.Прочитать();
		МенеджерЗаписи.Завершена = Истина;
		МенеджерЗаписи.Записать();
		ЗафиксироватьТранзакцию();
	КонецФункции
	
#КонецЕсли

Функция ИмяМодуля() Экспорт
	Возврат "А1Автозадачи";	
КонецФункции 