#import <Foundation/Foundation.h>

@interface JVMMetadata : NSObject
@property(strong) NSString *path;
@property(strong) NSString *version;
@end

NSString *resolvePlaceholders(NSString *src, NSString *javaFolder);
NSString *execute(NSString *command, NSArray *args);
NSString *fetchJavaVersion(NSString *path);
NSString *normalizeJavaVersion(NSString *version);
BOOL isValidRequirement(NSString *version);
BOOL versionMeetsConstraint(NSString *version, NSString *constraint, BOOL hasMax);
BOOL versionMeetsMaxConstraint(NSString *version, NSString *constraint);

