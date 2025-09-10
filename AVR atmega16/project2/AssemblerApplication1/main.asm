;*************************************
;* Designer        
;* Version:        1.1
;* Title:          Countert.asm
;* Device          ATmega16
;* Clock frequency:������� ��.���������� 8 ��� 
;*************************************
; �������
;*************************************
;(���������� - ������� ����� ������� �� ������ 
;� ������� �������� �� ����c��������� ���������).
;������ ���������� � PB4, �������������� ��������� � PC0-PC7 
;������������ ��������� PB0
;*************************************
.include "m16def.inc"; ������������� ����� ��������
.list ;��������� ��������
;*******************
; Register Variables
;*******************
.def temp     =R16;������� ���������� ��������
.def counter  =R17;������� ����� �������
.def delay1   =R18;�������� ��� ������������ ��������
.def delay2   =R19;��� ���������� �������� ���������
.def delay3   =R20;
;*****************
;***************** 
; Constants
;*****************
.equ Val_del1=0x80;�������� ��������� ��������
.equ Val_del2=0x38;(�������� �����) 
.equ Val_del3=0x01;(������� 8���,5 ������*80 -�������� 50 ���)

;***********************************
;������� ������ ��������
.cseg
;***********************************
;������� �������� ����������
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
;������ ������� ���������
;***********************************

Init:	ldi temp,LOW(RAMEND) ;������������� �����
	out SPL,temp ;� ���� ��������� SPL:SPH ������������
	ldi temp,HIGH(RAMEND) ;������������ ����� ������ 
	out SPH,temp ;������ RAMEND

;������������� ������ �/B
Init_B: ldi temp,0b11101111 ;PB4-����,��������� ������
	out DDRB,temp
	ldi temp,0b00010001 ;PB4 ����.��������, ��������� ������ 
	out PORTB,temp ;���������� ���������� PB0=1

Init_C: ser temp ;P�0...P�7 - ������
	out DDRC,temp
	ldi temp,0b11111100 ;��� "0" ��� ���������
	out PORTC,temp
	rcall delay_DK ;����� ������������ �������� (���������� ��� 	;������ �� ���������� ��������� ���
	;��������� ������ - ����������� ������ ������)

Init_CNT: clr counter ;����� �������� ����� �������

;***********************************
;������ ��������� �����
;***********************************
Start: sbic PinB,4 ;�������� �������, ��� ������ ������
	rjmp Start ;���� ���, �� ������� �� ����� Start
	inc counter ;���� ��, �� ��������� �������� counter
	cpi counter,16 ;��������, ��� Counter=16?
	brne PC+2 ;���� ���, �� ������� ��������� �������
	clr counter ;���� ��, �� ��������� �������� Counter � 0

Read: ldi ZL,TABLE*2 ;�������� � ��������� Z ������ ������ �������
	ldi ZH,0x00 ;������������� � ������ ��������
	clr temp ;��������� �������� ���������� �������� � 0
	add ZL,counter ;���������� � �������� Z �������� counter
	adc ZH,temp ;�.�. ������� 16-���������
	lpm temp,Z ;��������� ������ � ������� temp �� ������ Z
Write_C: out PORTC,temp ;�������� ������ �������� � ������� PORTC
Delay1_1: rcall delay_DK ;����� ������������ ��������

Key_end: sbis PinB,4 ;�������� �������, ��� ������ ��������
	rjmp Key_end ;���� ���, �� ������� �� ����� Key_end
Delay2_2: rcall delay_DK ;���� ��, �� ����� ������������ ��������
End_prog: rjmp Start ;���������� ��������� ����� � ������� � ������
;***********************************
;����� ������� ���������
;***********************************

;***********************************
;������������ Delay_DK
;***********************************
Delay_DK: ldi delay1,Val_del1 ;�������� ��������
	ldi delay2,Val_del2 ;� �������� ��������
	ldi delay3,Val_del3

Cycle: subi delay1,1 ;��������� ������� ��
	sbci delay2,0 ;3-� �������� �����
	sbci delay3,0 ;���� ������� 5 ������
	brcc Cycle ;������� �� ����� Cycle, ���� ��� �������
End_deley: ret ;������� �� ������������
;***********************************	
;����� ������������ Delay_DK
;*********************************** 

;*********************************** 
;������� ������������� ��������
;***********************************
TABLE: .db 0b11111100,0b01100000 ;���� "0","1" 
       .db 0b11011010,0b11110010 ;���� "2","3" 
       .db 0b01100110,0b10110110 ;���� "4","5" 
       .db 0b10111110,0b11100000 ;���� "6","7" 
       .db 0b11111110,0b11110110 ;���� "8","9" 
       .db 0b11101110,0b00111110;;���� "A","B"  
       .db 0b10011100,0b01111010;;���� "C","D"  
       .db 0b10011110,0b10001110;;���� "E","F"
;***********************************
;����� ������� ������������� ��������
;***********************************   
