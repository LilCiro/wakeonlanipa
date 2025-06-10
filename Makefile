include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = WakeOnLan
WakeOnLan_FILES = main.m AppDelegate.m WOLDevice.m DeviceListViewController.m DeviceSettingsViewController.m DeveloperOptionsViewController.m ThemeSelectionViewController.m ThemeManager.m WOLManager.m
WakeOnLan_FRAMEWORKS = UIKit Foundation CoreGraphics
WakeOnLan_LIBRARIES = network
WakeOnLan_ARCHS = arm64 armv7

include $(THEOS_MAKE_FILES)/application.mk

after-install::
	install.exec "killall -9 SpringBoard"
