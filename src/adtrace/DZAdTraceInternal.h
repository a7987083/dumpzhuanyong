#import "DZAdTrace.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *DZAdTraceKindFromText(NSString *text);
FOUNDATION_EXPORT id DZAdTraceSerializableObject(id _Nullable value, NSUInteger depth);
FOUNDATION_EXPORT void DZAdTraceRecordEvent(NSString *kind,
                                             NSString *stage,
                                             NSString *sourceClass,
                                             NSString *selectorName,
                                             id _Nullable placementID,
                                             id _Nullable sceneID,
                                             id _Nullable provider,
                                             id _Nullable details);

NS_ASSUME_NONNULL_END
