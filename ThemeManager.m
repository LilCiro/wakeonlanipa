#import "ThemeManager.h"

NSString *const ThemeChangedNotification = @"ThemeChangedNotification"; // Bildirim adı

@implementation ThemeManager

+ (instancetype)sharedManager {
    static ThemeManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // Uygulama ilk açıldığında veya manager oluşturulduğunda varsayılan temayı yükle
        if (![self loadCurrentTheme]) {
            [self applyTheme:[self defaultThemes][@"Light"]]; // Hiç tema yoksa varsayılan açık tema
        }
    }
    return self;
}

- (UIColor *)colorFromHexString:(NSString *)hexString {
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    if ([hexString hasPrefix:@"#"]) {
        [scanner setScanLocation:1];
    }
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
}

- (NSDictionary *)defaultThemes {
    return @{
        @"Light": @{
            @"backgroundColor": @"#F0F0F0", // Hafif gri arka plan
            @"textColor": @"#333333",       // Koyu gri metin
            @"buttonColor": @"#007AFF",     // iOS Mavi buton
            @"statusTextColor": @"#666666",  // Orta gri durum metni
            @"fieldBackgroundColor": @"#FFFFFF", // Beyaz giriş alanı arka planı
            @"keyboardAppearance": @(UIKeyboardAppearanceDefault) // Klavye görünümü
        },
        @"Dark": @{
            @"backgroundColor": @"#333333", // Koyu gri arka plan
            @"textColor": @"#FFFFFF",       // Beyaz metin
            @"buttonColor": @"#007AFF",     // Mavi buton
            @"statusTextColor": @"#CCCCCC",  // Açık gri durum metni
            @"fieldBackgroundColor": @"#444444", // Koyu giriş alanı arka planı
            @"keyboardAppearance": @(UIKeyboardAppearanceDark) // Klavye görünümü
        },
        @"Custom": @{ // Bu kısım kullanıcı tarafından doldurulacak
            @"backgroundColor": @"#F0F0F0",
            @"textColor": @"#333333",
            @"buttonColor": @"#007AFF",
            @"statusTextColor": @"#666666",
            @"fieldBackgroundColor": @"#FFFFFF",
            @"keyboardAppearance": @(UIKeyboardAppearanceDefault)
        }
    };
}

- (NSDictionary *)loadCurrentTheme {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults dictionaryForKey:@"currentThemeSettings"];
}

- (void)applyTheme:(NSDictionary *)theme {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:theme forKey:@"currentThemeSettings"];
    [defaults synchronize]; // Değişiklikleri hemen kaydet

    // Tema değiştiğinde ilgili tüm UI'ları güncelleyebilmeleri için bildirim gönder
    // Bu, her ViewController'ın viewDidLoad/viewWillAppear içinde kendini dinlemesini sağlar.
    [[NSNotificationCenter defaultCenter] postNotificationName:ThemeChangedNotification object:nil];
}

// Bir View'a ve tüm alt görünümlerine temayı uygular (ÖNEMLİ FONKSİYON)
// Bu metot, her bir ViewController'ın viewDidLoad veya viewWillAppear içinde çağrılmalı.
- (void)applyThemeToView:(UIView *)view {
    NSDictionary *currentTheme = [self loadCurrentTheme];
    if (!currentTheme) return; // Tema yüklenemediyse bir şey yapma

    // View'ın kendi arka plan rengini ayarla
    view.backgroundColor = [[ThemeManager sharedManager] colorFromHexString:currentTheme[@"backgroundColor"]];

    // Tüm alt görünümleri dolaş ve uygun renkleri uygula
    for (UIView *subview in view.subviews) {
        if ([subview isKindOfClass:[UILabel class]]) {
            UILabel *label = (UILabel *)subview;
            if ([label.text hasPrefix:@"Sürüm:"]) { // Sürüm etiketi için farklı renk
                label.textColor = [[ThemeManager sharedManager] colorFromHexString:currentTheme[@"statusTextColor"]];
            } else {
                label.textColor = [[ThemeManager sharedManager] colorFromHexString:currentTheme[@"textColor"]];
            }
        } else if ([subview isKindOfClass:[UITextField class]]) {
            UITextField *textField = (UITextField *)subview;
            textField.textColor = [[ThemeManager sharedManager] colorFromHexString:currentTheme[@"textColor"]];
            textField.backgroundColor = [[ThemeManager sharedManager] colorFromHexString:currentTheme[@"fieldBackgroundColor"]];
            // Klavyenin görünümünü ayarla
            textField.keyboardAppearance = [[currentTheme objectForKey:@"keyboardAppearance"] integerValue];
        } else if ([subview isKindOfClass:[UIButton class]]) {
            UIButton *button = (UIButton *)subview;
            // Sıfırlama butonu gibi özel butonlar için ayrı renkler verilebilir
            if ([button.titleLabel.text isEqualToString:@"Tüm Ayarları Sıfırla"]) {
                [button setTitleColor:[UIColor redColor] forState:UIControlStateNormal]; // Kırmızı
            } else {
                [button setTitleColor:[[ThemeManager sharedManager] colorFromHexString:currentTheme[@"buttonColor"]] forState:UIControlStateNormal];
            }
            // Eğer butonun arka plan rengini de ayarlamak istersen
            // button.backgroundColor = ...
        } else if ([subview isKindOfClass:[UISegmentedControl class]]) {
            UISegmentedControl *segmentedControl = (UISegmentedControl *)subview;
            segmentedControl.tintColor = [[ThemeManager sharedManager] colorFromHexString:currentTheme[@"buttonColor"]];
            [segmentedControl setTitleTextAttributes:@{NSForegroundColorAttributeName: [[ThemeManager sharedManager] colorFromHexString:currentTheme[@"textColor"]]} forState:UIControlStateNormal];
            [segmentedControl setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]} forState:UIControlStateSelected]; // Seçili olanın metni beyaz olsun
        } else if ([subview isKindOfClass:[UITableView class]]) {
            UITableView *tableView = (UITableView *)subview;
            tableView.backgroundColor = [[ThemeManager sharedManager] colorFromHexString:currentTheme[@"backgroundColor"]];
            // TableView hücrelerinin arka planını da temaya göre ayarla
            for (UITableViewCell *cell in [tableView visibleCells]) {
                cell.backgroundColor = [[ThemeManager sharedManager] colorFromHexString:currentTheme[@"fieldBackgroundColor"]];
                cell.textLabel.textColor = [[ThemeManager sharedManager] colorFromHexString:currentTheme[@"textColor"]];
                cell.detailTextLabel.textColor = [[ThemeManager sharedManager] colorFromHexString:currentTheme[@"statusTextColor"]];
            }
        }
        // Diğer UI bileşenleri için de benzer şekilde renkleri ayarla
        // Özyinelemeli olarak alt görünümlere in
        [self applyThemeToView:subview];
    }
}

@end