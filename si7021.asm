
;; Get device ID fo Si7021 (expect ?).
.if 0
si7021_get_device_id:
  mov.b #0x40, r14
  mov.b #0xfa, r15
  mov.b #0x0f, r15
  mov.b #2, r13
  call #i2c_read
  mov.b &RECEIVE_BUFFER+0, &SI7021_DEVICE_ID_0
  mov.b &RECEIVE_BUFFER+1, &SI7021_DEVICE_ID_1
  ret
.endif

si7021_read_humidity:
  mov.b #0x40, r14
  mov.b #0xf5, r15
  ;mov.b #0xf3, r15
  mov.b #2, r13
  call #i2c_read_wait_nak
  mov.b &RECEIVE_BUFFER+0, &SI7021_DATA+1
  mov.b &RECEIVE_BUFFER+1, &SI7021_DATA+0
  ret

