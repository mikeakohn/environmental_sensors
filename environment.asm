;; Environmental sensor.
;;
;; Copyright 2019 - By Michael Kohn
;; http://www.mikekohn.net/
;; mike@mikekohn.net
;;
;; Controller for SparkFun's QWIIC Air Quality Sensor (SGP30),
;; QWIIC Temperature Sensor (TMP117), Humidity and Temperature
;; Sensor (Si7021), and 16x2 SerLCD on an MSP430G2553.

.include "msp430x2xx.inc"

RAM equ 0x0200
TMP117_DEVICE_ID_0 equ RAM+0
TMP117_DEVICE_ID_1 equ RAM+1
BME680_DEVICE_ID equ RAM+2
SGP30_DEVICE_ID_0 equ RAM+3
SGP30_DEVICE_ID_1 equ RAM+4
SGP30_DEVICE_ID_2 equ RAM+5
REGISTER equ RAM+16
I2C_SLAVE_ADDRESS equ RAM+18
DEBUG_0 equ RAM+19
DEBUG_1 equ RAM+20
TEMP equ RAM+21
RECEIVE_BUFFER equ RAM+32
SGP30_DATA equ RAM+40
TMP117_DATA equ RAM+48
SI7021_DATA equ RAM+50
;STRING equ RAM+40

UART_RX equ 0x02
UART_TX equ 0x04
I2C_SCL equ 0x40
I2C_SDA equ 0x80

;  r4 = Interrupt counter
;  r5 =
;  r6 =
;  r7 =
;  r8 =
;  r9 =
; r10 =
; r11 =
; r12 = receive buffer pointer
; r13 = function param
; r14 = function param, temp
; r15 = function param, temp, and return value

.org 0xc000
start:
  ;; Turn off watchdog
  mov.w #WDTPW|WDTHOLD, &WDTCTL

  ;; Turn off interrupts
  dint

  ;; Setup stack pointer
  mov.w #0x0400, SP

  ;; Set MCLK to 1 MHz with DCO
  mov.b #DCO_3, &DCOCTL
  mov.b #RSEL_7, &BCSCTL1
  mov.b #0, &BCSCTL2

  ;; Set SMCLK to 32.768kHz external crystal
  mov.b #XCAP_1, &BCSCTL3

  ;; Setup output pins
  ;; P1.1 = UART RX
  ;; P1.2 = UART TX
  ;; P1.6 = i2c SCL
  ;; P1.7 = i2c SDA
  mov.b #I2C_SDA|I2C_SCL, &P1DIR
  mov.b #I2C_SDA|I2C_SCL, &P1OUT
  mov.b #0, &P1REN
  mov.b #0x06, &P1SEL
  mov.b #0x06, &P1SEL2

  ;; Setup UART (9600 @ 1 MHz)
  mov.b #UCSWRST, &UCA0CTL1
  bis.b #UCSSEL_2, &UCA0CTL1
  mov.b #0, &UCA0CTL0
  mov.b #UCBRS_2, &UCA0MCTL
  mov.b #104, &UCA0BR0
  mov.b #0, &UCA0BR1
  bic.b #UCSWRST, &UCA0CTL1

  ;; Setup i2c USCI
  ;mov.b #UCSWRST, &UCB0CTL1
  ;bis.b #UCSSEL_2, &UCB0CTL1
  ;mov.b #UCMST|UCMODE_3|UCSYNC, &UCB0CTL0
  ;mov.b #10, &UCB0BR0
  ;mov.b #0, &UCB0BR1
  ;bic.b #UCSWRST, &UCB0CTL1

  ;; Setup Timer A
  ;mov.w #32768, &TACCR0
  ;mov.w #TASSEL_1|ID_0|MC_1, &TACTL ; ACLK, DIV1, COUNT to TACCR0
  ;mov.w #CCIE, &TACCTL0
  ;mov.w #0, &TACCTL1

  ;; Turn on interrupts
  eint

  ;mov.b #'|', r15
  ;call #uart_send_char
  ;mov.b #8, r15
  ;call #uart_send_char

  ;; Clear screen.
  mov.b #'|', r15
  call #uart_send_char
  mov.b #'-', r15
  call #uart_send_char

  call #delay_200ms

  ;call #setup_backlights

  mov.w #text_initializing, r15
  call #uart_send_string

  call #tmp117_get_device_id
  call #sgp30_get_device_id
  call #sgp30_init_air_quality

  ;call #delay_15s
  call #delay_2s

  ;mov.w #text_mike, r15
  ;call #uart_send_string

  ;; Clear SGP30 data buffer.
  mov.w #SGP30_DATA, r15
