#import <UIKit/UIKit.h>
#import "WOLDevice.h" // Cihaz modelini dahil et

@interface DeviceSettingsViewController : UIViewController

@property (nonatomic, strong) WOLDevice *device; // Düzenlenecek cihaz (nil ise yeni cihaz)
@property (nonatomic, strong) NSString *groupID; // Cihazın hangi gruba ait olacağı (yeni cihazlar için)

// Başlatıcılar
- (instancetype)initWithDevice:(WOLDevice *)device; // Mevcut cihazı düzenlemek için
- (instancetype)initWithDevice:(WOLDevice *)device groupID:(NSString *)groupID; // Yeni cihaz eklemek veya düzenlemek için

@end