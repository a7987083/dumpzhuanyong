#import "DZAdTrace.h"
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/message.h>

static const NSInteger kDZDashboardTag = 0x445A4154;

@interface DZAdTraceDashboard : UIView
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UILabel *lastLabel;
@property (nonatomic, strong) UILabel *recentLabel;
@property (nonatomic, strong) UIButton *toggleButton;
- (void)refresh;
@end

@implementation DZAdTraceDashboard

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;

    self.backgroundColor = [UIColor colorWithRed:0.055 green:0.06 blue:0.075 alpha:1.0];
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectZero];
    title.text = [NSString stringWithFormat:@"AD Trace %@", DZAdTraceVersion];
    title.textColor = UIColor.whiteColor;
    title.font = [UIFont boldSystemFontOfSize:13.0];
    [self addSubview:title];

    _statusLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _statusLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.72];
    _statusLabel.font = [UIFont monospacedSystemFontOfSize:10.5 weight:UIFontWeightRegular];
    _statusLabel.numberOfLines = 2;
    [self addSubview:_statusLabel];

    _toggleButton = [self buttonWithTitle:@"Trace ON" action:@selector(toggleTapped:)];
    [self addSubview:_toggleButton];

    UIButton *rescan = [self buttonWithTitle:@"Rescan" action:@selector(rescanTapped:)];
    [self addSubview:rescan];

    UIButton *clear = [self buttonWithTitle:@"Clear" action:@selector(clearTapped:)];
    [self addSubview:clear];

    UIButton *copy = [self buttonWithTitle:@"Copy Log" action:@selector(copyTapped:)];
    [self addSubview:copy];

    UILabel *lastHeader = [[UILabel alloc] initWithFrame:CGRectZero];
    lastHeader.text = @"Last event";
    lastHeader.textColor = [UIColor colorWithWhite:1.0 alpha:0.48];
    lastHeader.font = [UIFont systemFontOfSize:10.0 weight:UIFontWeightSemibold];
    [self addSubview:lastHeader];

    _lastLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _lastLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.90];
    _lastLabel.font = [UIFont monospacedSystemFontOfSize:10.0 weight:UIFontWeightRegular];
    _lastLabel.numberOfLines = 3;
    _lastLabel.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.20];
    _lastLabel.layer.cornerRadius = 7.0;
    _lastLabel.layer.masksToBounds = YES;
    [self addSubview:_lastLabel];

    _recentLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _recentLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.70];
    _recentLabel.font = [UIFont monospacedSystemFontOfSize:9.0 weight:UIFontWeightRegular];
    _recentLabel.numberOfLines = 5;
    [self addSubview:_recentLabel];

    title.tag = 1001;
    rescan.tag = 1002;
    clear.tag = 1003;
    copy.tag = 1004;
    lastHeader.tag = 1005;

    [self refresh];
    return self;
}

- (UIButton *)buttonWithTitle:(NSString *)title action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:10.5 weight:UIFontWeightSemibold];
    button.backgroundColor = [UIColor colorWithRed:0.18 green:0.32 blue:0.62 alpha:0.95];
    button.layer.cornerRadius = 6.0;
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat width = CGRectGetWidth(self.bounds);
    UILabel *title = [self viewWithTag:1001];
    UIButton *rescan = [self viewWithTag:1002];
    UIButton *clear = [self viewWithTag:1003];
    UIButton *copy = [self viewWithTag:1004];
    UILabel *lastHeader = [self viewWithTag:1005];

    title.frame = CGRectMake(14, 8, width - 28, 20);
    self.statusLabel.frame = CGRectMake(14, 28, width - 28, 32);

    CGFloat gap = 7.0;
    CGFloat buttonWidth = floor((width - 28.0 - gap * 3.0) / 4.0);
    CGFloat x = 14.0;
    self.toggleButton.frame = CGRectMake(x, 65, buttonWidth, 30); x += buttonWidth + gap;
    rescan.frame = CGRectMake(x, 65, buttonWidth, 30); x += buttonWidth + gap;
    clear.frame = CGRectMake(x, 65, buttonWidth, 30); x += buttonWidth + gap;
    copy.frame = CGRectMake(x, 65, buttonWidth, 30);

    lastHeader.frame = CGRectMake(14, 101, width - 28, 17);
    self.lastLabel.frame = CGRectMake(14, 119, width - 28, 52);
    self.recentLabel.frame = CGRectMake(14, 178, width - 28, MAX(42.0, CGRectGetHeight(self.bounds) - 184.0));
}

- (NSString *)eventLine:(NSDictionary *)event {
    if (!event.count) return @"<waiting>";
    NSString *placement = event[@"placementID"] ?: @"";
    NSString *provider = event[@"provider"] ?: @"";
    NSMutableString *line = [NSMutableString stringWithFormat:@"#%@ %@ / %@",
                             event[@"seq"] ?: @"?",
                             event[@"kind"] ?: @"unknown",
                             event[@"stage"] ?: @"event"];
    if (placement.length) [line appendFormat:@"\nP: %@", placement];
    if (provider.length) [line appendFormat:@"  N: %@", provider];
    return line;
}

