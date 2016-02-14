# Copyright (c) 2016, Sultan Qasim Khan
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of the <organization> nor the
#       names of its contributors may be used to endorse or promote products
#       derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# Main target
PRODUCT_NAME := example
all: $(PRODUCT_NAME)

ifeq ($(CROSS_COMPILE),)
    CROSS_COMPILE := arm-none-eabi-
endif

# Build tools
CC = $(CROSS_COMPILE)gcc
LD = $(CROSS_COMPILE)ld
OC = $(CROSS_COMPILE)objcopy
OD = $(CROSS_COMPILE)objdump
AR = $(CROSS_COMPILE)ar

# Header includes
DLIB_INCLUDE_DIRS := \
    driverlib/include \
    driverlib/board_include \
    driverlib/board_include/CMSIS
INCLUDE_DIRS := $(DLIB_INCLUDE_DIRS) include
DLIB_HEADERS := \
    $(shell find driverlib/include -type f) \
    $(shell find driverlib/board_include -type f)
HEADERS := \
    $(DLIB_HEADERS) \
    $(shell find include -type f)

# Build flags
LANG_FLAGS      := -std=c11 -Wall -Wextra -pedantic
ARM_FLAGS       := -mthumb -mcpu=cortex-m4 -mfpu=fpv4-sp-d16 -mfloat-abi=softfp
SECTION_FLAGS   := -ffunction-sections -fdata-sections
DEFINE_FLAGS    := -D__MSP432P401R__ -DUSE_CMSIS_REGISTER_FORMAT
INCLUDE_FLAGS   := $(patsubst %, -I %, $(INCLUDE_DIRS))

CFLAGS = $(LANG_FLAGS) $(ARM_FLAGS) $(SECTION_FLAGS) $(DEFINE_FLAGS) $(INCLUDE_FLAGS)

LFLAGS  := --gc-sections -T msp432.ld
OCFLAGS := -Obinary
ODFLAGS	:= -S

# Static libraries
LIB_GCC_PATH    := $(shell ${CC} ${CFLAGS} -print-libgcc-file-name)
LIBC_PATH       := $(shell ${CC} ${CFLAGS} -print-file-name=libc.a)
LIBM_PATH       := $(shell ${CC} ${CFLAGS} -print-file-name=libm.a)
LIB_MSP_PATH    := driverlib/build/libmsp432.a

LIB_PATHS = $(LIB_GCC_PATH) $(LIBC_PATH) $(LIBM_PATH) $(LIB_MSP_PATH)

# Building the driverlib
.PHONY: driverlib
driverlib: $(LIB_MSP_PATH)
DLIB_BUILD_DIR := driverlib/build
DRIVERLIB_SRCS := $(wildcard driverlib/*.c)
DRIVERLIB_OBJS := $(patsubst driverlib/%.c, $(DLIB_BUILD_DIR)/%.o, $(DRIVERLIB_SRCS))

$(DLIB_BUILD_DIR):
	mkdir -p $@

$(DLIB_BUILD_DIR)/%.o: driverlib/%.c $(DLIB_HEADERS) | $(DLIB_BUILD_DIR)
	$(CC) -c $(CFLAGS) -Dgcc $< -o $@

$(LIB_MSP_PATH): $(DRIVERLIB_OBJS) | $(DLIB_BUILD_DIR)
	$(AR) rcs $@ $^

# Building the project
BUILD_DIR := build
SRCS := $(wildcard *.c)
OBJS := $(patsubst %.c,$(BUILD_DIR)/%.o,$(SRCS))

.PHONY: dirs $(PRODUCT_NAME)

$(BUILD_DIR):
	mkdir -p $@

$(BUILD_DIR)/%.o: %.c $(HEADERS) | $(BUILD_DIR)
	$(CC) -c $(CFLAGS) $< -o $@

$(BUILD_DIR)/$(PRODUCT_NAME).axf: $(OBJS) driverlib
	$(LD) $(LFLAGS) -o $@ $(OBJS) $(LIB_PATHS)

$(BUILD_DIR)/$(PRODUCT_NAME): $(BUILD_DIR)/$(PRODUCT_NAME).axf
	$(OC) $(OCFLAGS) $< $@
	$(OD) $(ODFLAGS) $< > $@.lst

$(PRODUCT_NAME): build/$(PRODUCT_NAME)

# Cleaning
.PHONY: clean clean_driverlib cleanall
clean:
	rm -rf $(BUILD_DIR)

clean_driverlib:
	rm -rf $(DLIB_BUILD_DIR)

cleanall: clean clean_driverlib
