#import "DZAdTrace.h"
#import <objc/runtime.h>
#import <objc/message.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

NSString * const DZVersion = @"0.1.0";
static dispatch_queue_t gLogQueue;
static NSMutableDictionary<NSString *, NSValue *> *gOriginalIMPs;
static NSMutableSet<NSString *> *gInstalledHooks;
static NSMutableDictionary<NSString *, NSString *> *gPlacements;
static volatile uint64_t gEventCount = 0;
static NSUInteger gHookCount = 0;
static BOOL gTraceEnabled = YES;
static NSString *gLastEvent = @"waiting for ad events";

static void DZEnsureState(void) {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        gLogQueue = dispatch_queue_create("com.dumpzhuanyong.adtrace.log", DISPATCH_QUEUE_SERIAL);
        gOriginalIMPs = [NSMutableDictionary dictionary];
        gInstalledHooks = [NSMutableSet set];
        gPlacements = [NSMutableDictionary dictionary];
    });
}

NSString *DZLogPath(void) {
    NSString *docs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    if (!docs.length) docs = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    return [docs stringByAppendingPathComponent:@"DumpZhuanYong_AdTrace.jsonl"];
}

BOOL DZIsTraceEnabled(void) { DZEnsureState(); @synchronized ([NSObject class]) { return gTraceEnabled; } }
void DZSetTraceEnabled(BOOL enabled) { DZEnsureState(); @synchronized ([NSObject class]) { gTraceEnabled = enabled; } }
NSUInteger DZHookCount(void) { DZEnsureState(); @synchronized (gInstalledHooks) { return gHookCount; } }
uint64_t DZEventCount(void) { return gEventCount; }
NSString *DZLastEvent(void) { DZEnsureState(); @synchronized ([NSObject class]) { return gLastEvent; } }

void DZClearLog(void) {
    DZEnsureState();
    dispatch_async(gLogQueue, ^{ [[NSFileManager defaultManager] removeItemAtPath:DZLogPath() error:nil]; });
    gEventCount = 0;
    @synchronized ([NSObject class]) { gLastEvent = @"log cleared"; }
}

static NSString *DZString(id value) {
    if (!value || value == [NSNull null]) return @"<nil>";
    NSString *s = [value isKindOfClass:[NSString class]] ? value : [value description];
    if (!s) return @"<nil>";
    return s.length > 1600 ? [[s substringToIndex:1600] stringByAppendingString:@"…"] : s;
}

static NSString *DZKind(NSString *text) {
    NSString *s = text.lowercaseString ?: @"";
    if ([s containsString:@"splash"]) return @"splash";
    if ([s containsString:@"reward"]) return @"reward";
    if ([s containsString:@"interstitial"]) return @"interstitial";
    if ([s containsString:@"banner"]) return @"banner";
    if ([s containsString:@"native"]) return @"native";
    return @"unknown";
}

static id DZDictValue(id obj, NSString *key) {
    return [obj isKindOfClass:[NSDictionary class]] ? [(NSDictionary *)obj objectForKey:key] : nil;
}

static void DZRememberPlacement(NSString *kind, id value) {
    if (!kind.length || [kind isEqualToString:@"unknown"] || !value) return;
    NSString *p = DZString(value);
    if (!p.length || [p isEqualToString:@"<nil>"]) return;
    @synchronized (gPlacements) { gPlacements[kind] = p; }
}

static NSString *DZKnownPlacement(NSString *kind) {
    @synchronized (gPlacements) { return gPlacements[kind]; }
}

