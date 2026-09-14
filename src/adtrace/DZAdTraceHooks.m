#import "DZAdTraceInternal.h"
#import <objc/runtime.h>
#import <mach-o/dyld.h>
#include <stdlib.h>
#include <string.h>

static NSMutableDictionary<NSString *, NSValue *> *gDZOriginalIMPs;
static NSMutableSet<NSString *> *gDZInstalledHooks;
static NSUInteger gDZHookCount;

static void DZEnsureHookState(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        gDZOriginalIMPs = [NSMutableDictionary dictionary];
        gDZInstalledHooks = [NSMutableSet set];
    });
}

NSUInteger DZAdTraceHookCount(void) {
    DZEnsureHookState();
    @synchronized (gDZInstalledHooks) { return gDZHookCount; }
}

static NSString *DZHookKey(Class cls, SEL selector) {
    return [NSString stringWithFormat:@"%@::%@", NSStringFromClass(cls), NSStringFromSelector(selector)];
}

static IMP DZOriginalIMP(id self, SEL selector) {
    DZEnsureHookState();
    for (Class cls = object_getClass(self); cls; cls = class_getSuperclass(cls)) {
        NSValue *value = nil;
        @synchronized (gDZOriginalIMPs) { value = gDZOriginalIMPs[DZHookKey(cls, selector)]; }
        if (value) return [value pointerValue];
    }
    return NULL;
}

static const char *DZSkipTypeQualifiers(const char *type) {
    if (!type) return type;
    while (*type && strchr("rnNoORV", *type)) type++;
    return type;
}

static BOOL DZIsObjectCompatibleType(const char *type) {
    type = DZSkipTypeQualifiers(type);
    if (!type || !*type) return NO;
    return *type == '@' || *type == '#' || *type == ':';
}

static BOOL DZMethodHasCompatibleABI(Method method, unsigned objectArgumentCount) {
    if (!method || method_getNumberOfArguments(method) != objectArgumentCount + 2) return NO;

    char *returnType = method_copyReturnType(method);
    const char *safeReturnType = DZSkipTypeQualifiers(returnType);
    BOOL returnOK = safeReturnType && *safeReturnType == 'v';
    if (returnType) free(returnType);
    if (!returnOK) return NO;

    for (unsigned i = 0; i < objectArgumentCount; i++) {
        char *argumentType = method_copyArgumentType(method, i + 2);
        BOOL ok = DZIsObjectCompatibleType(argumentType);
        if (argumentType) free(argumentType);
        if (!ok) return NO;
    }
    return YES;
}

static id DZDictionaryValue(id object, NSArray<NSString *> *keys) {
    if (![object isKindOfClass:[NSDictionary class]]) return nil;
    NSDictionary *dictionary = object;
    for (NSString *key in keys) {
        id value = dictionary[key];
        if (value && value != [NSNull null]) return value;
    }
    return nil;
}

static id DZRecursiveValue(id object, NSArray<NSString *> *keys, NSUInteger depth) {
    if (!object || depth > 3) return nil;
    id direct = DZDictionaryValue(object, keys);
    if (direct) return direct;

    if ([object isKindOfClass:[NSDictionary class]]) {
        for (id value in [(NSDictionary *)object allValues]) {
            id nested = DZRecursiveValue(value, keys, depth + 1);
            if (nested) return nested;
        }
    } else if ([object isKindOfClass:[NSArray class]]) {
        for (id value in (NSArray *)object) {
            id nested = DZRecursiveValue(value, keys, depth + 1);
            if (nested) return nested;
        }
    }
    return nil;
}

static id DZPlacementFromArguments(NSArray *arguments) {
    NSArray *keys = @[@"placementID", @"placementId", @"placement_id"];
    for (id value in arguments) {
        id found = DZRecursiveValue(value, keys, 0);
        if (found) return found;
    }
    for (id value in arguments) {
        if ([value isKindOfClass:[NSString class]] && [(NSString *)value length] > 0) return value;
    }
    return nil;
}

static id DZSceneFromArguments(NSArray *arguments) {
    NSArray *keys = @[@"sceneID", @"sceneId", @"scene_id", @"scenario"];
    for (id value in arguments) {
        id found = DZRecursiveValue(value, keys, 0);
        if (found) return found;
    }
    return nil;
}

static id DZProviderFromObject(id object) {
    return DZRecursiveValue(object,
                            @[@"networkFirmId", @"network_firm_id", @"networkName", @"network_name",
                              @"adSourceId", @"adsourceId", @"adsource_id", @"network", @"source"],
                            0);
}

