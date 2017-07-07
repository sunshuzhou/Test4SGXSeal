#ifndef SGX_UTILS_H
#define SGX_UTILS_H

#include "sgx_urts.h"

/* Error code returned by sgx_create_enclave */
typedef struct _sgx_errlist_t {
    sgx_status_t err;
    const char *msg;
    const char *sug; /* Suggestion */
} sgx_errlist_t;

typedef struct _sgx_context {
  sgx_enclave_id_t eid;
} sgx_context;

extern void print_error_message(sgx_status_t ret);

#endif
