#import "DZAdTraceInternal.h"

NSString * const DZAdTraceDidAppendEventNotification = @"DZAdTraceDidAppendEventNotification";
NSString * const DZAdTraceVersion = @"2.0.0-dev1";

static dispatch_queue_t gDZStoreQueue;
static NSMutableArray<NSDictionary<NSString *, id> *> *gDZRecentEvents;
static NSMutableDictionary<NSString *, NSNumber *> *gDZKindCounts;
static NSMutableDictionary<NSString *, NSNumber *> *gDZStageCounts;
static NSDictionary<NSString *, id> *gDZLastEvent;
static NSUInteger gDZEventCount;
static BOOL gDZTraceEnabled = YES;

static NSObject *DZStateLock(void) {
    static NSObject *lock;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ lock = [NSObject new]; });
    return lock;
}

static void DZEnsureStore(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        gDZStoreQueue = dispatch_queue_create("com.dumpzhuanyong.adtrace.v2.store", DISPATCH_QUEUE_SERIAL);
        gDZRecentEvents = [NSMutableArray array];
        gDZKindCounts = [NSMutableDictionary dictionary];
        gDZStageCounts = [NSMutableDictionary dictionary];
        gDZLastEvent = @{};
    });
}

static NSString *DZTruncatedString(NSString *value, NSUInteger limit) {
    if (!value) return @"";
    if (value.length <= limit) return value;
    return [[value substringToIndex:limit] stringByAppendingString:@"…"];
}

id DZAdTraceSerializableObject(id value, NSUInteger depth) {
    if (!value || value == [NSNull null]) return [NSNull null];
    if (depth > 4) return @"<max-depth>";
    if ([value isKindOfClass:[NSString class]]) return DZTruncatedString(value, 2048);
    if ([value isKindOfClass:[NSNumber class]] || [value isKindOfClass:[NSNull class]]) return value;
    if ([value isKindOfClass:[NSError class]]) {
        NSError *error = value;
        return @{
            @"domain": error.domain ?: @"",
            @"code": @(error.code),
            @"description": DZTruncatedString(error.localizedDescription ?: @"", 1024)
        };
    }
    if ([value isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *result = [NSMutableDictionary dictionary];
        __block NSUInteger count = 0;
        [(NSDictionary *)value enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            if (count++ >= 48) { *stop = YES; return; }
            NSString *keyDescription = [key description] ?: @"<key>";
            NSString *safeKey = DZTruncatedString(keyDescription, 160);
            result[safeKey] = DZAdTraceSerializableObject(obj, depth + 1) ?: [NSNull null];
        }];
        return result;
    }
    if ([value isKindOfClass:[NSArray class]]) {
        NSArray *array = value;
        NSUInteger limit = MIN((NSUInteger)32, array.count);
        NSMutableArray *result = [NSMutableArray arrayWithCapacity:limit];
        for (NSUInteger i = 0; i < limit; i++) {
            [result addObject:DZAdTraceSerializableObject(array[i], depth + 1) ?: [NSNull null]];
        }
        return result;
    }
    if ([value isKindOfClass:[NSSet class]]) {
        return DZAdTraceSerializableObject([(NSSet *)value allObjects], depth + 1);
    }
    return DZTruncatedString([value description] ?: @"<object>", 2048);
}

NSString *DZAdTraceKindFromText(NSString *text) {
    NSString *s = text.lowercaseString ?: @"";
    if ([s containsString:@"splash"]) return @"splash";
    if ([s containsString:@"reward"]) return @"reward";
    if ([s containsString:@"interstitial"]) return @"interstitial";
    if ([s containsString:@"banner"]) return @"banner";
    if ([s containsString:@"native"]) return @"native";
    return @"unknown";
}

NSString *DZAdTraceLogPath(void) {
    NSString *documents = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    if (!documents.length) documents = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    return [documents stringByAppendingPathComponent:@"DumpZhuanYong_AdTrace_v2.jsonl"];
}

BOOL DZAdTraceIsEnabled(void) {
    @synchronized (DZStateLock()) { return gDZTraceEnabled; }
}

void DZAdTraceSetEnabled(BOOL enabled) {
    @synchronized (DZStateLock()) { gDZTraceEnabled = enabled; }
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:DZAdTraceDidAppendEventNotification object:nil];
    });
}

NSUInteger DZAdTraceEventCount(void) {
    DZEnsureStore();
    __block NSUInteger count = 0;
    dispatch_sync(gDZStoreQueue, ^{ count = gDZEventCount; });
    return count;
}