static void DZRecord(NSString *kind, NSString *stage, id owner, SEL selector,
                     id placement, id scene, id details) {
    DZEnsureState();
    if (!DZIsTraceEnabled()) return;
    uint64_t seq = __sync_add_and_fetch(&gEventCount, 1);
    NSString *className = owner ? NSStringFromClass([owner class]) : @"<nil>";
    NSString *selectorName = selector ? NSStringFromSelector(selector) : @"<none>";
    NSString *placementText = placement ? DZString(placement) : @"";
    NSString *sceneText = scene ? DZString(scene) : @"";
    NSString *detailsText = details ? DZString(details) : @"";
    if (placementText.length) DZRememberPlacement(kind, placementText);

    NSMutableDictionary *row = [@{@"ts": @([[NSDate date] timeIntervalSince1970]), @"seq": @(seq),
        @"kind": kind ?: @"unknown", @"stage": stage ?: @"event", @"class": className,
        @"selector": selectorName} mutableCopy];
    if (placementText.length) row[@"placementID"] = placementText;
    if (sceneText.length) row[@"sceneID"] = sceneText;
    if (detailsText.length) row[@"details"] = detailsText;

    NSString *summary = [NSString stringWithFormat:@"#%llu %@/%@ %@%@", (unsigned long long)seq,
        kind ?: @"unknown", stage ?: @"event", className,
        placementText.length ? [NSString stringWithFormat:@" [%@]", placementText] : @""];
    @synchronized ([NSObject class]) { gLastEvent = summary; }

    dispatch_async(gLogQueue, ^{
        NSData *json = [NSJSONSerialization dataWithJSONObject:row options:0 error:nil];
        if (!json) return;
        NSMutableData *line = [json mutableCopy];
        [line appendData:[@"\n" dataUsingEncoding:NSUTF8StringEncoding]];
        NSString *path = DZLogPath();
        NSFileManager *fm = NSFileManager.defaultManager;
        if (![fm fileExistsAtPath:path]) [fm createFileAtPath:path contents:nil attributes:nil];
        NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath:path];
        if (!fh) return;
        @try { [fh seekToEndOfFile]; [fh writeData:line]; } @catch (__unused NSException *e) {}
        [fh closeFile];
    });
}

UIWindow *DZActiveWindow(void) {
    UIApplication *app = UIApplication.sharedApplication;
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in app.connectedScenes) {
            if (scene.activationState != UISceneActivationStateForegroundActive || ![scene isKindOfClass:[UIWindowScene class]]) continue;
            UIWindowScene *ws = (UIWindowScene *)scene;
            for (UIWindow *w in ws.windows) if (w.isKeyWindow && !w.hidden && w.alpha > 0.01) return w;
            for (UIWindow *w in ws.windows) if (!w.hidden && w.alpha > 0.01 && w.windowLevel == UIWindowLevelNormal) return w;
        }
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    if (app.keyWindow) return app.keyWindow;
#pragma clang diagnostic pop
    for (UIWindow *w in app.windows) if (!w.hidden && w.alpha > 0.01) return w;
    return nil;
}

static NSString *DZHookKey(Class cls, SEL sel) {
    return [NSString stringWithFormat:@"%@::%@", NSStringFromClass(cls), NSStringFromSelector(sel)];
}

static IMP DZOriginal(id self, SEL sel) {
    for (Class c = object_getClass(self); c; c = class_getSuperclass(c)) {
        NSValue *v = nil;
        @synchronized (gOriginalIMPs) { v = gOriginalIMPs[DZHookKey(c, sel)]; }
        if (v) return [v pointerValue];
    }
    return NULL;
}