static NSString *DZCallbackStage(NSString *selectorName) {
    NSString *head = [[selectorName componentsSeparatedByString:@":"] firstObject] ?: @"event";
    return [@"callback." stringByAppendingString:head.lowercaseString];
}

static NSString *DZManagerStage(NSString *selectorName) {
    NSString *lower = selectorName.lowercaseString;
    if ([lower containsString:@"autoload"]) return @"bridge.autoload";
    if ([lower hasPrefix:@"load"]) return @"bridge.load";
    if ([lower hasPrefix:@"show"]) return @"bridge.show";
    if ([lower hasPrefix:@"entry"]) return @"bridge.scenario";
    if ([lower containsString:@"ready"] || [lower hasPrefix:@"check"] || [lower containsString:@"validads"]) return @"bridge.status";
    return @"bridge.event";
}

static void DZCapture(id self, SEL selector, NSArray *arguments) {
    NSString *className = NSStringFromClass([self class]) ?: @"<unknown>";
    NSString *selectorName = NSStringFromSelector(selector) ?: @"<unknown>";
    NSString *kind = DZAdTraceKindFromText([className stringByAppendingFormat:@" %@", selectorName]);
    NSString *stage = @"runtime.event";
    id placement = nil;
    id scene = nil;
    id provider = nil;
    id details = arguments;

    if ([className isEqualToString:@"AnythinkSdkPlugin"] && [selectorName isEqualToString:@"handleMethodCall:result:"]) {
        stage = @"flutter.call";
        id call = arguments.count > 0 ? arguments[0] : nil;
        id method = nil;
        id callArguments = nil;
        @try {
            method = [call valueForKey:@"method"];
            callArguments = [call valueForKey:@"arguments"];
        } @catch (__unused NSException *exception) {
        }
        if (method) kind = DZAdTraceKindFromText([method description]);
        placement = DZDictionaryValue(callArguments, @[@"placementID", @"placementId", @"placement_id"]);
        scene = DZDictionaryValue(callArguments, @[@"sceneID", @"sceneId", @"scene_id", @"scenario"]);
        provider = DZProviderFromObject(callArguments);
        details = @{
            @"method": method ?: [NSNull null],
            @"arguments": callArguments ?: [NSNull null]
        };
    } else if ([className isEqualToString:@"ATFSendSignalManger"] && [selectorName isEqualToString:@"sendMethod:arguments:result:"]) {
        stage = @"flutter.callback";
        id method = arguments.count > 0 ? arguments[0] : nil;
        id callback = arguments.count > 1 ? arguments[1] : nil;
        NSString *combined = [NSString stringWithFormat:@"%@ %@", method ?: @"", callback ?: @""];
        kind = DZAdTraceKindFromText(combined);
        placement = DZRecursiveValue(callback, @[@"placementID", @"placementId", @"placement_id"], 0);
        scene = DZRecursiveValue(callback, @[@"sceneID", @"sceneId", @"scene_id", @"scenario"], 0);
        provider = DZProviderFromObject(callback);
        details = @{
            @"method": method ?: [NSNull null],
            @"callback": callback ?: [NSNull null]
        };
    } else if ([className isEqualToString:@"ATAdManager"]) {
        stage = [selectorName.lowercaseString hasPrefix:@"load"] ? @"topon.load" : @"topon.show";
        placement = arguments.count > 0 ? arguments[0] : nil;
        if ([selectorName.lowercaseString containsString:@"scene"] && arguments.count > 1) scene = arguments[1];
        provider = DZProviderFromObject(arguments);
    } else if ([className hasPrefix:@"AT"] && [className containsString:@"Adapter"]) {
        stage = @"adapter.show";
        provider = className;
        placement = DZPlacementFromArguments(arguments);
        scene = DZSceneFromArguments(arguments);
    } else if ([className hasSuffix:@"Delegate"] || [className containsString:@"Delegate"]) {
        stage = DZCallbackStage(selectorName);
        placement = DZPlacementFromArguments(arguments);
        scene = DZSceneFromArguments(arguments);
        provider = DZProviderFromObject(arguments);
    } else if ([className hasPrefix:@"ATF"] && [className containsString:@"Manger"]) {
        stage = DZManagerStage(selectorName);
        placement = arguments.count > 0 ? arguments[0] : nil;
        if ([selectorName.lowercaseString containsString:@"sceneid"] && arguments.count > 1) scene = arguments[1];
        provider = DZProviderFromObject(arguments);
    }

    DZAdTraceRecordEvent(kind, stage, className, selectorName, placement, scene, provider, details);
}