clear_sgp30_data:
  mov.b #0, @r15
  inc.w r15
  cmp.w #SGP30_DATA+6, r15
  jnz clear_sgp30_data

  ;; Clear TMP117 and Si7021 data.
  mov.w #0, &TMP117_DATA
  mov.w #0, &SI7021_DATA

.if 0
  call #bme680_get_device_id
  call #bme680_setup

  call #bme680_read_temperature
  ;call #bme680_read_humidity
  ;call #bme680_read_pressure
.endif

main:
  inc.w r7
  call #tmp117_read_temperature
  call #sgp30_measure_air_quality
  call #si7021_read_humidity

  call #update_screen

  call #delay_2s
  jmp main

update_screen:
  ;; Clear screen.
  mov.b #'|', r15
  call #uart_send_char
  mov.b #'-', r15
  call #uart_send_char

  mov.w #text_co2, r15
  call #uart_send_string

  mov.w &SGP30_DATA, r15
  swpb r15
  call #uart_send_number

  ;; Go to line 2.
  mov.b #254, r15
  call #uart_send_char
  mov.b #128+64, r15
  call #uart_send_char

  mov.w #text_tvoc, r15
  call #uart_send_string

  mov.b &SGP30_DATA+4, &SGP30_DATA+2
  mov.w &SGP30_DATA+2, r15
  call #uart_send_number

  ;; Go to line 1 around the middle.
  mov.b #254, r15
  call #uart_send_char
  mov.b #128+11, r15
  call #uart_send_char

  ;; Print temperature.
  mov.w &TMP117_DATA, r15
  bit.w #0x8000, r15
  jz temperature_not_negative
  mov.b #'-', r15
  call #uart_send_char
  mov.w #0, r14
  sub.w r15, r14
  mov.w r14, r15
temperature_not_negative: 
  mov.w r15, r14
  and.w #0x007f, r14
  rra.w r14
  rra.w r14
  rra.w r14
  push r14
  rla.w r15
  swpb r15
  and.b #0xff, r15
  call #uart_send_number
  mov.b #'.', r15
  call #uart_send_char
  pop r14
  add.w #div16, r14
  mov.b @r14, r15
  call #uart_send_char
  mov.b #'C', r15
  call #uart_send_char

  ;; Go to line 2 around the middle.
  mov.b #254, r15
  call #uart_send_char
  mov.b #128+64+11, r15
  call #uart_send_char

  ;; Print humidity.
  mov.w &SI7021_DATA, r15
  mov.w #0, r14
  mov.w #0, r13
  mov.w #125, r12
humidity_loop_125:
  cmp.w #0, r12
  jz humidity_loop_125_done
  dec.w r12
  add.w r15, r14
  adc.w r13
  jmp humidity_loop_125
humidity_loop_125_done:
  sub.w #6, r13
  mov.w r13, r15
  call #uart_send_number
  mov.b #'%', r15
  call #uart_send_char
  ret

.include "bme680.asm"
.include "sgp30.asm"
.include "si7021.asm"
.include "tmp117.asm"

i2c_start:
  bis.b #I2C_SDA, &P1OUT
  bis.b #I2C_SCL, &P1OUT
  nop
  nop
  nop
  nop
  bic.b #I2C_SDA, &P1OUT
  nop
  nop
  nop
  nop
  bic.b #I2C_SCL, &P1OUT
  ret

i2c_clock_out:
  mov.b #8, r14
i2c_clock_out_next:
  bic.b #I2C_SDA, &P1OUT
  bit.b #0x80, r15
  jz i2c_clock_out_zero
  bis.b #I2C_SDA, &P1OUT
i2c_clock_out_zero:
  bis.b #I2C_SCL, &P1OUT
  nop
  nop
  nop
  nop
  bic.b #I2C_SCL, &P1OUT
  rla.b r15
  dec.b r14
  jnz i2c_clock_out_next
  bic.b #I2C_SDA, &P1OUT
  ret

i2c_clock_in:
  mov.b #8, r14
  mov.b #0, r15
  bic.b #I2C_SDA, &P1DIR
i2c_clock_in_next:
  rla.w r15
  bis.b #I2C_SCL, &P1OUT
  nop
  nop
  nop
  nop
  bit.b #I2C_SDA, &P1IN
  jz i2c_clock_in_zero
  bis.b #1, r15
i2c_clock_in_zero:
  bic.b #I2C_SCL, &P1OUT
  dec.b r14
  jnz i2c_clock_in_next
  bis.b #I2C_SDA, &P1DIR
  ret

