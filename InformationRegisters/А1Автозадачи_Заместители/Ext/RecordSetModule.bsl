﻿
Процедура ПриЗаписи(Отказ, Замещение)
	УстановитьПривилегированныйРежим(Истина);
	Если А1Автозадачи.АктивныеЗаместители() = Ложь Тогда
		Отказ = Истина;
	КонецЕсли;
КонецПроцедуры
