#include <stdint.h>

#include "math.h"
#include "stm32f10x.h"

#include "print_msg.c"
#include "data_processing.c"

#define Num_Samples 85
#define CORE_CLOCK 560000000

volatile uint32_t msTicks = 0;
static uint32_t buff_adc_flag = 0;

void delayMs(int ms);
void ADC1_2_IRQHandler(void);
void SysTick_Handler(void);
void DMA1_Channel1_IRQHandler(void);
void adcStop(void);
void adcStart(void);

int main(void) {
  // Конфигурация системного таймера и настройка тактовой частоты МК
  SysTick_Config(CORE_CLOCK/1000);
  RCC->CFGR |= RCC_CFGR_PLLSRC_HSE;
  RCC->CFGR |= RCC_CFGR_PLLMULL7;
  RCC->CFGR |= RCC_CFGR_SW_PLL;
  RCC->CFGR |= RCC_CFGR_HPRE_DIV1;
  RCC->CFGR |= RCC_CFGR_PPRE1_DIV2;
  RCC->CFGR |= RCC_CFGR_PPRE2_DIV1;
 
  // Конфигурация TIM3
  RCC->APB1ENR |= RCC_APB1ENR_TIM3EN; // Разрешаем тактирование таймера
  TIM3->PSC = 0;                      // Предделитель и значение,                                   
  TIM3->ARR  = 140;                   // до которого считает таймер
  TIM3->CR2 |= TIM_CR2_MMS_1;         // Разрешаем генерацию TRGO
  TIM3->CR1 |= TIM_CR1_CEN;           // Включаем таймер
 
  // Конфигурация DMA
  RCC->AHBENR |= RCC_AHBENR_DMA1EN;                 // Тактирование DMA
  DMA1_Channel1->CPAR = (uint32_t)(&(ADC1->DR));    // Адрес регистра данных АЦП
  DMA1_Channel1->CMAR = (uint32_t)&ADCDualConvertedValue; // Адрес переменной
  DMA1_Channel1->CCR &= ~( DMA_CCR1_DIR );  // Направление передачи 
  DMA1_Channel1->CNDTR = Num_Samples;       // Количество пересылаемых значений
  DMA1_Channel1->CCR &= ~( DMA_CCR1_PINC ); // Не инкрементируем адрес переферии
  DMA1_Channel1->CCR |= DMA_CCR1_MINC;      // Инкрементация памяти
  DMA1_Channel1->CCR |= DMA_CCR1_PSIZE_1;   // Размер данных периферии
  DMA1_Channel1->CCR |= DMA_CCR1_MSIZE_1;   // Размер данных памяти
  DMA1_Channel1->CCR |= DMA_CCR1_CIRC;      // Режим циркуляции да/нет
  DMA1_Channel1->CCR |= DMA_CCR1_PL;        // Приоритет
  DMA1_Channel1->CCR |= DMA_CCR1_TCIE;      // Прерывания DMA
  NVIC_EnableIRQ(DMA1_Channel1_IRQn);
  DMA1_Channel1->CCR |= DMA_CCR1_EN;        // Включение DMA
 
  // Конфигурация ADC1 и USART1
  RCC->CFGR |= RCC_CFGR_ADCPRE_DIV6;        // Настройка частоты АЦП (12 МГц)
 
  // Тактирование выводов I/O portA, portB, альтернативные функции, USART1, ADC1
  RCC->APB2ENR |= RCC_APB2ENR_IOPAEN | RCC_APB2ENR_IOPBEN | \ 
  RCC_APB2ENR_AFIOEN | RCC_APB2ENR_USART1EN;
  RCC->APB2ENR |= RCC_APB2ENR_ADC1EN;
 
  // Конфигурация пинов
  // 9 пин порта А как выход для UART
  // 1 пин порта А как аналоговый вход для АЦП
  // 0 пин порта Б как выход
  GPIOA->CRH |= GPIO_CRH_CNF9_1 | GPIO_CRH_MODE9_0 | GPIO_CRH_MODE9_1;
  GPIOA->CRH &= ~GPIO_CRH_CNF9_0;
  GPIOA->CRL &= ~(GPIO_CRL_CNF1_0);
  GPIOB->CRL |= GPIO_CRL_MODE9_0 | GPIO_CRL_MODE9_1;
 
  // Прерывания от АЦП
  //ADC1->CR1 |= ADC_CR1_EOCIE;
  //NVIC_EnableIRQ(ADC1_2_IRQn);

  ADC1->CR2 &= ADC_CR2_EXTSEL;  // Разрешение внешнего запуска
  ADC1->CR2 = ADC_CR2_EXTSEL_2 | ADC_CR2_EXTTRIG;
  ADC1->CR2 = ADC_CR2_DMA;      //Разрешение доступа по DMA
  
  // Установка режима DUALMOD
  // 0110: Regular simultaneous mode only
  ADC1->CR1 |= ADC_CR1_DUALMOD_1 | ADC_CR1_DUALMOD_2; 
 
  // Настройка времени преобразования
  // 110: 71,5 циклов
  ADC1->SMPR2 |= ADC_SMPR2_SMP1_2 | ADC_SMPR2_SMP1_1;
 
  // Настройка количества каналов и очередность опроса
  ADC1->SQR3 = 1<<0;
 
  // Первое включение и continuous режим
  ADC1->CR2 |= ADC_CR2_ADON | ADC_CR2_CONT;
  delayMs(1);
 
  // Второе включение и калибровка 
  ADC1->CR2 |= ADC_CR2_ADON;
  delayMs(1);
  ADC1->CR2 |= ADC_CR2_CAL;
  delayMs(1);
 
  // Настройка USART1 (см printMsg.c)
  USART1->BRR = 0x1d4c;
  USART1->CR1 |= USART_CR1_TE;
  USART1->CR1 |= USART_CR1_UE;
 
  //Для светодиода
  //RCC->APB2ENR |= RCC_APB2ENR_IOPCEN;
  //GPIOC->CRH |= GPIO_CRH_MODE13_1 | GPIO_CRH_MODE13_0;
 
  // Конфигурация ADC2
  RCC->APB2ENR |= RCC_APB2ENR_ADC2EN; // Тактирование ADC2
 
  // Конфигурация пинов
  // 2 пин порта А как аналоговый вход для АЦП
  GPIOA->CRL &= ~(GPIO_CRL_CNF2_0);
 
  // Время преобразования
  ADC2->SMPR2 |= ADC_SMPR2_SMP2_2 | ADC_SMPR2_SMP2_1| ADC_SMPR2_SMP2_0;
 
  //Настройка количества каналов и очередность опроса
  ADC2->SQR3 |= 2<<0;
 
  // Разрешение внешнего запуска
  // Разрешаем внешний запуск, при этом триггером ставим SWSTART (111)
  ADC2->CR2 |= ADC_CR2_EXTTRIG;
  ADC2->CR2 |= ADC_CR2_EXTSEL_0 | ADC_CR2_EXTSEL_1 | ADC_CR2_EXTSEL_2;
 
  //Первое включение и continuous режим
  ADC2->CR2 |= ADC_CR2_ADON | ADC_CR2_CONT;
  delayMs(1);
 
  //Второе включение и калибровка 
  ADC2->CR2 |= ADC_CR2_ADON;
  delayMs(1);
  ADC2->CR2 |= ADC_CR2_CAL;
  delayMs(1);
 
  static uint32_t ADCDualConvertedValue[Num_Samples];
  static double ADC1_data[Num_Samples];
  static double ADC2_data[Num_Samples];
  static double phase[Num_Samples];

  // Основной цикл while
  while(1) {
    if (buff_adc_flag == 1) {
      adcStop();
      for (uint32_t i = 0; i < Num_Samples; i++) {
        //Разделение данных
        ADC1_data[i] = (ADCDualConvertedValue[i] & 0x0000FFFF)*3.3/4096;
        ADC2_data[i] = ((ADCDualConvertedValue[i] & 0xFFFF0000) >> 16)*3.3/4096;
        phase[i] = atan2(ADC1_data[i],ADC2_data[i]);
      }
      if (dataProcessing(phase)) { GPIOB0->BSRR |= GPIO_BSRR_BS0; };
    }
  }
}

//void ADC1_2_IRQHandler(void)
//{
// 
// if(ADC1->SR & ADC_SR_EOC)
// {
//  
//  val = ADC1->DR;
//  
// }
//}

//Обработчик прерываний DMA
void DMA1_Channel1_IRQHandler(void) {
  DMA1->IFCR = DMA_IFCR_CGIF1;  // Очистка всех флагов прерываний
  buff_adc_flag = 1;            // Флаг заполнения буфера
}

//Миллисекундная задержка
void delayMs(int ms) {
  msTicks = 0;
  while (msTicks < ms);
}

//Обработчик прерываний SysTick
void SysTick_Handler(void) {
  msTicks++;
}

//Запуск АЦП
void adcStart(void) {
  buff_adc_flag = 0;
  TIM3->CR1 |= TIM_CR1_CEN;
}

//Остановка АЦП
void adcStop(void) {
  TIM3->CR1 &= ~( TIM_CR1_CEN );
}