static void DZCapture(id self, SEL sel, NSArray *args) {
    NSString *cls = NSStringFromClass([self class]);
    NSString *selName = NSStringFromSelector(sel);
    NSString *kind = DZKind([cls stringByAppendingFormat:@" %@", selName]);
    id placement = nil, scene = nil, details = nil;
    NSString *stage = @"bridge";

    if ([cls isEqualToString:@"AnythinkSdkPlugin"] && [selName isEqualToString:@"handleMethodCall:result:"]) {
        stage = @"flutter-in";
        id call = args.count > 0 ? args[0] : nil, method = nil, callArgs = nil;
        @try { method = [call valueForKey:@"method"]; callArgs = [call valueForKey:@"arguments"]; } @catch (__unused NSException *e) {}
        if (method) kind = DZKind(DZString(method));
        placement = DZDictValue(callArgs, @"placementID"); scene = DZDictValue(callArgs, @"sceneID");
        details = @{@"method": method ?: [NSNull null], @"arguments": callArgs ?: [NSNull null]};
    } else if ([cls isEqualToString:@"ATFSendSignalManger"] && [selName isEqualToString:@"sendMethod:arguments:result:"]) {
        stage = @"flutter-out";
        id method = args.count > 0 ? args[0] : nil, callback = args.count > 1 ? args[1] : nil;
        if (method) kind = DZKind([DZString(method) stringByAppendingFormat:@" %@", DZString(callback)]);
        placement = DZDictValue(callback, @"placementID") ?: DZKnownPlacement(kind); scene = DZDictValue(callback, @"sceneID");
        details = @{@"method": method ?: [NSNull null], @"callback": callback ?: [NSNull null]};
    } else if ([cls isEqualToString:@"ATAdManager"]) {
        placement = args.count ? args[0] : nil; stage = [selName hasPrefix:@"load"] ? @"topon-load" : @"topon-show";
        if ([selName containsString:@"Splash"]) kind = @"splash";
        else if ([selName containsString:@"Rewarded"]) kind = @"reward";
        else if ([selName containsString:@"Interstitial"]) kind = @"interstitial";
        if ([selName hasPrefix:@"load"] && args.count > 1) details = args[1];
    } else if ([cls hasPrefix:@"AT"] && [cls containsString:@"Adapter"]) {
        stage = @"adapter-show"; placement = DZKnownPlacement(kind); details = @{@"providerClass": cls};
    } else {
        placement = args.count ? args[0] : nil;
        stage = [selName.lowercaseString containsString:@"load"] ? @"bridge-load" : @"bridge-show";
        if ([selName containsString:@"scene"] && args.count > 1) scene = args[1];
        if ([selName containsString:@"extra"] && args.count > 1) details = args[1];
    }
    DZRecord(kind, stage, self, sel, placement, scene, details);
}

static void DZHook1(id s, SEL c, id a) { DZCapture(s,c,@[a?:[NSNull null]]); IMP i=DZOriginal(s,c); if(i)((void(*)(id,SEL,id))i)(s,c,a); }
static void DZHook2(id s, SEL c, id a,id b) { DZCapture(s,c,@[a?:[NSNull null],b?:[NSNull null]]); IMP i=DZOriginal(s,c); if(i)((void(*)(id,SEL,id,id))i)(s,c,a,b); }
static void DZHook3(id s, SEL c, id a,id b,id d) { DZCapture(s,c,@[a?:[NSNull null],b?:[NSNull null],d?:[NSNull null]]); IMP i=DZOriginal(s,c); if(i)((void(*)(id,SEL,id,id,id))i)(s,c,a,b,d); }
static void DZHook4(id s, SEL c, id a,id b,id d,id e) { DZCapture(s,c,@[a?:[NSNull null],b?:[NSNull null],d?:[NSNull null],e?:[NSNull null]]); IMP i=DZOriginal(s,c); if(i)((void(*)(id,SEL,id,id,id,id))i)(s,c,a,b,d,e); }
static void DZHook5(id s, SEL c, id a,id b,id d,id e,id f) { DZCapture(s,c,@[a?:[NSNull null],b?:[NSNull null],d?:[NSNull null],e?:[NSNull null],f?:[NSNull null]]); IMP i=DZOriginal(s,c); if(i)((void(*)(id,SEL,id,id,id,id,id))i)(s,c,a,b,d,e,f); }
static void DZHook6(id s, SEL c, id a,id b,id d,id e,id f,id g) { DZCapture(s,c,@[a?:[NSNull null],b?:[NSNull null],d?:[NSNull null],e?:[NSNull null],f?:[NSNull null],g?:[NSNull null]]); IMP i=DZOriginal(s,c); if(i)((void(*)(id,SEL,id,id,id,id,id,id))i)(s,c,a,b,d,e,f,g); }

static IMP DZWrapper(unsigned argc) {
    switch (argc) { case 1:return(IMP)DZHook1; case 2:return(IMP)DZHook2; case 3:return(IMP)DZHook3;
        case 4:return(IMP)DZHook4; case 5:return(IMP)DZHook5; case 6:return(IMP)DZHook6; default:return NULL; }
}

