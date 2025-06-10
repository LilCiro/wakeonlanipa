#import "AppDelegate.h"
#import "DeviceListViewController.h"
#import "ThemeManager.h" // Tema Manager'ı burada da başlatabiliriz

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    // Tab Bar Controller'ı oluştur
    self.tabBarController = [[UITabBarController alloc] init];
    self.tabBarController.delegate = self;

    // İlk sekme (Ana Grup)
    DeviceListViewController *group1VC = [[DeviceListViewController alloc] initWithGroupID:@"Group1" groupName:@"Ana Grup"];
    UINavigationController *nav1 = [[UINavigationController alloc] initWithRootViewController:group1VC];
    nav1.tabBarItem.title = @"Ana Grup";
    nav1.tabBarItem.image = [UIImage systemImageNamed:@"house.fill"]; // Bir ikon ekleyelim (iOS 13+ için)

    // İkinci sekme (Ofis Cihazları)
    DeviceListViewController *group2VC = [[DeviceListViewController alloc] initWithGroupID:@"Group2" groupName:@"Ofis Cihazları"];
    UINavigationController *nav2 = [[UINavigationController alloc] initWithRootViewController:group2VC];
    nav2.tabBarItem.title = @"Ofis";
    nav2.tabBarItem.image = [UIImage systemImageNamed:@"building.2.fill"];

    // Üçüncü sekme (Oyun Bilgisayarları)
    DeviceListViewController *group3VC = [[DeviceListViewController alloc] initWithGroupID:@"Group3" groupName:@"Oyun Bilgisayarları"];
    UINavigationController *nav3 = [[UINavigationController alloc] initWithRootViewController:group3VC];
    nav3.tabBarItem.title = @"Oyun";
    nav3.tabBarItem.image = [UIImage systemImageNamed:@"gamecontroller.fill"];

    // İsteğe bağlı olarak daha fazla sekme ekleyebilirsin
    // DeviceListViewController *group4VC = ...
    // UINavigationController *nav4 = ...

    self.tabBarController.viewControllers = @[nav1, nav2, nav3]; // Tüm sekmeleri ekle

    self.window.rootViewController = self.tabBarController;
    [self.window makeKeyAndVisible];

    // Tema yöneticisini başlat (varsayılan tema ayarlanır)
    [ThemeManager sharedManager];

    // Uygulama genelinde temayı uygula
    // (UITabBarController'ın kendisini ve tüm view controller'ları etkiler)
    [[ThemeManager sharedManager] applyThemeToView:self.window];

    // Tema değişikliği bildirimine abone ol
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleThemeChange:) name:ThemeChangedNotification object:nil];
    
    return YES;
}

- (void)dealloc {
    // Uygulama kapanırken bildirimi kaldır
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

// Tema değiştiğinde tüm UI'ı güncelle
- (void)handleThemeChange:(NSNotification *)notification {
    [[ThemeManager sharedManager] applyThemeToView:self.window];
    // Ayrıca Tab Bar'ın kendisi için de özel ayarlamalar gerekebilir
    NSDictionary *currentTheme = [[ThemeManager sharedManager] loadCurrentTheme];
    self.tabBarController.tabBar.barTintColor = [[ThemeManager sharedManager] colorFromHexString:currentTheme[@"backgroundColor"]];
    self.tabBarController.tabBar.tintColor = [[ThemeManager sharedManager] colorFromHexString:currentTheme[@"buttonColor"]]; // Seçili ikon/metin rengi
    self.tabBarController.tabBar.unselectedItemTintColor = [[ThemeManager sharedManager] colorFromHexString:currentTheme[@"statusTextColor"]]; // Seçili olmayan ikon/metin rengi
}


// Uygulama arka plana geçtiğinde veya kapandığında (opsiyonel)
- (void)applicationWillResignActive:(UIApplication *)application {
    // Uygulama aktif değilken yapılacak işlemler
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Uygulama arka plana girdiğinde yapılacak işlemler
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Uygulama arka plandan ön plana dönerken yapılacak işlemler
    // Temanın tekrar uygulanması için burada çağrılabilir
    [[ThemeManager sharedManager] applyThemeToView:self.window];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Uygulama aktif olduğunda yapılacak işlemler
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Uygulama sonlanırken yapılacak işlemler
}

@end