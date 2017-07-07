#include <iostream>
#include <iomanip>

#include <cstdio>

#include "sgx_urts.h"

#include "enclave_u.h"
#include "sgx-utils.h"

using namespace std;

#define CHECK_STATUS(status) \
  if (SGX_SUCCESS != (status)) { \
    print_error_message((status)); \
    exit(1); \
  }

int main(int argc, char **argv) {
  sgx_launch_token_t launch_token = { 0 };
  sgx_enclave_id_t eid;
  int updated;

  CHECK_STATUS(sgx_create_enclave("test.signed.so", SGX_DEBUG_FLAG, &launch_token, &updated, &eid, nullptr));
  msg_code ret;
  uint8_t pk[32];
  CHECK_STATUS(ecall_generate_keypair(eid, &ret, pk));
  if (MSG_OK == ret) {
    for (int i = 0; i < 32; i++) {
      printf("%02X", pk[i]);
    }
    cout << endl;
    cout << "ecall_generate_keypair Success" << endl;
  }
  CHECK_STATUS(ecall_seal_keypair(eid, &ret));
  if (MSG_OK == ret) {
    cout << "ecall_seal_keypair Success" << endl;
  }
  CHECK_STATUS(ecall_unseal_keypair(eid, &ret, pk));
  if (MSG_OK == ret) {
    cout << "ecall_unseal_keypair Success" << endl;
  }
  CHECK_STATUS(sgx_destroy_enclave(eid));

  cout << "Success." << endl;

  return 0;
}
