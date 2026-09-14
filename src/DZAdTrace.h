#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include <stdint.h>

FOUNDATION_EXPORT NSString * const DZVersion;
FOUNDATION_EXPORT NSString *DZLogPath(void);
FOUNDATION_EXPORT UIWindow *DZActiveWindow(void);
FOUNDATION_EXPORT void DZInstallKnownHooks(void);
FOUNDATION_EXPORT BOOL DZIsTraceEnabled(void);
FOUNDATION_EXPORT void DZSetTraceEnabled(BOOL enabled);
FOUNDATION_EXPORT NSUInteger DZHookCount(void);
FOUNDATION_EXPORT uint64_t DZEventCount(void);
FOUNDATION_EXPORT NSString *DZLastEvent(void);
FOUNDATION_EXPORT void DZClearLog(void);