static BOOL DZInstall(Class cls, const char *selectorName, unsigned argc) {
    if (!cls || !selectorName) return NO;
    SEL sel = sel_registerName(selectorName); Method method = class_getInstanceMethod(cls, sel);
    if (!method || method_getNumberOfArguments(method) != argc + 2) return NO;
    const char *types = method_getTypeEncoding(method); if (!types || types[0] != 'v') return NO;
    IMP wrapper = DZWrapper(argc); if (!wrapper) return NO;
    NSString *key = DZHookKey(cls, sel);
    @synchronized (gInstalledHooks) { if ([gInstalledHooks containsObject:key]) return YES; }
    IMP original = method_getImplementation(method); if (!original || original == wrapper) return NO;
    @synchronized (gOriginalIMPs) { gOriginalIMPs[key] = [NSValue valueWithPointer:original]; }
    Method superMethod = class_getSuperclass(cls) ? class_getInstanceMethod(class_getSuperclass(cls), sel) : NULL;
    if (superMethod && superMethod == method) class_addMethod(cls, sel, wrapper, types); else method_setImplementation(method, wrapper);
    @synchronized (gInstalledHooks) { [gInstalledHooks addObject:key]; gHookCount = gInstalledHooks.count; }
    return YES;
}

typedef struct { const char *className; const char *selector; unsigned argc; } DZHookSpec;
static const DZHookSpec kHooks[] = {
    {"AnythinkSdkPlugin","handleMethodCall:result:",2},{"ATFSendSignalManger","sendMethod:arguments:result:",3},
    {"ATFSplashAdManger","loadSplashAd:extraDic:",2},{"ATFSplashAdManger","showSplashAd:",1},{"ATFSplashAdManger","showSplashAd:sceneID:",2},{"ATFSplashAdManger","showSplashAdWithShowConfig:sceneID:showCustomExt:",3},
    {"ATFRewardedVideoManger","loadRewardedVideo:extraDic:",2},{"ATFRewardedVideoManger","showRewardedVideo:",1},{"ATFRewardedVideoManger","showRewardedVideo:sceneID:",2},
    {"ATFInterstitialManger","loadInterstitialAd:extraDic:",2},{"ATFInterstitialManger","showInterstitialAd:",1},{"ATFInterstitialManger","showInterstitialAd:sceneID:",2},
    {"ATFBannerManger","loadBannerWith:extraDic:",2},{"ATFBannerManger","showBannerAd:",1},{"ATFNativeManger","loadNativeWith:extraDic:",2},
    {"ATAdManager","loadADWithPlacementID:extra:delegate:",3},{"ATAdManager","loadADWithPlacementID:extra:delegate:containerView:",4},
    {"ATAdManager","showSplashWithPlacementID:config:window:inViewController:extra:delegate:",6},
    {"ATAdManager","showRewardedVideoWithPlacementID:inViewController:delegate:",3},{"ATAdManager","showInterstitialWithPlacementID:inViewController:delegate:",3}
};

void DZInstallKnownHooks(void) {
    DZEnsureState();
    for (NSUInteger i=0;i<sizeof(kHooks)/sizeof(kHooks[0]);i++) { Class c=objc_getClass(kHooks[i].className); if(c) DZInstall(c,kHooks[i].selector,kHooks[i].argc); }
    int count=objc_getClassList(NULL,0); if(count<=0) return;
    Class *classes=(__unsafe_unretained Class *)calloc((size_t)count,sizeof(Class)); if(!classes) return;
    count=objc_getClassList(classes,count);
    const struct { const char *sel; unsigned argc; } adapters[]={{"showSplashAdInWindow:inViewController:parameter:",3},{"showRewardedVideoInViewController:",1},{"showInterstitialInViewController:",1}};
    for(int i=0;i<count;i++){ const char *name=class_getName(classes[i]); if(!name||strncmp(name,"AT",2)||!strstr(name,"Adapter")) continue;
        for(NSUInteger j=0;j<sizeof(adapters)/sizeof(adapters[0]);j++) DZInstall(classes[i],adapters[j].sel,adapters[j].argc); }
    free(classes);
}
