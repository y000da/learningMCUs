;*************************************
;* Designer        
;* Version:        1.1
;* Title:          Countert.asm
;* Device          ATmega16
;* Clock frequency:Частота кв.резонатора 8 МГц 
;*************************************
; учебная
;*************************************
;(Назначение - считает число нажатий на кнопку 
;и выводит значение на семиcегментный индикатор).
;Кнопка подключена к PB4, семигегментный индикатор к PC0-PC7 
;используется индикатор PB0
;*************************************
.include "m16def.inc"; присоединение файла описаний
.list ;включение листинга
;*******************
; Register Variables
;*******************
.def temp     =R16;регистр временного хранения
.def counter  =R17;счетчик числа нажатий
.def delay1   =R18;регистры для формирования задержки
.def delay2   =R19;при подавлении дребезга контактов
.def delay3   =R20;
;*****************
;***************** 
; Constants
;*****************
.equ Val_del1=0x80;величина константы задержки
.equ Val_del2=0x38;(защитной паузы) 
.equ Val_del3=0x01;(частота 8мГц,5 тактов*80 -задержка 50 мкс)

;***********************************
;Сегмент памяти программ
.cseg
;***********************************
;Таблица векторов прерываний
;***********************************
.org $0000
rjmp Init
;****************
.org  INT0addr;=$002	;External Interrupt0 Vector Address
reti
.org  INT1addr;=$004	;External Interrupt1 Vector Address
reti
.org  OC2addr; =$006	;Output Compare2 Interrupt Vector Address
reti
.org  OVF2addr;=$008	;Overflow2 Interrupt Vector Address
reti 
.org  ICP1addr;=$00A	;Input Capture1 Interrupt Vector Address
reti
.org  OC1Aaddr;=$00C	;Output Compare1A Interrupt Vector Address
reti
.org  OC1Baddr;=$00E	;Output Compare1B Interrupt Vector Address
reti
.org  OVF1addr;=$010	;Overflow1 Interrupt Vector Address
reti
.org  OVF0addr;=$012	;Overflow0 Interrupt Vector Address
reti
.org  SPIaddr; =$014	;SPI Interrupt Vector Address
reti
.org  URXCaddr;=$016	;UART Receive Complete Interrupt Vector Address
reti
.org  UDREaddr;=$018	;UART Data Register Empty Interrupt Vector Addr
reti
.org UTXCaddr; =$01A	;UART Transmit Complete Interrupt Vector Addr
reti
.org ADCCaddr; =$01C	;ADC Interrupt Vector Address
reti
.org ERDYaddr; =$01E	;EEPROM Interrupt Vector Address
reti
.org ACIaddr;  =$020	;Analog Comparator Interrupt Vector Address
reti
.org TWIaddr;  =$022	;Irq. vector address for Two-Wire Interface
reti
.org INT2addr; =$024	;External Interrupt2 Vector Address
reti
.org OC0addr;  =$026	;Output Compare0 Interrupt Vector Address
reti
.org SPMRaddr; =$028	;Store Prog Mem Ready Interrupt Vector Address
reti

;***********************************
;Начало главной программы
;***********************************

Init:	ldi temp,LOW(RAMEND) ;Инициализация стека
	out SPL,temp ;В пару регистров SPL:SPH записывается
	ldi temp,HIGH(RAMEND) ;максимальный адрес памяти 
	out SPH,temp ;данных RAMEND

;Инициализация портов В/B
Init_B: ldi temp,0b11101111 ;PB4-вход,остальные выходы
	out DDRB,temp
	ldi temp,0b00010001 ;PB4 подт.резистор, разрешена работа 
	out PORTB,temp ;индикатора установкой PB0=1

Init_C: ser temp ;PС0...PС7 - выходы
	out DDRC,temp
	ldi temp,0b11111100 ;код "0" при включении
	out PORTC,temp
	rcall delay_DK ;Вызов подпрограммы задержки (необходима для 	;защиты от переходных процессов при
	;включении стенда - особенность самого стенда)

Init_CNT: clr counter ;сброс счетчика числа нажатий

;***********************************
;Начало основного цикла
;***********************************
Start: sbic PinB,4 ;проверка условия, что нажата кнопка
	rjmp Start ;если нет, то переход на метку Start
	inc counter ;если да, то инкремент счетчика counter
	cpi counter,16 ;проверка, что Counter=16?
	brne PC+2 ;если нет, то пропуск следующей команды
	clr counter ;если да, то установка счетчика Counter в 0

Read: ldi ZL,TABLE*2 ;загрузка в указатель Z адреса начала таблицы
	ldi ZH,0x00 ;перекодировки в памяти программ
	clr temp ;установка регистра временного хранения в 0
	add ZL,counter ;добавление к значению Z счетчика counter
	adc ZH,temp ;т.к. регистр 16-разрядный
	lpm temp,Z ;косвенное чтение в регистр temp по адресу Z
Write_C: out PORTC,temp ;загрузка нового значения в регистр PORTC
Delay1_1: rcall delay_DK ;вызов подпрограммы задержки

Key_end: sbis PinB,4 ;проверка условия, что кнопка отпущена
	rjmp Key_end ;если нет, то переход на метку Key_end
Delay2_2: rcall delay_DK ;если да, то вызов подпрограммы задержки
End_prog: rjmp Start ;завершение основного цикла и возврат к началу
;***********************************
;Конец главной программы
;***********************************

;***********************************
;Подпрограмма Delay_DK
;***********************************
Delay_DK: ldi delay1,Val_del1 ;загрузка констант
	ldi delay2,Val_del2 ;в регистры задержки
	ldi delay3,Val_del3

Cycle: subi delay1,1 ;вычитание единицы из
	sbci delay2,0 ;3-х байтного числа
	sbci delay3,0 ;цикл требует 5 тактов
	brcc Cycle ;переход на метку Cycle, если был перенос
End_deley: ret ;возврат из подпрограммы
;***********************************	
;Конец подпрограммы Delay_DK
;*********************************** 

;*********************************** 
;Таблица перекодировки символов
;***********************************
TABLE: .db 0b11111100,0b01100000 ;коды "0","1" 
       .db 0b11011010,0b11110010 ;коды "2","3" 
       .db 0b01100110,0b10110110 ;коды "4","5" 
       .db 0b10111110,0b11100000 ;коды "6","7" 
       .db 0b11111110,0b11110110 ;коды "8","9" 
       .db 0b11101110,0b00111110;;коды "A","B"  
       .db 0b10011100,0b01111010;;коды "C","D"  
       .db 0b10011110,0b10001110;;коды "E","F"
;***********************************
;Конец таблицы перекодировки символов
;***********************************   
