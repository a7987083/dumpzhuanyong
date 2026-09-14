#import "DZFloatWindow.h"
#import "DZFloatButton.h"
#import "DZFloatPanel.h"

@interface DZFloatCoordinator : NSObject
@property (nonatomic, strong) DZFloatWindow *window;
@property (nonatomic, strong) DZFloatButton *button;
@property (nonatomic, strong) DZFloatPanel *panel;
@property (nonatomic, strong) DZFloatRootController *rootController;
@property (nonatomic, weak) UIWindowScene *boundScene;
@property (nonatomic, assign) CGSize lastWindowSize;
@property (nonatomic, strong) NSTimer *frontTimer;
+ (instancetype)shared;
- (void)start;
@end

@implementation DZFloatCoordinator

+ (instancetype)shared {
    static DZFloatCoordinator *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ instance = [DZFloatCoordinator new]; });
    return instance;
}

- (void)start {
    [self ensureWindow];
    if (!self.frontTimer) {
        self.frontTimer = [NSTimer scheduledTimerWithTimeInterval:0.25
                                                          target:self
                                                        selector:@selector(frontTick:)
                                                        userInfo:nil
                                                         repeats:YES];
    }
}

- (void)frontTick:(NSTimer *)timer {
    (void)timer;
    [self ensureWindow];
    if (!self.window || self.window.hidden) return;

    CGSize size = self.window.bounds.size;
    if (!CGSizeEqualToSize(size, self.lastWindowSize)) {
        [self handleLayoutChange:size];
    }

    [self.window bringSubviewToFront:self.panel];
    [self.window bringSubviewToFront:self.button];
}

- (void)ensureWindow {
    UIWindowScene *scene = nil;
    if (@available(iOS 13.0, *)) scene = DZActiveWindowScene();

    if (@available(iOS 13.0, *)) {
        if (!scene) return;
        if (self.window && self.boundScene == scene) return;
    } else if (self.window) {
        return;
    }

    [self destroyWindow];
    [self createWindowForScene:scene];
}

- (void)createWindowForScene:(UIWindowScene *)scene {
    UIWindow *host = DZHostWindowForScene(scene);
    if (!host && @available(iOS 13.0, *)) return;

    DZFloatWindow *window = nil;
    if (@available(iOS 13.0, *)) {
        window = [[DZFloatWindow alloc] initWithWindowScene:scene];
        self.boundScene = scene;
    } else {
        window = [[DZFloatWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    }

    window.backgroundColor = UIColor.clearColor;
    window.opaque = NO;
    window.windowLevel = UIWindowLevelAlert - 1.0;

    DZFloatRootController *root = [DZFloatRootController new];
    root.hostWindow = host;
    __weak typeof(self) weakSelf = self;
    root.layoutChanged = ^(CGSize size) { [weakSelf handleLayoutChange:size]; };
    window.rootViewController = root;

    DZFloatButton *button = [[DZFloatButton alloc] initWithFrame:CGRectMake(20, 120, 52, 52)];
    [button setDisplayText:@"UI"];
    button.tapAction = ^{ [weakSelf togglePanel]; };

    CGSize winSize = window.bounds.size;
    CGFloat panelWidth = MIN(350.0, MAX(300.0, winSize.width - 30.0));
    CGFloat panelHeight = MIN(300.0, MAX(240.0, winSize.height - 80.0));
    DZFloatPanel *panel = [[DZFloatPanel alloc] initWithFrame:CGRectMake((winSize.width-panelWidth)*0.5,
                                                                        (winSize.height-panelHeight)*0.5,
                                                                        panelWidth,
                                                                        panelHeight)];
    panel.closeAction = ^{ weakSelf.panel.hidden = YES; };
    panel.hidden = YES;

    [window addSubview:panel];
    [window addSubview:button];
    window.floatButton = button;
    window.floatPanel = panel;

    self.window = window;
    self.button = button;
    self.panel = panel;
    self.rootController = root;
    self.lastWindowSize = window.bounds.size;

    // H5GG-style: show the overlay window without makeKeyAndVisible,
    // so the host application keeps its key window / responder ownership.
    window.hidden = NO;
    [window bringSubviewToFront:panel];
    [window bringSubviewToFront:button];
}

- (void)togglePanel {
    if (!self.panel || !self.window) return;
    self.panel.hidden = !self.panel.hidden;
    if (!self.panel.hidden) {
        [self.panel clampToSuperviewBounds];
        [self.window bringSubviewToFront:self.panel];
    }
    [self.window bringSubviewToFront:self.button];
}

- (void)handleLayoutChange:(CGSize)newSize {
    if (!self.window || newSize.width <= 0 || newSize.height <= 0) return;

    CGSize oldSize = self.lastWindowSize;
    if (oldSize.width > 0 && oldSize.height > 0 && self.button) {
        CGPoint c = self.button.center;
        c.x = c.x / oldSize.width * newSize.width;
        c.y = c.y / oldSize.height * newSize.height;
        self.button.center = c;
    }
    if (oldSize.width > 0 && oldSize.height > 0 && self.panel) {
        CGPoint c = self.panel.center;
        c.x = c.x / oldSize.width * newSize.width;
        c.y = c.y / oldSize.height * newSize.height;
        self.panel.center = c;
    }

    self.lastWindowSize = newSize;
    [self.button clampToSuperviewBounds];
    [self.panel clampToSuperviewBounds];
}

- (void)destroyWindow {
    if (self.window) self.window.hidden = YES;
    [self.button removeFromSuperview];
    [self.panel removeFromSuperview];
    self.window.floatButton = nil;
    self.window.floatPanel = nil;
    self.button = nil;
    self.panel = nil;
    self.rootController = nil;
    self.window = nil;
    self.boundScene = nil;
    self.lastWindowSize = CGSizeZero;
}

@end

__attribute__((constructor)) static void DZFloatUIEntry(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[DZFloatCoordinator shared] start];
    });
}
