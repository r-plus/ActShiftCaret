include theos/makefiles/common.mk

TWEAK_NAME = ActShiftCaret
ActShiftCaret_FILES = ActShiftCaret.x
ActShiftCaret_FRAMEWORKS = UIKit
ActShiftCaret_LDFLAGS = -lactivator

include $(THEOS_MAKE_PATH)/tweak.mk
