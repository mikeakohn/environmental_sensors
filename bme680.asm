
.include "bme680.inc"

;; Get device ID fo BME680 (expect 0x61).
bme680_get_device_id:
  mov.b #0x77, r14
  mov.b #BME680_ID, r15
  mov.b #1, r13
  call #i2c_read
  mov.b &RECEIVE_BUFFER, &BME680_DEVICE_ID
  ret

;; Setup BME680
bme680_setup:
  mov.b #0x77, r14
  mov.b #BME680_CONFIG, r15
  mov.b #0, r13
  call #i2c_write

  mov.b #0x77, r14
  mov.b #BME680_CTRL_HUM, r15
  mov.b #1, r13
  call #i2c_write

  mov.b #0x77, r14
  mov.b #BME680_CTRL_MEAS, r15
  mov.b #(1 << 5)|(1 << 2)|1, r13
  call #i2c_write

  call #bme680_wait_busy
  ret

bme680_wait_busy:
  mov.b #0x77, r14
  mov.b #BME680_MEAS_STATUS_0, r15
  mov.b #3, r13
  call #i2c_read
  bit.b #0x60, &RECEIVE_BUFFER
  jnz bme680_wait_busy
  ret

;; Get temperature from BME680.
bme680_read_temperature:
  mov.b #0x77, r14
  mov.b #BME680_TEMP_MSB, r15
  mov.b #3, r13
  call #i2c_read
  ret

;; Get humidity from BME680.
bme680_read_humidity:
  mov.b #0x77, r14
  mov.b #BME680_HUM_MSB, r15
  mov.b #3, r13
  call #i2c_read
  ret

;; Get air pressure from BME680.
bme680_read_pressure:
  mov.b #0x77, r14
  mov.b #BME680_PRESS_MSB, r15
  mov.b #3, r13
  call #i2c_read
  ret

