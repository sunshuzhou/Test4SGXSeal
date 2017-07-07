SGX_SDK ?= /opt/intel/sgxsdk
SGX_EDGER8R := $(SGX_SDK)/bin/x64/sgx_edger8r
SGX_SIGN := $(SGX_SDK)/bin/x64/sgx_sign
SGX_LIB_PATH := $(SGX_SDK)/lib64

SIGNER_KEY_FILE := /home/sgx/certificate/private_key.pem
REENCRYPT_CONF_FILE := reencrypt/reencrypt.config.xml

TRTS_LIB := sgx_trts
URTS_LIB := sgx_urts
CRYPTO_LIB := sgx_tcrypto
SERVICE_LIB := sgx_tservice

# Put all the build file into this directory
# So we will have a clear workspace
DEST := build

# Enclave directory and enclave name
ENCLAVE_NAME := enclave
ENCLAVE_DIR  := Enclave

APP_DIR := app


#  -----------------------------------------------------
#  Build All
#  -----------------------------------------------------

all: $(DEST)/test.signed.so $(DEST)/app

#  -----------------------------------------------------
#  Build App
#  -----------------------------------------------------

APP_INC := -I$(SGX_SDK)/include -IEnclave -Iutils
APP_C_FLAGS := $(APP_INC)
APP_CPP_FLAGS := $(APP_INC) -std=c++11
APP_LINK_FLAGS := -L$(SGX_LIB_PATH) -l$(URTS_LIB) -pthread

EDL_UNTRUSTED_FILE := $(APP_DIR)/$(ENCLAVE_NAME)_u.h $(APP_DIR)/$(ENCLAVE_NAME)_u.c 
APP_ENCLAVE_SRC := app/$(ENCLAVE_NAME)_u.c
APP_ENCLAVE_OBJ := $(patsubst %.c, %.o, $(APP_ENCLAVE_SRC))
APP_SRC = $(wildcard app/*.cpp) $(wildcard utils/*.cpp) 
APP_OBJ = $(patsubst %.cpp, %.o, $(APP_SRC)) $(APP_ENCLAVE_OBJ)

$(DEST)/app: $(APP_OBJ) $(DEST)/test.signed.so 
	@echo "LINK => $@"
	@$(CXX) -o $@ $(APP_OBJ) $(APP_LINK_FLAGS)

app/main.o: app/main.cpp app/$(ENCLAVE_NAME)_u.h
	@echo "$^ => $@" 
	@$(CXX) -o $@ -c $< $(APP_CPP_FLAGS)

app/fs.o: app/fs.cpp app/$(ENCLAVE_NAME)_u.h
	@echo "$^ => $@" 
	@$(CXX) -o $@ -c $< $(APP_CPP_FLAGS)

$(APP_ENCLAVE_OBJ): $(APP_ENCLAVE_SRC)
	@echo "$^ => $@" 
	@$(CC) -o $@ -c $< $(ENCLAVE_C_FLAGS) 

$(EDL_UNTRUSTED_FILE): $(ENCLAVE_DIR)/$(ENCLAVE_NAME).edl
	@echo "$^ => $@" 
	@$(SGX_EDGER8R) $^ --untrusted --untrusted-dir app
	

#  -----------------------------------------------------
#  Build Utils
#  -----------------------------------------------------

utils/sgx-utils.o: utils/sgx-utils.cpp utils/sgx-utils.h
	@echo $^ "=>" $@
	@$(CXX) -o $@ -c $< $(APP_CPP_FLAGS) $(APP_INC) 

#  -----------------------------------------------------
#  Build Enclave
#  -----------------------------------------------------

ENCLAVE_INC := -I$(SGX_SDK)/include -I$(SGX_SDK)/include/tlibc -I$(SGX_SDK)/include/stlport -IEnclave
ENCLAVE_C_FLAGS := $(ENCLAVE_INC) -nostdinc -fvisibility=hidden -fpie -fstack-protector
ENCLAVE_LINK_FLAGS := -Wl,--no-undefined -L$(SGX_LIB_PATH) \
	-nostdlib -nodefaultlibs -nostartfiles \
	-Wl,--whole-archive -l$(TRTS_LIB) -Wl,--no-whole-archive \
	-Wl,--start-group -lsgx_tstdc -lsgx_tstdcxx -l$(CRYPTO_LIB) \
	-l$(SERVICE_LIB) -Wl,--end-group  \
	-Wl,-Bstatic -Wl,-Bsymbolic -Wl,--no-undefined \
	-Wl,-pie,-eenclave_entry -Wl,--export-dynamic \
	-Wl,--defsym,__ImageBase=0 \
	-Wl,--version-script=Enclave/test.lds

EDL_TRUSTED_FILE := $(ENCLAVE_DIR)/$(ENCLAVE_NAME)_t.h $(ENCLAVE_DIR)/$(ENCLAVE_NAME)_t.c
ENCLAVE_SRC := $(EDL_TRUSTED_FILE) $(wildcard Enclave/*.c)
ENCLAVE_OBJ := $(patsubst %.c, %.o, $(ENCLAVE_SRC))
ENCLAVE_CONFIG := Enclave/test.config.xml

$(DEST)/test.signed.so: $(DEST)/test.so $(ENCLAVE_CONFIG)
	@mkdir -p build
	@echo "SIGN => $@"
	@$(SGX_SIGN) sign -key ${SIGNER_KEY_FILE} -enclave $< -out $@ -config $(ENCLAVE_CONFIG) >/dev/null 2>/dev/null

$(DEST)/test.so: $(ENCLAVE_OBJ)
	@mkdir -p build
	@echo "LINK => $@"
	@$(CC) -o $@ $^ $(ENCLAVE_INC) $(ENCLAVE_LINK_FLAGS)

Enclave/%.o: Enclave/%.c
	@echo "CC <= $<" 
	@$(CC) -o $@ -c $< $(ENCLAVE_C_FLAGS)

$(EDL_TRUSTED_FILE): $(ENCLAVE_DIR)/$(ENCLAVE_NAME).edl
	@echo "$^ => $@" 
	@$(SGX_EDGER8R) $^ --trusted --trusted-dir Enclave

clean:
	@rm -f build/*
	@rm -f app/*.o app/*_u.* app/*_t.*
	@rm -rf Enclave/*.o Enclave/*_u.* Enclave/*_t.*
	@rm -f app/*.o