static NSArray *DZArgs1(id a) { return @[a ?: [NSNull null]]; }
static NSArray *DZArgs2(id a, id b) { return @[a ?: [NSNull null], b ?: [NSNull null]]; }
static NSArray *DZArgs3(id a, id b, id c) { return @[a ?: [NSNull null], b ?: [NSNull null], c ?: [NSNull null]]; }
static NSArray *DZArgs4(id a, id b, id c, id d) { return @[a ?: [NSNull null], b ?: [NSNull null], c ?: [NSNull null], d ?: [NSNull null]]; }
static NSArray *DZArgs5(id a, id b, id c, id d, id e) { return @[a ?: [NSNull null], b ?: [NSNull null], c ?: [NSNull null], d ?: [NSNull null], e ?: [NSNull null]]; }
static NSArray *DZArgs6(id a, id b, id c, id d, id e, id f) { return @[a ?: [NSNull null], b ?: [NSNull null], c ?: [NSNull null], d ?: [NSNull null], e ?: [NSNull null], f ?: [NSNull null]]; }

static void DZHook1(id self, SEL cmd, id a) {
    DZCapture(self, cmd, DZArgs1(a));
    IMP original = DZOriginalIMP(self, cmd);
    if (original) ((void (*)(id, SEL, id))original)(self, cmd, a);
}

static void DZHook2(id self, SEL cmd, id a, id b) {
    DZCapture(self, cmd, DZArgs2(a, b));
    IMP original = DZOriginalIMP(self, cmd);
    if (original) ((void (*)(id, SEL, id, id))original)(self, cmd, a, b);
}

static void DZHook3(id self, SEL cmd, id a, id b, id c) {
    DZCapture(self, cmd, DZArgs3(a, b, c));
    IMP original = DZOriginalIMP(self, cmd);
    if (original) ((void (*)(id, SEL, id, id, id))original)(self, cmd, a, b, c);
}

static void DZHook4(id self, SEL cmd, id a, id b, id c, id d) {
    DZCapture(self, cmd, DZArgs4(a, b, c, d));
    IMP original = DZOriginalIMP(self, cmd);
    if (original) ((void (*)(id, SEL, id, id, id, id))original)(self, cmd, a, b, c, d);
}

static void DZHook5(id self, SEL cmd, id a, id b, id c, id d, id e) {
    DZCapture(self, cmd, DZArgs5(a, b, c, d, e));
    IMP original = DZOriginalIMP(self, cmd);
    if (original) ((void (*)(id, SEL, id, id, id, id, id))original)(self, cmd, a, b, c, d, e);
}

static void DZHook6(id self, SEL cmd, id a, id b, id c, id d, id e, id f) {
    DZCapture(self, cmd, DZArgs6(a, b, c, d, e, f));
    IMP original = DZOriginalIMP(self, cmd);
    if (original) ((void (*)(id, SEL, id, id, id, id, id, id))original)(self, cmd, a, b, c, d, e, f);
}

static IMP DZWrapperForArgumentCount(unsigned count) {
    switch (count) {
        case 1: return (IMP)DZHook1;
        case 2: return (IMP)DZHook2;
        case 3: return (IMP)DZHook3;
        case 4: return (IMP)DZHook4;
        case 5: return (IMP)DZHook5;
        case 6: return (IMP)DZHook6;
        default: return NULL;
    }
}

static BOOL DZClassOwnsMethod(Class cls, SEL selector) {
    unsigned count = 0;
    Method *methods = class_copyMethodList(cls, &count);
    BOOL found = NO;
    for (unsigned i = 0; i < count; i++) {
        if (method_getName(methods[i]) == selector) { found = YES; break; }
    }
    if (methods) free(methods);
    return found;
}

