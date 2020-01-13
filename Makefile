#INSTALL_TARGET_PROCESSES = SpringBoard

# Comment this out to enable debug versions
#PACKAGE_VERSION=$(THEOS_PACKAGE_BASE_VERSION)

ARCHS = arm64 arm64e 
#ARCHS = x86_64 

# Target iOS 10+ Devices, and use the iOS 11.2 SDK
TARGET = iphone:clang:11.2:10.0

# Declare the location of the (patched) SDK we use
SYSROOT = $(THEOS)/sdks/iPhoneOS11.2.sdk

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Signe

dtoim = $(foreach d,$(1),-I$(d))

_IMPORTS =  $(shell /bin/ls -d ./BGNumericalGlyphRecognizer/*/)
_IMPORTS +=  $(shell /bin/ls -d ./BGNumericalGlyphRecognizer/*/*/)
_IMPORTS +=  $(shell /bin/ls -d ./BGNumericalGlyphRecognizer/*/*/*/)
_IMPORTS +=  $(shell /bin/ls -d ./BGNumericalGlyphRecognizer/*/*/*/*/)
_IMPORTS +=  $(shell /bin/ls -d ./BGNumericalGlyphRecognizer/*/*/*/*/*/)
_IMPORTS +=  $(shell /bin/ls -d ./BGNumericalGlyphRecognizer/*/*/*/*/*/*/)
_IMPORTS +=  $(shell /bin/ls -d ./SigneManager/)
_IMPORTS += $(shell /bin/ls -d ./)
IMPORTS = -I$./BGNumericalGlyphRecognizer $(call dtoim, $(_IMPORTS))

# This code treats any .m file as a source file for the tweak and compiles/links it. 

SOURCES = $(shell find BGNumericalGlyphRecognizer -name '*.m')
SOURCES += $(shell find Signemanager -name '*.m')


Signe_FILES = Signe.xm ${SOURCES}
Signe_CFLAGS += -fobjc-arc -w -Wno-deprecated-declarations $(IMPORTS)


internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/Application\ Support/Signe.bundle/$(ECHO_END)
	$(ECHO_NOTHING)cp -a BGNumericalGlyphRecognizer/Resources/. $(THEOS_STAGING_DIR)/Library/Application\ Support/Signe.bundle/$(ECHO_END)

after-install:: # Fast respring!!
	install.exec "sbreload"

include $(THEOS_MAKE_PATH)/tweak.mk
