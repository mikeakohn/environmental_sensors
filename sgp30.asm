
.include "sgp30.inc"

;; Get measure test ID fo SGP30.
sgp30_get_device_id:
  mov.b #0x58, r14
  mov.w #SGP30_MEASURE_TEST, r15
  ;mov.w #SGP30_MEASURE_TEST, r15
  mov.b #3, r13
  call #i2c_read_16
  mov.b &RECEIVE_BUFFER+0, &SGP30_DEVICE_ID_0
  mov.b &RECEIVE_BUFFER+1, &SGP30_DEVICE_ID_1
  mov.b &RECEIVE_BUFFER+2, &SGP30_DEVICE_ID_2
  ret

;; Init air quality on SGP30.
sgp30_init_air_quality:
  mov.b #0x58, r14
  mov.w #SGP30_INIT_AIR_QUALITY, r15
  mov.b #3, r13
  call #i2c_write_16
  ret

;; Measure air quality on SGP30.
sgp30_measure_air_quality:
  mov.b #0x58, r14
  mov.w #SGP30_MEASURE_AIR_QUALITY, r15
  mov.b #6, r13
  call #i2c_read_16
  mov.w &RECEIVE_BUFFER, SGP30_DATA
  mov.w &RECEIVE_BUFFER+2, SGP30_DATA+2
  mov.w &RECEIVE_BUFFER+4, SGP30_DATA+4
  ret

