ifndef VERBOSE
.SILENT:
endif

starting_makefile := $(abspath $(firstword $(MAKEFILE_LIST)))
mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
tmk_root := $(patsubst %/,%,$(dir $(mkfile_path)))

ifneq (,$(findstring /keyboard/,$(starting_makefile)))
	possible_keyboard:=$(patsubst %/,%,$(dir $(patsubst $(tmk_root)/keyboard/%,%,$(starting_makefile))))
	ifneq (,$(findstring /keymaps/,$(possible_keyboard)))
		KEYBOARD_DIR:=$(firstword $(subst /keymaps/, ,$(possible_keyboard)))
		KEYMAP_DIR:=$(lastword $(subst /keymaps/, ,$(possible_keyboard)))
	else
		KEYBOARD_DIR:=$(possible_keyboard)
		KEYMAP_DIR:=default
	endif
endif

# $(info $(KEYBOARD_DIR))
# $(info $(KEYMAP_DIR))
# $(info $(SUBPROJECT_DIR))

# Directory common source filess exist
TOP_DIR = $(tmk_root)
TMK_DIR = tmk_core
TMK_PATH = $(TOP_DIR)/$(TMK_DIR)

QUANTUM_DIR = quantum
QUANTUM_PATH = $(TOP_DIR)/$(QUANTUM_DIR)


ifdef keyboard
	KEYBOARD ?= $(keyboard)
endif
ifdef KEYBOARD_DIR
	KEYBOARD ?= $(KEYBOARD_DIR)
endif
ifndef KEYBOARD
	KEYBOARD=planck
endif

ifdef SUBPROJECT_DEFAULT
	SUBPROJECT=$(SUBPROJECT_DEFAULT)
endif
ifneq (,$(findstring /,$(KEYBOARD)))
	TEMP:=$(KEYBOARD)
	KEYBOARD:=$(firstword $(subst /, ,$(TEMP)))
	SUBPROJECT:=$(lastword $(subst /, ,$(TEMP)))
endif

KEYBOARD_PATH = $(TOP_DIR)/keyboard/$(KEYBOARD)
ifneq ("$(wildcard $(KEYBOARD_PATH)/$(KEYBOARD).c)","")
	KEYBOARD_FILE = keyboard/$(KEYBOARD)/$(KEYBOARD).c
	ifndef ARCH
		include $(KEYBOARD_PATH)/Makefile
	endif
else 
$(error "$(KEYBOARD_PATH)/$(KEYBOARD).c" does not exist)
endif

ifdef SUBPROJECT
	SUBPROJECT_PATH = $(TOP_DIR)/keyboard/$(KEYBOARD)/$(SUBPROJECT)
	ifneq ("$(wildcard $(SUBPROJECT_PATH)/$(SUBPROJECT).c)","")
		SUBPROJECT_FILE = keyboard/$(KEYBOARD)/$(SUBPROJECT)/$(SUBPROJECT).c
		-include $(SUBPROJECT_PATH)/Makefile
	else 
$(error "$(SUBPROJECT_PATH)/$(SUBPROJECT).c" does not exist)
	endif
endif

ifdef keymap
	KEYMAP ?= $(keymap)
endif
ifdef KEYMAP_DIR
	KEYMAP ?= $(KEYMAP_DIR)
endif
ifndef KEYMAP
	KEYMAP = default
endif
KEYMAP_PATH = $(KEYBOARD_PATH)/keymaps/$(KEYMAP)
ifneq ("$(wildcard $(KEYMAP_PATH)/keymap.c)","")
	KEYMAP_FILE = keyboard/$(KEYBOARD)/keymaps/$(KEYMAP)/keymap.c
	-include $(KEYMAP_PATH)/Makefile
else 
$(error "$(KEYMAP_PATH)/keymap.c" does not exist)
endif

ifdef SUBPROJECT
	TARGET = $(KEYBOARD)_$(SUBPROJECT)_$(KEYMAP)
else
	TARGET = $(KEYBOARD)_$(KEYMAP)
endif

ifneq ("$(wildcard $(KEYMAP_PATH)/config.h)","")
	CONFIG_H = $(KEYMAP_PATH)/config.h
else
	CONFIG_H = $(KEYBOARD_PATH)/config.h
endif


ifdef SUBPROJECT
	ifneq ("$(wildcard $(SUBPROJECT_PATH)/$(SUBPROJECT).c)","")
		CONFIG_H = $(SUBPROJECT_PATH)/config.h
	endif
endif

# # project specific files
SRC += $(KEYBOARD_FILE) \
	$(KEYMAP_FILE) \
	$(QUANTUM_DIR)/quantum.c \
	$(QUANTUM_DIR)/keymap_common.c \
	$(QUANTUM_DIR)/led.c

ifdef SUBPROJECT
	SRC += $(SUBPROJECT_FILE)
endif

ifndef CUSTOM_MATRIX
	SRC += $(QUANTUM_DIR)/matrix.c
endif

ifeq ($(strip $(AUDIO_ENABLE)), yes)
	SRC += $(QUANTUM_DIR)/audio/audio.c
	SRC += $(QUANTUM_DIR)/audio/voices.c
	SRC += $(QUANTUM_DIR)/audio/luts.c
endif

ifeq ($(strip $(RGBLIGHT_ENABLE)), yes)
	SRC += $(QUANTUM_DIR)/light_ws2812.c
	SRC += $(QUANTUM_DIR)/rgblight.c
	OPT_DEFS += -DRGBLIGHT_ENABLE
endif

# Optimize size but this may cause error "relocation truncated to fit"
#EXTRALDFLAGS = -Wl,--relax

# Search Path
VPATH += $(KEYMAP_PATH)
ifdef SUBPROJECT
	VPATH += $(SUBPROJECT_PATH)
endif
VPATH += $(KEYBOARD_PATH)
VPATH += $(TOP_DIR)
VPATH += $(TMK_PATH)
VPATH += $(QUANTUM_PATH)
VPATH += $(QUANTUM_PATH)/keymap_extras
VPATH += $(QUANTUM_PATH)/audio

include $(TMK_PATH)/protocol/lufa.mk
include $(TMK_PATH)/common.mk
include $(TMK_PATH)/rules.mk