static BOOL DZInstallHook(Class cls, SEL selector, unsigned objectArgumentCount) {
    if (!cls || !selector || objectArgumentCount == 0 || objectArgumentCount > 6) return NO;
    DZEnsureHookState();

    NSString *key = DZHookKey(cls, selector);
    @synchronized (gDZInstalledHooks) {
        if ([gDZInstalledHooks containsObject:key]) return YES;
    }

    Method method = class_getInstanceMethod(cls, selector);
    if (!DZMethodHasCompatibleABI(method, objectArgumentCount)) return NO;
    IMP wrapper = DZWrapperForArgumentCount(objectArgumentCount);
    IMP original = method_getImplementation(method);
    const char *types = method_getTypeEncoding(method);
    if (!wrapper || !original || !types || original == wrapper) return NO;

    @synchronized (gDZOriginalIMPs) {
        gDZOriginalIMPs[key] = [NSValue valueWithPointer:original];
    }

    BOOL installed = NO;
    if (DZClassOwnsMethod(cls, selector)) {
        method_setImplementation(method, wrapper);
        installed = YES;
    } else {
        installed = class_addMethod(cls, selector, wrapper, types);
    }

    if (!installed) {
        @synchronized (gDZOriginalIMPs) { [gDZOriginalIMPs removeObjectForKey:key]; }
        return NO;
    }

    @synchronized (gDZInstalledHooks) {
        [gDZInstalledHooks addObject:key];
        gDZHookCount = gDZInstalledHooks.count;
    }
    return YES;
}

typedef struct {
    const char *className;
    const char *selectorName;
    unsigned argumentCount;
} DZHookSpec;

static const DZHookSpec kKnownHooks[] = {
    {"AnythinkSdkPlugin", "handleMethodCall:result:", 2},
    {"ATFSendSignalManger", "sendMethod:arguments:result:", 3},

    {"ATFSplashAdManger", "loadSplashAd:extraDic:", 2},
    {"ATFSplashAdManger", "showSplashAd:", 1},
    {"ATFSplashAdManger", "showSplashAd:sceneID:", 2},
    {"ATFSplashAdManger", "showSplashAdWithShowConfig:sceneID:showCustomExt:", 3},
    {"ATFSplashAdManger", "entryScenarioWithPlacementID:sceneID:", 2},

    {"ATFRewardedVideoManger", "loadRewardedVideo:extraDic:", 2},
    {"ATFRewardedVideoManger", "showRewardedVideo:", 1},
    {"ATFRewardedVideoManger", "showRewardedVideo:sceneID:", 2},
    {"ATFRewardedVideoManger", "showRewardedVideoWithShowConfig:sceneID:showCustomExt:", 3},
    {"ATFRewardedVideoManger", "autoLoadRewardedVideo:", 1},
    {"ATFRewardedVideoManger", "showAutoLoadRewardedVideoAD:sceneID:", 2},
    {"ATFRewardedVideoManger", "showAutoLoadRewardedVideoAD:sceneID:showCustomExt:", 3},

    {"ATFInterstitialManger", "loadInterstitialAd:extraDic:", 2},
    {"ATFInterstitialManger", "showInterstitialAd:", 1},
    {"ATFInterstitialManger", "showInterstitialAd:sceneID:", 2},
    {"ATFInterstitialManger", "showInterstitialAdWithShowConfig:sceneID:showCustomExt:", 3},
    {"ATFInterstitialManger", "autoLoadInterstitialAD:", 1},
    {"ATFInterstitialManger", "showAutoLoadInterstitialADWithPlacementID:sceneID:", 2},
    {"ATFInterstitialManger", "showAutoLoadInterstitialADWithPlacementID:sceneID:showCustomExt:", 3},

    {"ATFBannerManger", "loadBannerWith:extraDic:", 2},
    {"ATFBannerManger", "showBanner:", 1},
    {"ATFBannerManger", "showBannerInRectangle:extraDic:", 2},
    {"ATFBannerManger", "showBannerInRectangle:sceneID:extraDic:", 3},
    {"ATFBannerManger", "showAdInPosition:position:", 2},
    {"ATFBannerManger", "showAdInPosition:sceneID:position:showCustomExt:", 4},

    {"ATFNativeManger", "loadNativeWith:extraDic:", 2},
    {"ATFNativeManger", "entryScenarioWithPlacementID:sceneID:", 2},
    {"ATFNativeManger", "renderOffer:config:placementID:extraDic:", 4},

    {"ATAdManager", "loadADWithPlacementID:extra:delegate:", 3},
    {"ATAdManager", "loadADWithPlacementID:extra:delegate:containerView:", 4},
    {"ATAdManager", "showSplashWithPlacementID:config:window:inViewController:extra:delegate:", 6},
    {"ATAdManager", "showRewardedVideoWithPlacementID:inViewController:delegate:", 3},
    {"ATAdManager", "showRewardedVideoWithPlacementID:config:inViewController:delegate:", 4},
    {"ATAdManager", "showInterstitialWithPlacementID:inViewController:delegate:", 3},
    {"ATAdManager", "showInterstitialWithPlacementID:scene:inViewController:delegate:", 4}
};

