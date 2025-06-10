#import "ThemeSelectionViewController.h"
#import "ThemeManager.h"

@interface ThemeSelectionViewController ()
@property (nonatomic, strong) UISegmentedControl *themeSegmentedControl;
// Eğer özel tema için renk giriş alanları istersen buraya ekleyebilirsin
// @property (nonatomic, strong) UITextField *customBgColorField;
// @property (nonatomic, strong) UIButton *applyCustomThemeButton;
@end

@implementation ThemeSelectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Tema Seçimi";

    // Tema değişikliği bildirimine abone ol
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleThemeChange:) name:ThemeChangedNotification object:nil];
    // Mevcut temayı uygula
    [[ThemeManager sharedManager] applyThemeToView:self.view];

    CGFloat yOffset = 100;
    CGFloat controlWidth = self.view.bounds.size.width - 40;
    CGFloat controlHeight = 40;

    // Tema Seçimi Segmented Control
    self.themeSegmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"Açık Tema", @"Koyu Tema"]]; // Şimdilik sadece Açık/Koyu
    self.themeSegmentedControl.frame = CGRectMake(20, yOffset, controlWidth, controlHeight);
    [self.themeSegmentedControl addTarget:self action:@selector(themeSegmentChanged:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.themeSegmentedControl];

    // Mevcut temayı seçili hale getir
    NSDictionary *currentTheme = [[ThemeManager sharedManager] loadCurrentTheme];
    if ([currentTheme isEqualToDictionary:[[ThemeManager sharedManager] defaultThemes][@"Light"]]) {
        self.themeSegmentedControl.selectedSegmentIndex = 0;
    } else if ([currentTheme isEqualToDictionary:[[ThemeManager sharedManager] defaultThemes][@"Dark"]]) {
        self.themeSegmentedControl.selectedSegmentIndex = 1;
    }
    // Özel tema seçeneği eklenirse buraya ekle

    // Eğer özel tema renk girişleri olacaksa burada oluştur
    // customBgColorField, customTextColorField vb.
}

- (void)dealloc {
    // Bildirim aboneliğini kaldır
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Actions

- (void)themeSegmentChanged:(UISegmentedControl *)sender {
    NSDictionary *selectedTheme = nil;
    if (sender.selectedSegmentIndex == 0) {
        selectedTheme = [[ThemeManager sharedManager] defaultThemes][@"Light"];
    } else if (sender.selectedSegmentIndex == 1) {
        selectedTheme = [[ThemeManager sharedManager] defaultThemes][@"Dark"];
    }
    // else if (sender.selectedSegmentIndex == 2) { // Özel tema seçeneği için
    //     selectedTheme = [[ThemeManager sharedManager] defaultThemes][@"Custom"];
    // }

    if (selectedTheme) {
        [[ThemeManager sharedManager] applyTheme:selectedTheme];
    }
}

// Tema değişikliği bildirimi geldiğinde
- (void)handleThemeChange:(NSNotification *)notification {
    [[ThemeManager sharedManager] applyThemeToView:self.view]; // Tüm görünüme temayı uygula
    // Segmented control'ün renklerini de güncelle
    NSDictionary *currentTheme = [[ThemeManager sharedManager] loadCurrentTheme];
    self.themeSegmentedControl.tintColor = [[ThemeManager sharedManager] colorFromHexString:currentTheme[@"buttonColor"]];
    [self.themeSegmentedControl setTitleTextAttributes:@{NSForegroundColorAttributeName: [[ThemeManager sharedManager] colorFromHexString:currentTheme[@"textColor"]]} forState:UIControlStateNormal];
    [self.themeSegmentedControl setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]} forState:UIControlStateSelected];
}

@end