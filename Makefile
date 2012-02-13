include theos/makefiles/common.mk

TWEAK_NAME = ActiShiftCaret
ActiShiftCaret_FILES = ActiShiftCaret.x
ActiShiftCaret_FRAMEWORKS = UIKit
ActiShiftCaret_LDFLAGS = -lactivator

include $(THEOS_MAKE_PATH)/tweak.mk
