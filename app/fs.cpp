#include "enclave_u.h"

#include <stdio.h>

msg_code ocall_fs_write(char *filename, uint8_t *data, size_t len) {
  printf("ocall_fs_write\n");
  printf("%s : %zu Bytes\n", filename, len);
  FILE *fp = fopen(filename, "wb");
  msg_code ret = MSG_ERROR;
  if (fwrite(data, sizeof(uint8_t), len, fp) == len) {
    ret = MSG_OK;
  }
  fclose(fp);
  return ret;
}

msg_code ocall_fs_read(char *filename, uint8_t *data, size_t len) {
  printf("ocall_fs_read\n");
  FILE *fp = fopen(filename, "rb");
  msg_code ret = MSG_ERROR;
  if (fread(data, sizeof(uint8_t), len, fp) == len) {
    ret = MSG_OK;
  }
  fclose(fp);
  return ret;
}

void ocall_print_string(char *msg, uint8_t *data, size_t len) {
  printf("%s: ", msg);
  for (size_t i = 0; i < len; i++) {
    printf("%02X", data[i]);
  }
  printf("\n");
}