static void DZAppendLogLine(NSDictionary *event) {
    NSData *json = [NSJSONSerialization dataWithJSONObject:event options:0 error:nil];
    if (!json) return;

    NSMutableData *line = [json mutableCopy];
    [line appendBytes:"\n" length:1];
    NSString *path = DZAdTraceLogPath();
    NSFileManager *fm = NSFileManager.defaultManager;
    NSString *directory = [path stringByDeletingLastPathComponent];
    [fm createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:nil];
    if (![fm fileExistsAtPath:path]) [fm createFileAtPath:path contents:nil attributes:nil];

    NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:path];
    if (!handle) return;
    @try {
        [handle seekToEndOfFile];
        [handle writeData:line];
    } @catch (__unused NSException *exception) {
    }
    [handle closeFile];
}

void DZAdTraceRecordEvent(NSString *kind,
                          NSString *stage,
                          NSString *sourceClass,
                          NSString *selectorName,
                          id placementID,
                          id sceneID,
                          id provider,
                          id details) {
    if (!DZAdTraceIsEnabled()) return;
    DZEnsureStore();

    id safeDetails = details ? DZAdTraceSerializableObject(details, 0) : nil;
    NSString *safePlacement = placementID ? DZTruncatedString([placementID description] ?: @"", 256) : @"";
    NSString *safeScene = sceneID ? DZTruncatedString([sceneID description] ?: @"", 256) : @"";
    NSString *safeProvider = provider ? DZTruncatedString([provider description] ?: @"", 256) : @"";
    NSString *safeKind = kind.length ? kind : @"unknown";
    NSString *safeStage = stage.length ? stage : @"event";
    NSString *safeClass = sourceClass.length ? sourceClass : @"<unknown>";
    NSString *safeSelector = selectorName.length ? selectorName : @"<unknown>";

    dispatch_async(gDZStoreQueue, ^{
        gDZEventCount += 1;
        NSMutableDictionary *event = [@{
            @"seq": @(gDZEventCount),
            @"ts": @([[NSDate date] timeIntervalSince1970]),
            @"kind": safeKind,
            @"stage": safeStage,
            @"class": safeClass,
            @"selector": safeSelector
        } mutableCopy];
        if (safePlacement.length) event[@"placementID"] = safePlacement;
        if (safeScene.length) event[@"sceneID"] = safeScene;
        if (safeProvider.length) event[@"provider"] = safeProvider;
        if (safeDetails) event[@"details"] = safeDetails;

        gDZLastEvent = [event copy];
        [gDZRecentEvents addObject:gDZLastEvent];
        while (gDZRecentEvents.count > 200) [gDZRecentEvents removeObjectAtIndex:0];

        gDZKindCounts[safeKind] = @([gDZKindCounts[safeKind] unsignedIntegerValue] + 1);
        gDZStageCounts[safeStage] = @([gDZStageCounts[safeStage] unsignedIntegerValue] + 1);
        DZAppendLogLine(gDZLastEvent);

        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:DZAdTraceDidAppendEventNotification
                                                                object:nil
                                                              userInfo:gDZLastEvent];
        });
    });
}

NSDictionary<NSString *, id> *DZAdTraceSnapshot(void) {
    DZEnsureStore();
    __block NSDictionary *snapshot = nil;
    dispatch_sync(gDZStoreQueue, ^{
        snapshot = @{
            @"version": DZAdTraceVersion,
            @"enabled": @(DZAdTraceIsEnabled()),
            @"eventCount": @(gDZEventCount),
            @"kindCounts": [gDZKindCounts copy],
            @"stageCounts": [gDZStageCounts copy],
            @"lastEvent": gDZLastEvent ?: @{},
            @"logPath": DZAdTraceLogPath()
        };
    });
    return snapshot;
}

NSArray<NSDictionary<NSString *, id> *> *DZAdTraceRecentEvents(NSUInteger limit) {
    DZEnsureStore();
    __block NSArray *result = nil;
    dispatch_sync(gDZStoreQueue, ^{
        NSUInteger count = MIN(limit, gDZRecentEvents.count);
        NSMutableArray *events = [NSMutableArray arrayWithCapacity:count];
        for (NSUInteger i = 0; i < count; i++) {
            [events addObject:gDZRecentEvents[gDZRecentEvents.count - 1 - i]];
        }
        result = events;
    });
    return result ?: @[];
}

void DZAdTraceClear(void) {
    DZEnsureStore();
    dispatch_async(gDZStoreQueue, ^{
        [gDZRecentEvents removeAllObjects];
        [gDZKindCounts removeAllObjects];
        [gDZStageCounts removeAllObjects];
        gDZLastEvent = @{};
        gDZEventCount = 0;
        [[NSFileManager defaultManager] removeItemAtPath:DZAdTraceLogPath() error:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:DZAdTraceDidAppendEventNotification object:nil];
        });
    });
}
