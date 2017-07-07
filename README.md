# Test4Seal

Caution: **This is only for demonstration.**

**You need to install sgx in ubuntu16.04 first.**

  $> make 

  Enclave/enclave.edl => Enclave/enclave_t.h
  CC <= Enclave/enclave_t.c
  CC <= Enclave/test.c
  LINK => build/test.so
  SIGN => build/test.signed.so
  Enclave/enclave.edl => app/enclave_u.h
  app/fs.cpp app/enclave_u.h => app/fs.o
  app/main.cpp app/enclave_u.h => app/main.o
  app/enclave_u.c => app/enclave_u.o
  LINK => build/app


If success, run the command `cd build; ./app`. You will see something like this.

  [ecall_generate_keypair] Public Key: C78F04D499899002EECCD5E6B999C89A43F9755FC37F269BC16F118ED012E126
  [ecall_generate_keypair] Private Key: 3870FB2B66766FFD11332A1946663765BC068AA03C80D9643E90EE712FED1ED9
  C78F04D499899002EECCD5E6B999C89A43F9755FC37F269BC16F118ED012E126
  ecall_generate_keypair Success
  [ecall_seal_keypair] Public Key: C78F04D499899002EECCD5E6B999C89A43F9755FC37F269BC16F118ED012E126
  [ecall_seal_keypair] Private Key: 3870FB2B66766FFD11332A1946663765BC068AA03C80D9643E90EE712FED1ED9
  ocall_fs_write
  keypair.sealed : 624 Bytes
  ecall_seal_keypair Success
  ocall_fs_read
  Unsealed Priavte Key: 3870FB2B66766FFD11332A1946663765BC068AA03C80D9643E90EE712FED1ED9
  ecall_unseal_keypair Success
  Success.