i2c_slave_ack:
  bic.b #I2C_SDA, &P1DIR
  bis.b #I2C_SCL, &P1OUT
  nop
  nop
  nop
  nop
  mov.b #0, r15
  bit.b #I2C_SDA, &P1IN
  jz i2c_slave_ack_off
  mov.b #1, r15
i2c_slave_ack_off:
  bic.b #I2C_SCL, &P1OUT
  bis.b #I2C_SDA, &P1DIR
  ret

i2c_master_ack:
  bic.b #I2C_SDA, &P1OUT
  cmp.b #1, r13
  jnz i2c_master_ack_not_nack
  bis.b #I2C_SDA, &P1OUT
i2c_master_ack_not_nack:
  bis.b #I2C_SCL, &P1OUT
  nop
  nop
  nop
  nop
  bic.b #I2C_SCL, &P1OUT
  ret

i2c_stop:
  bis.b #I2C_SCL, &P1OUT
  nop
  nop
  nop
  nop
  bis.b #I2C_SDA, &P1OUT
  ret

;; i2c_write(register=r15, data=r13, i2c_address=r14)
i2c_write:
  mov.b r15, &REGISTER
  mov.b r14, &I2C_SLAVE_ADDRESS
  rla.w r14
  call #i2c_start
  mov.b r14, r15
  call #i2c_clock_out
  call #i2c_slave_ack
  mov.b &REGISTER, r15
  call #i2c_clock_out
  call #i2c_slave_ack
  mov.b r13, r15
  call #i2c_clock_out
  call #i2c_slave_ack
  call #i2c_stop
  ret

;; i2c_read(register=r15, count=r13, i2c_address=r14)
i2c_read:
  ; First send the a sequence of start, slave address, 0, ack, register, ack.
  mov.b r14, &I2C_SLAVE_ADDRESS
  mov.b r15, &REGISTER
  call #i2c_start
  mov.b &I2C_SLAVE_ADDRESS, r15
  rla.w r15
  call #i2c_clock_out
  call #i2c_slave_ack
  mov.b &REGISTER, r15
  call #i2c_clock_out
  call #i2c_slave_ack
  call #i2c_start
  mov.b &I2C_SLAVE_ADDRESS, r15
  rla.w r15
  bis.b #1, r15
  call #i2c_clock_out
  call #i2c_slave_ack
  ; Next send the a sequence of start, slave address, 1, ack [ read, nack ]
  mov.w #RECEIVE_BUFFER, r12
i2c_read_loop:
  call #i2c_clock_in
  mov.b r15, @r12
  inc.w r12
  call #i2c_master_ack
  dec.b r13
  jnz i2c_read_loop
  call #i2c_stop
  ret

;; i2c_read_wait_nak(register=r15, count=r13, i2c_address=r14)
i2c_read_wait_nak:
  ; First send the a sequence of start, slave address, 0, ack, register, ack.
  mov.b r14, &I2C_SLAVE_ADDRESS
  mov.b r15, &REGISTER
  call #i2c_start
  mov.b &I2C_SLAVE_ADDRESS, r15
  rla.w r15
  call #i2c_clock_out
  call #i2c_slave_ack
  mov.b &REGISTER, r15
  call #i2c_clock_out
  call #i2c_slave_ack
  ; Send a start, slave read and wait for nack to go away
  mov.w #0, r6
i2c_read_wait_nak_1:
  inc.w r6
  cmp.w #0x90, r6
  jz i2c_error
  call #i2c_start
  mov.b &I2C_SLAVE_ADDRESS, r15
  rla.w r15
  bis.b #1, r15
  call #i2c_clock_out
  call #i2c_slave_ack
  cmp.b #0, r15
  jnz i2c_read_wait_nak_1
  ; Next send the a sequence of start, slave address, 1, ack [ read, nack ]
  mov.w #RECEIVE_BUFFER, r12
i2c_read_wait_nak_loop:
  call #i2c_clock_in
  mov.b r15, @r12
  inc.w r12
  call #i2c_master_ack
  dec.b r13
  jnz i2c_read_wait_nak_loop
  call #i2c_stop
  ret

i2c_error:
  mov.w #0, &RECEIVE_BUFFER
  ret

;; i2c_write_16(register=r15, data=r13, i2c_address=r14)
i2c_write_16:
  mov.w r15, &REGISTER
  mov.b r14, &I2C_SLAVE_ADDRESS
  rla.w r14
  call #i2c_start
  mov.b r14, r15
  call #i2c_clock_out
  call #i2c_slave_ack
  mov.b &REGISTER+1, r15
  call #i2c_clock_out
  call #i2c_slave_ack
  mov.b &REGISTER+0, r15
  call #i2c_clock_out
  call #i2c_slave_ack
  call #i2c_stop
  ret

