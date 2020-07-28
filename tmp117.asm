
.include "tmp117.inc"

;; Get device ID fo TMP117 (expect 0x0117).
tmp117_get_device_id:
  mov.b #0x48, r14
  mov.b #TMP117_DEVICE_ID, r15
  mov.b #2, r13
  call #i2c_read
  mov.b &RECEIVE_BUFFER+0, &TMP117_DEVICE_ID_0
  mov.b &RECEIVE_BUFFER+1, &TMP117_DEVICE_ID_1
  ret

tmp117_read_temperature:
  mov.b #0x48, r14
  mov.b #TMP117_TEMPERATURE, r15
  mov.b #2, r13
  call #i2c_read
  mov.b &RECEIVE_BUFFER+0, &TMP117_DATA+1
  mov.b &RECEIVE_BUFFER+1, &TMP117_DATA+0
  ret

