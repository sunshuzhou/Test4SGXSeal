#include "enclave_t.h"
#include "sgx_trts.h"
#include "sgx_tseal.h"

static uint8_t sgx_sk[32];
static uint8_t sgx_pk[32];

msg_code ecall_generate_keypair(uint8_t *pk) {
  if (SGX_SUCCESS == sgx_read_rand(pk, 32)) {
    for (int i = 0; i < 32; i++) {
      sgx_pk[i] = pk[i];
      sgx_sk[i] = ~pk[i];
    }
    ocall_print_string("[ecall_generate_keypair] Public Key", sgx_pk, 32);
    ocall_print_string("[ecall_generate_keypair] Private Key", sgx_sk, 32);
    return MSG_OK;
  }
  else return MSG_ERROR;
}

#define FILE_NAME "keypair.sealed"

msg_code ecall_seal_keypair() {
  msg_code ret = MSG_ERROR;
  size_t len = 0, add_len = 32, txt_len = 32;
  len = sgx_calc_sealed_data_size(add_len, txt_len);
  if (0xFFFFFFFF == len) {
    return ret;
  }

  ocall_print_string("[ecall_seal_keypair] Public Key", sgx_pk, 32);
  ocall_print_string("[ecall_seal_keypair] Private Key", sgx_sk, 32);

  sgx_sealed_data_t *data = (sgx_sealed_data_t *)malloc(len * sizeof(uint8_t));
  if (SGX_SUCCESS == sgx_seal_data(add_len, sgx_pk, txt_len, sgx_sk, len, data)) {
    if (SGX_SUCCESS != ocall_fs_write(&ret, FILE_NAME, (uint8_t *)data, len)) {
      ret = MSG_ERROR;
    }
  }
  free(data);
  return ret;
}
msg_code ecall_unseal_keypair(uint8_t *pk) {
  msg_code ret = MSG_ERROR;
  size_t len = 0;
  uint32_t add_len = 32, txt_len = 32;
  len = sgx_calc_sealed_data_size(add_len, txt_len);

  uint8_t *data = (uint8_t *)malloc(len * sizeof(uint8_t)), sk[32];

  if (SGX_SUCCESS == ocall_fs_read(&ret, FILE_NAME, data, len) && ret == MSG_OK) {
    if (SGX_SUCCESS == sgx_unseal_data((sgx_sealed_data_t *)data, pk, &add_len, sk, &txt_len)) {
      ocall_print_string("Unsealed Priavte Key", sk, txt_len);

      // check if unsealed sk == previous sgx_sk
      if (txt_len != 32) goto err;
      for (int i = 0; i < txt_len; i++) if (sk[i] != sgx_sk[i]) {
        goto err;
      }

    }
  }

err:
  free(data);
  return ret;
}