static BOOL DZLooksLikeCallbackSelector(NSString *selectorName) {
    NSString *lower = selectorName.lowercaseString;
    return [lower containsString:@"load"] || [lower containsString:@"show"] ||
           [lower containsString:@"click"] || [lower containsString:@"close"] ||
           [lower containsString:@"reward"] || [lower containsString:@"bidding"] ||
           [lower containsString:@"fail"] || [lower containsString:@"deep"] ||
           [lower containsString:@"video"] || [lower containsString:@"refresh"];
}

static void DZInstallKnownHooks(void) {
    for (NSUInteger i = 0; i < sizeof(kKnownHooks) / sizeof(kKnownHooks[0]); i++) {
        const DZHookSpec spec = kKnownHooks[i];
        Class cls = objc_getClass(spec.className);
        if (!cls) continue;
        DZInstallHook(cls, sel_registerName(spec.selectorName), spec.argumentCount);
    }
}

static void DZInstallDelegateHooks(void) {
    const char *classNames[] = {
        "ATFSplashDelegate", "ATFRewardedVideoDelegate", "ATFInterstitialDelegate", "ATFBannerDelegate", "ATFNativeDelegate"
    };
    for (NSUInteger c = 0; c < sizeof(classNames) / sizeof(classNames[0]); c++) {
        Class cls = objc_getClass(classNames[c]);
        if (!cls) continue;
        unsigned count = 0;
        Method *methods = class_copyMethodList(cls, &count);
        for (unsigned i = 0; i < count; i++) {
            SEL selector = method_getName(methods[i]);
            NSString *name = NSStringFromSelector(selector);
            unsigned argumentCount = method_getNumberOfArguments(methods[i]) - 2;
            if (argumentCount == 0 || argumentCount > 6 || !DZLooksLikeCallbackSelector(name)) continue;
            DZInstallHook(cls, selector, argumentCount);
        }
        if (methods) free(methods);
    }
}

static void DZInstallAdapterHooks(void) {
    int classCount = objc_getClassList(NULL, 0);
    if (classCount <= 0) return;
    Class *classes = (__unsafe_unretained Class *)calloc((size_t)classCount, sizeof(Class));
    if (!classes) return;
    classCount = objc_getClassList(classes, classCount);

    for (int i = 0; i < classCount; i++) {
        const char *rawName = class_getName(classes[i]);
        if (!rawName || strncmp(rawName, "AT", 2) != 0 || strstr(rawName, "Adapter") == NULL) continue;

        unsigned methodCount = 0;
        Method *methods = class_copyMethodList(classes[i], &methodCount);
        for (unsigned m = 0; m < methodCount; m++) {
            SEL selector = method_getName(methods[m]);
            NSString *name = NSStringFromSelector(selector);
            if (![name.lowercaseString hasPrefix:@"show"]) continue;
            unsigned argumentCount = method_getNumberOfArguments(methods[m]) - 2;
            if (argumentCount == 0 || argumentCount > 6) continue;
            DZInstallHook(classes[i], selector, argumentCount);
        }
        if (methods) free(methods);
    }
    free(classes);
}

static void DZInstallPass(void) {
    DZEnsureHookState();
    DZInstallKnownHooks();
    DZInstallDelegateHooks();
    DZInstallAdapterHooks();
}

static void DZImageAdded(const struct mach_header *header, intptr_t slide) {
    (void)header;
    (void)slide;
    dispatch_async(dispatch_get_main_queue(), ^{ DZInstallPass(); });
}

void DZAdTraceInstall(void) {
    static dispatch_once_t observerOnceToken;
    dispatch_once(&observerOnceToken, ^{
        _dyld_register_func_for_add_image(DZImageAdded);
        DZAdTraceRecordEvent(@"system", @"trace.install", @"DZAdTrace", @"install", nil, nil, nil,
                             @{@"version": DZAdTraceVersion});
    });

    // Manual calls (for example the dashboard Rescan button) must really rescan.
    // The installed-hook set keeps this idempotent, while newly loaded classes can be discovered.
    DZInstallPass();
}

__attribute__((constructor)) static void DZAdTraceEntry(void) {
    dispatch_async(dispatch_get_main_queue(), ^{ DZAdTraceInstall(); });
}
