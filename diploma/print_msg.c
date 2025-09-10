#include <string.h>
#include <stdlib.h>
#include <stdarg.h>
#include <stdint.h>

#include "stm32f10x.h"

#define DEBUG_UART USART1
#define delay for (int i=0; i<500000; i++)

static void printMsg(char *msg, ...);
uint32_t vsprintf(char *, const char *, __builtin_va_list);

static void printMsg(char *msg, ...) { 
  char buff[80]; // Буфер для сообщения
  #ifdef DEBUG_UART
  va_list args;
  va_start(args,msg);
  vsprintf(buff,msg,args);
  // Последовательно передаем на UART данные из буфера
  for(int i = 0; i < strlen(buff); i++) {
    USART1->DR = buff[i];
    //проверка на окончание передачи
    // используем операцию И с регистром статуса (USART1_SR) и 
    // битом TXE (USART_SR_TXE)
    // Т.е. пока ведется передача, мы висим в while
    while ( !( USART1->SR & USART_SR_TXE ) );
  }
  #endif
}