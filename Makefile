include $(THEOS)/makefiles/common.mk
# ...
include $(THEOS_MAKE_FILES)/application.mk
```Makefile` dosyanızda bu yolların **doğru** şekilde yazıldığından emin olmanız gerekiyor. Yani `include /application.mk` gibi **sadece `/application.mk` yazmamalı, mutlaka `$(THEOS_MAKE_FILES)` veya `$(THEOS)/makefiles` şeklinde değişkenleri kullanmalıdır.**

**Yapmanız gereken tek şey:**

1.  GitHub deponuzda, `WakeOnLanApp` (veya Theos proje klasörünüzün adı neyse) klasörünüzün içindeki **`Makefile` dosyasını açın.**
2.  İçeriğini **tamamen** aşağıdaki kodla değiştirin. Bu, daha önce size verdiğim doğru `Makefile` içeriğidir.

```makefile
include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = WakeOnLan
WakeOnLan_FILES = main.m AppDelegate.m WOLDevice.m DeviceListViewController.m DeviceSettingsViewController.m DeveloperOptionsViewController.m ThemeSelectionViewController.m ThemeManager.m WOLManager.m
WakeOnLan_FRAMEWORKS = UIKit Foundation CoreGraphics
WakeOnLan_LIBRARIES = network
WakeOnLan_ARCHS = arm64 armv7

include $(THEOS_MAKE_FILES)/application.mk

after-install::
	install.exec "killall -9 SpringBoard"