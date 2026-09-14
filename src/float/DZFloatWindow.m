#import "DZFloatWindow.h"
#import "DZFloatButton.h"
#import "DZFloatPanel.h"

@implementation DZFloatRootController

- (void)loadView {
    UIView *view = [[UIView alloc] initWithFrame:UIScreen.mainScreen.bounds];
    view.backgroundColor = UIColor.clearColor;
    view.userInteractionEnabled = NO;
    self.view = view;
}

- (BOOL)shouldAutorotate { return YES; }

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    UIViewController *host = self.hostWindow.rootViewController;
    if (host) return host.supportedInterfaceOrientations;
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    UIViewController *host = self.hostWindow.rootViewController;
    if (host) return host.preferredInterfaceOrientationForPresentation;
    return UIInterfaceOrientationPortrait;
}

- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    if (self.layoutChanged) self.layoutChanged(size);
}

@end

@implementation DZFloatWindow

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    NSArray<UIView *> *targets = @[(UIView *)self.floatPanel ?: [UIView new],
                                   (UIView *)self.floatButton ?: [UIView new]];
    for (UIView *view in targets) {
        if (!view.superview || view.hidden || view.alpha <= 0.01 || !view.userInteractionEnabled) continue;
        CGPoint childPoint = [self convertPoint:point toView:view];
        if ([view pointInside:childPoint withEvent:event]) return YES;
    }
    return NO;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if (![self pointInside:point withEvent:event]) return nil;
    return [super hitTest:point withEvent:event];
}

@end

UIWindowScene *DZActiveWindowScene(void) {
    if (@available(iOS 13.0, *)) {
        UIWindowScene *fallback = nil;
        for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
            if (![scene isKindOfClass:UIWindowScene.class]) continue;
            UIWindowScene *ws = (UIWindowScene *)scene;
            if (ws.activationState == UISceneActivationStateForegroundActive) return ws;
            if (!fallback && ws.activationState == UISceneActivationStateForegroundInactive) fallback = ws;
        }
        return fallback;
    }
    return nil;
}

UIWindow *DZHostWindowForScene(UIWindowScene *scene) {
    if (@available(iOS 13.0, *)) {
        if (scene) {
            for (UIWindow *window in scene.windows) {
                if (window.isKeyWindow && !window.hidden && window.alpha > 0.01) return window;
            }
            for (UIWindow *window in scene.windows) {
                if (!window.hidden && window.alpha > 0.01 && window.windowLevel == UIWindowLevelNormal) return window;
            }
        }
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    UIWindow *key = UIApplication.sharedApplication.keyWindow;
#pragma clang diagnostic pop
    if (key) return key;
    for (UIWindow *window in UIApplication.sharedApplication.windows) {
        if (!window.hidden && window.alpha > 0.01 && window.windowLevel == UIWindowLevelNormal) return window;
    }
    return nil;
}