- (void)refresh {
    NSDictionary *snapshot = DZAdTraceSnapshot();
    BOOL enabled = DZAdTraceIsEnabled();
    [self.toggleButton setTitle:(enabled ? @"Trace ON" : @"Trace OFF") forState:UIControlStateNormal];
    self.toggleButton.alpha = enabled ? 1.0 : 0.55;
    self.statusLabel.text = [NSString stringWithFormat:@"hooks:%lu   events:%lu   state:%@\nlog: Documents/DumpZhuanYong_AdTrace_v2.jsonl",
                             (unsigned long)DZAdTraceHookCount(),
                             (unsigned long)[snapshot[@"eventCount"] unsignedIntegerValue],
                             enabled ? @"recording" : @"paused"];
    self.lastLabel.text = [@"  " stringByAppendingString:[self eventLine:snapshot[@"lastEvent"] ?: @{}]];

    NSArray<NSDictionary *> *recent = DZAdTraceRecentEvents(5);
    NSMutableArray<NSString *> *lines = [NSMutableArray array];
    for (NSDictionary *event in recent) {
        NSString *provider = event[@"provider"] ?: @"";
        NSString *placement = event[@"placementID"] ?: @"";
        NSString *line = [NSString stringWithFormat:@"#%@ %@:%@%@%@",
                          event[@"seq"] ?: @"?",
                          event[@"kind"] ?: @"?",
                          event[@"stage"] ?: @"?",
                          placement.length ? [@" P=" stringByAppendingString:placement] : @"",
                          provider.length ? [@" N=" stringByAppendingString:provider] : @""];
        [lines addObject:line];
    }
    self.recentLabel.text = lines.count ? [lines componentsJoinedByString:@"\n"] : @"No ad events yet.";
}

- (void)toggleTapped:(id)sender {
    (void)sender;
    DZAdTraceSetEnabled(!DZAdTraceIsEnabled());
    [self refresh];
}

- (void)rescanTapped:(id)sender {
    (void)sender;
    DZAdTraceInstall();
    [self refresh];
}

- (void)clearTapped:(id)sender {
    (void)sender;
    DZAdTraceClear();
    [self refresh];
}

- (void)copyTapped:(id)sender {
    (void)sender;
    UIPasteboard.generalPasteboard.string = DZAdTraceLogPath();
}

@end

@interface DZAdTraceUIBridge : NSObject
@property (nonatomic, strong) NSTimer *timer;
+ (instancetype)shared;
- (void)start;
@end

@implementation DZAdTraceUIBridge

+ (instancetype)shared {
    static DZAdTraceUIBridge *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ instance = [DZAdTraceUIBridge new]; });
    return instance;
}

- (void)start {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(traceChanged:)
                                                 name:DZAdTraceDidAppendEventNotification
                                               object:nil];
    [self attachIfPossible];
    if (!self.timer) {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:0.75
                                                     target:self
                                                   selector:@selector(tick:)
                                                   userInfo:nil
                                                    repeats:YES];
    }
}

- (NSArray<UIWindow *> *)allWindows {
    NSMutableArray<UIWindow *> *windows = [NSMutableArray array];
    UIApplication *application = UIApplication.sharedApplication;
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in application.connectedScenes) {
            if (![scene isKindOfClass:[UIWindowScene class]]) continue;
            [windows addObjectsFromArray:((UIWindowScene *)scene).windows];
        }
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        [windows addObjectsFromArray:application.windows];
#pragma clang diagnostic pop
    }
    return windows;
}

- (UIView *)findViewOfClass:(Class)target inView:(UIView *)root {
    if (!root || !target) return nil;
    if ([root isKindOfClass:target]) return root;
    for (UIView *subview in root.subviews) {
        UIView *found = [self findViewOfClass:target inView:subview];
        if (found) return found;
    }
    return nil;
}

- (void)attachIfPossible {
    Class panelClass = NSClassFromString(@"DZFloatPanel");
    Class buttonClass = NSClassFromString(@"DZFloatButton");
    if (!panelClass) return;

    for (UIWindow *window in [self allWindows]) {
        UIView *panel = [self findViewOfClass:panelClass inView:window];
        if (!panel) continue;

        DZAdTraceDashboard *dashboard = [panel viewWithTag:kDZDashboardTag];
        if (!dashboard) {
            dashboard = [[DZAdTraceDashboard alloc] initWithFrame:CGRectMake(0, 48,
                                                                              CGRectGetWidth(panel.bounds),
                                                                              MAX(0.0, CGRectGetHeight(panel.bounds) - 48.0))];
            dashboard.tag = kDZDashboardTag;
            [panel addSubview:dashboard];
        }
        [panel bringSubviewToFront:dashboard];
        [dashboard refresh];

        if (buttonClass) {
            UIView *button = [self findViewOfClass:buttonClass inView:window];
            SEL selector = NSSelectorFromString(@"setDisplayText:");
            if (button && [button respondsToSelector:selector]) {
                ((void (*)(id, SEL, id))objc_msgSend)(button, selector, @"AD");
            }
        }
        return;
    }
}

- (void)traceChanged:(NSNotification *)notification {
    (void)notification;
    [self attachIfPossible];
}

- (void)tick:(NSTimer *)timer {
    (void)timer;
    [self attachIfPossible];
}

@end

__attribute__((constructor)) static void DZAdTraceUIEntry(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[DZAdTraceUIBridge shared] start];
    });
}
