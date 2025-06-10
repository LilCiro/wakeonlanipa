#import "DeveloperOptionsViewController.h"
#import "ThemeManager.h" // Tema yönetimini kullanmak için

@interface DeveloperOptionsViewController ()
@property (nonatomic, strong) UIButton *resetButton;
@property (nonatomic, strong) UILabel *countdownLabel; // Geri sayım için
@property (nonatomic, strong) NSTimer *resetTimer; // Geri sayım sayacı
@property (nonatomic, assign) NSInteger countdownValue; // Geri sayım değeri
@end

@implementation DeveloperOptionsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Geliştirici Seçenekleri";
    
    // Sağ üst köşeye "Kapat" butonu
    UIBarButtonItem *closeButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(closeOptions)];
    self.navigationItem.rightBarButtonItem = closeButton;

    // Tema değişikliği bildirimine abone ol
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleThemeChange:) name:ThemeChangedNotification object:nil];
    // Mevcut temayı uygula
    [[ThemeManager sharedManager] applyThemeToView:self.view];


    CGFloat yOffset = 100;
    CGFloat buttonWidth = self.view.bounds.size.width - 40;
    CGFloat buttonHeight = 50;
    CGFloat spacing = 20;

    // "Tüm Ayarları Sıfırla" Butonu
    self.resetButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.resetButton.frame = CGRectMake(20, yOffset, buttonWidth, buttonHeight);
    [self.resetButton setTitle:@"Tüm Ayarları Sıfırla" forState:UIControlStateNormal];
    [self.resetButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal]; // Kırmızı renk
    [self.resetButton addTarget:self action:@selector(resetAllSettingsTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.resetButton];
    yOffset += buttonHeight + spacing;

    // Geri sayım etiketi
    self.countdownLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, yOffset, buttonWidth, 40)];
    self.countdownLabel.textAlignment = NSTextAlignmentCenter;
    self.countdownLabel.textColor = [[ThemeManager sharedManager] colorFromHexString:[[ThemeManager sharedManager] loadCurrentTheme][@"statusTextColor"]];
    self.countdownLabel.hidden = YES; // Başlangıçta gizli
    [self.view addSubview:self.countdownLabel];
}

- (void)dealloc {
    // Timer'ı durdur (önemli!)
    [self.resetTimer invalidate];
    self.resetTimer = nil;
    // Bildirim aboneliğini kaldır
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Actions

- (void)closeOptions {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)resetAllSettingsTapped {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Emin Misin?" message:@"Bu işlem, tüm cihazlarınızı ve uygulama ayarlarınızı siler. Geri alınamaz!" preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:[UIAlertAction actionWithTitle:@"Sil" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        // Geri sayımı başlat
        self.countdownValue = 5;
        self.countdownLabel.text = [NSString stringWithFormat:@"%ld", (long)self.countdownValue];
        self.countdownLabel.hidden = NO;
        self.resetButton.enabled = NO; // Butonu devre dışı bırak

        self.resetTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateCountdown) userInfo:nil repeats:YES];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"İptal" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        self.countdownLabel.hidden = YES;
        self.resetButton.enabled = YES;
        [self.resetTimer invalidate];
        self.resetTimer = nil;
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)updateCountdown {
    self.countdownValue--;
    if (self.countdownValue > 0) {
        self.countdownLabel.text = [NSString stringWithFormat:@"%ld", (long)self.countdownValue];
    } else {
        [self.resetTimer invalidate]; // Timer'ı durdur
        self.resetTimer = nil;
        self.countdownLabel.hidden = YES;
        self.resetButton.enabled = YES; // Butonu tekrar etkinleştir

        // Tüm ayarları sıfırla
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        // Uygulamaya özel tüm NSUserDefaults verilerini sil
        NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
        [defaults removePersistentDomainForName:appDomain];
        [defaults synchronize]; // Değişiklikleri hemen kaydet

        // Tema ayarlarını varsayılana çek (çünkü tümü silindi)
        [[ThemeManager sharedManager] applyTheme:[[ThemeManager sharedManager] defaultThemes][@"Light"]];

        // Kullanıcıya bilgi ver ve uygulamayı yeniden başlatmasını iste
        UIAlertController *doneAlert = [UIAlertController alertControllerWithTitle:@"Ayarlar Sıfırlandı" message:@"Tüm ayarlar sıfırlandı. Değişikliklerin tam olarak uygulanması için uygulamayı yeniden başlatın." preferredStyle:UIAlertControllerStyleAlert];
        [doneAlert addAction:[UIAlertAction actionWithTitle:@"Tamam" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            // İsteğe bağlı: Uygulamayı kapatmaya zorla veya ana ekrana dön
            exit(0); // Uygulamayı kapatır
        }]];
        [self presentViewController:doneAlert animated:YES completion:nil];
    }
}

// Tema değişikliği bildirimi geldiğinde
- (void)handleThemeChange:(NSNotification *)notification {
    [[ThemeManager sharedManager] applyThemeToView:self.view]; // Tüm görünüme temayı uygula
    // Etiket rengini güncelle
    self.countdownLabel.textColor = [[ThemeManager sharedManager] colorFromHexString:[[ThemeManager sharedManager] loadCurrentTheme][@"statusTextColor"]];
}

@end