#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString * const DZAdTraceDidAppendEventNotification;
FOUNDATION_EXPORT NSString * const DZAdTraceVersion;

FOUNDATION_EXPORT void DZAdTraceInstall(void);
FOUNDATION_EXPORT BOOL DZAdTraceIsEnabled(void);
FOUNDATION_EXPORT void DZAdTraceSetEnabled(BOOL enabled);
FOUNDATION_EXPORT NSUInteger DZAdTraceHookCount(void);
FOUNDATION_EXPORT NSUInteger DZAdTraceEventCount(void);
FOUNDATION_EXPORT NSString *DZAdTraceLogPath(void);
FOUNDATION_EXPORT NSDictionary<NSString *, id> *DZAdTraceSnapshot(void);
FOUNDATION_EXPORT NSArray<NSDictionary<NSString *, id> *> *DZAdTraceRecentEvents(NSUInteger limit);
FOUNDATION_EXPORT void DZAdTraceClear(void);

NS_ASSUME_NONNULL_END