;; i2c_read_16(register=r15, count=r13, i2c_address=r14)
i2c_read_16:
  ; First send the a sequence of start, slave address, 0, ack, register, ack.
  mov.b r14, &I2C_SLAVE_ADDRESS
  mov.w r15, &REGISTER
  call #i2c_start
  mov.b &I2C_SLAVE_ADDRESS, r15
  rla.w r15
  call #i2c_clock_out
  call #i2c_slave_ack
  mov.b &REGISTER+1, r15
  call #i2c_clock_out
  call #i2c_slave_ack
  mov.b &REGISTER+0, r15
  call #i2c_clock_out
  call #i2c_slave_ack
  call #delay_200ms
  call #i2c_start
  mov.b &I2C_SLAVE_ADDRESS, r15
  rla.w r15
  bis.b #1, r15
  call #i2c_clock_out
  call #i2c_slave_ack
  ; Next send the a sequence of start, slave address, 1, ack [ read, nack ]
  mov.w #RECEIVE_BUFFER, r12
i2c_read_16_loop:
  call #i2c_clock_in
  mov.b r15, @r12
  inc.w r12
  call #i2c_master_ack
  dec.b r13
  jnz i2c_read_16_loop
  call #i2c_stop
  ret

print_error:
  bis.b #UCTXSTT, &UCB0CTL1
  mov.w #text_error, r15
  call #uart_send_string
while_1:
  jmp while_1
  ret

;; uart_send_char(r15)
uart_send_char:
  bit.b #UCA0TXIFG, &IFG2
  jz uart_send_char
  mov.b r15, &UCA0TXBUF
  ret

;; uart_send_string(r15)
uart_send_string:
  mov.w r15, r14
uart_send_string_next:
  mov.b @r14+, r15
  cmp.b #0, r15
  jz uart_send_string_exit
  call #uart_send_char
  jmp uart_send_string_next
uart_send_string_exit:
  ret

;; divide_by_10(r15): r15=answer, r14=remainder
divide_by_10:
  mov.w r15, r14
  mov.w #0, r15
divide_by_10_repeat:
  cmp.w #10, r14
  jlo divide_by_10_exit
  add.w #1, r15
  sub.w #10, r14
  jmp divide_by_10_repeat
divide_by_10_exit:
  ret

;; uart_send_number(r15)
uart_send_number:
  mov.w #0, r14
  mov.w #0, r13
  ; ouch
uart_send_number_div:
  call #divide_by_10
  add.b #'0', r14
  push r14
  inc.w r13
  cmp.w #0, r15
  jnz uart_send_number_div
uart_send_number_char:
  pop r15
  call #uart_send_char
  dec.w r13
  jnz uart_send_number_char
  ret

delay_20ms:
  mov.w #7000, r15
delay_loop_20ms:
  dec.w r15
  jnz delay_loop_20ms
  ret

delay_200ms:
  mov.w #10, r14
delay_loop_200ms:
  call #delay_20ms
  dec.w r14
  jnz delay_loop_200ms
  ret

delay_2s:
  mov.b #10, r5
delay_2s_loop:
  call #delay_200ms
  dec.b r5
  jnz delay_2s_loop
  ret

;delay_2s:
;  mov.w #0, r4
;delay_2s_loop:
;  cmp.w #2, r4
;  jnz delay_2s_loop
;  ret

delay_15s:
  mov.w #0, r4
delay_15s_loop:
  cmp.w #15, r4
  jnz delay_15s_loop
  ret

setup_backlights:
  ;; Set up RGB backlights.
  mov.b #'|', r15
  call #uart_send_char
  mov.b #128, r15
  call #uart_send_char

  mov.b #'|', r15
  call #uart_send_char
  mov.b #158, r15
  call #uart_send_char

  mov.b #'|', r15
  call #uart_send_char
  mov.b #200, r15
  call #uart_send_char
  ret

i2c_status_interrupt:
  reti

i2c_data_interrupt:
  reti

timer_interrupt:
  inc.w r4
  reti

div16:
  .db '0', '0', '1', '1', '2', '3', '3', '4',
  .db '5', '5', '6', '6', '7', '8', '8', '9',

text_mike:
  .asciiz "MIKE"
text_initializing:
  .asciiz "Initializing ..."
text_co2:
  .asciiz "CO2: "
text_tvoc:
  .asciiz "TVOC: "
text_error:
  .asciiz "ERROR"

.org 0xfff2
  dw timer_interrupt       ; Timer_A2 TACCR0, CCIFG
.org 0xffee
  dw i2c_status_interrupt
.org 0xffec
  dw i2c_data_interrupt
.org 0xfffe
  dw start                 ; Reset

