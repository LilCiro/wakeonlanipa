#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

extern NSString *const ThemeChangedNotification; // Tema değiştiğinde bildirim göndermek için

@interface ThemeManager : NSObject

+ (instancetype)sharedManager; // Tekil örnek (singleton)

// Renkleri hex string'den UIColor'a çevirir
- (UIColor *)colorFromHexString:(NSString *)hexString;

// Varsayılan temaları döndürür
- (NSDictionary *)defaultThemes;

// Mevcut temayı yükler
- (NSDictionary *)loadCurrentTheme;

// Yeni bir temayı kaydeder ve uygular
- (void)applyTheme:(NSDictionary *)theme;

// Tüm UI elemanlarına temayı uygula (bir görünüm ve alt görünümleri için)
- (void)applyThemeToView:(UIView *)view;

@end