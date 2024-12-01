#import "nativeStub.h"
#import <stdlib.h>
#import <string.h>
#import <AppKit/AppKit.h>

int main(int argc, char** argv) {
    // For future improvement we can make these localized strings actually have the translations
    // like they do in the bash script
    NSString *MSG_ERROR_LAUNCHING=NSLocalizedString(@"ERROR launching '%s'.", nil);
    NSString *MSG_MISSING_MAINCLASS=NSLocalizedString(@"'MainClass' isn't specified!\nJava application cannot be started!", nil);
    NSString *MSG_JVMVERSION_REQ_INVALID=@"The syntax of the required Java version is invalid: %@\nPlease contact the App developer.";
    NSString *MSG_NO_SUITABLE_JAVA=NSLocalizedString(@"No suitable Java version found on your system!\nThis program requires Java %@", nil);
    NSString *MSG_JAVA_VERSION_OR_LATER=@" or later";
    NSString *MSG_JAVA_VERSION_LATEST=@" (latest update)";
    NSString *MSG_JAVA_VERSION_MAX=@"up to %@";
    NSString *MSG_NO_SUITABLE_JAVA_CHECK=NSLocalizedString(@"Make sure you install the required Java version.", nil);
    NSString *MSG_INSTALL_JAVA=NSLocalizedString(@"You need to have JAVA installed on your Mac!\nVisit java.com for installation instructions...", nil);
    NSString *MSG_LATER=NSLocalizedString(@"Later", nil);
    NSString *MSG_VISIT_JAVA_DOT_COM=NSLocalizedString(@"Java by Oracle", nil);
    NSString *MSG_VISIT_ADOPTIUM=NSLocalizedString(@"Java by Adoptium", nil);

    NSBundle *main = [NSBundle mainBundle];
    NSDictionary *info = [main infoDictionary];
    const char *appName = [info[@"CFBundleName"] UTF8String];
    NSLog(@"[%s] [StubPath] %@", appName, [main executablePath]);

    NSString *iconFile = info[@"CFBundleIconFile"];
    if(iconFile != nil && ![iconFile containsString:@".icns"]) {
        iconFile = [iconFile stringByAppendingString:@".icns"];
    }
    NSDictionary *javaInfo = info[@"Java"];
    if(javaInfo == nil) {
        javaInfo = info[@"JavaX"];
    }

    NSString *javaFolder;
    NSString *mainClass;
    NSString *splashFile;
    NSString *workingDirectory;
    NSMutableArray *jvmOptions;
    NSMutableArray *jvmDefaultOptions;
    NSMutableArray *classPath;
    NSMutableArray *mainArgs;
    NSString *jvmVersion;
    NSString *jvmMaxVersion = nil;
    NSString *jvmOptionsFile;
    NSString *bootstrapScript;
    if(javaInfo != nil) {
        NSLog(@"[%s] [PlistStyle] Apple", appName);
        // Apple mode
        javaFolder = [[main resourcePath] stringByAppendingPathComponent:@"Java"];
        if(javaInfo[@"RelocateJar"]) {
            javaFolder = [main resourcePath];
        }

        if(javaInfo[@"WorkingDirectory"] != nil) {
            NSString *workDirWithPlaceholders = javaInfo[@"WorkingDirectory"];
            workingDirectory = resolvePlaceholders(workDirWithPlaceholders, javaFolder);
        } else {
            workingDirectory = [[main bundlePath] stringByDeletingLastPathComponent];
        }

        mainClass = javaInfo[@"MainClass"];
        splashFile = javaInfo[@"SplashFile"];
        jvmOptions = [[NSMutableArray alloc] init];
        NSDictionary *propertiesAttr = javaInfo[@"Properties"];
        if(propertiesAttr != nil) {
            for(NSString *key in propertiesAttr) {
                [jvmOptions addObject:[NSString stringWithFormat:@"-D%@=%@", resolvePlaceholders(key, javaFolder), resolvePlaceholders(propertiesAttr[key], javaFolder)]];
            }
        }

        classPath = [[NSMutableArray alloc] init];
        id classPathAttr = javaInfo[@"ClassPath"];
        if([classPathAttr isKindOfClass:[NSArray class]]) {
            for(NSString *pathElement in classPathAttr) {
                [classPath addObject:resolvePlaceholders(pathElement, javaFolder)];
            }
        } else if(classPathAttr != nil) {
            [classPath addObject:resolvePlaceholders(classPathAttr, javaFolder)];
        }

        jvmDefaultOptions = [[NSMutableArray alloc] init];
        id vmOptionsAttr = javaInfo[@"VMOptions"];
        if([vmOptionsAttr isKindOfClass:[NSArray class]]) {
            for(NSString *pathElement in vmOptionsAttr) {
                [jvmDefaultOptions addObject:resolvePlaceholders(pathElement, javaFolder)];
            }
        } else if(vmOptionsAttr != nil) {
            [jvmDefaultOptions addObject:resolvePlaceholders(vmOptionsAttr, javaFolder)];
        }

        if(javaInfo[@"StartOnMainThread"]) {
            [jvmDefaultOptions addObject:@" -XstartOnFirstThread"];
        }

        mainArgs = [[NSMutableArray alloc] init];
        id argumentsAttr = javaInfo[@"Arguments"];
        if([argumentsAttr isKindOfClass:[NSArray class]]) {
            for(NSString *pathElement in argumentsAttr) {
                [mainArgs addObject:resolvePlaceholders(pathElement, javaFolder)];
            }
        } else if(argumentsAttr != nil) {
            [mainArgs addObject:resolvePlaceholders(argumentsAttr, javaFolder)];
        }

        jvmVersion = javaInfo[@"JVMVersion"];
        jvmOptionsFile = javaInfo[@"JVMOptionsFile"];
        bootstrapScript = javaInfo[@"BootstrapScript"];
    } else {
        NSLog(@"[%s] [PlistStyle] Oracle", appName);
        javaFolder = [[main bundlePath] stringByAppendingPathComponent:@"Contents/Java"];
        workingDirectory = javaFolder;
        mainClass = info[@"JVMMainClassName"];
        mainClass = info[@"JVMSplashFile"];

        jvmOptions = [[NSMutableArray alloc] init];
        NSDictionary *propertiesAttr = info[@"JVMOptions"];
        if(propertiesAttr != nil) {
            for(NSString *key in propertiesAttr) {
                [jvmOptions addObject:[NSString stringWithFormat:@"-D%@=%@", resolvePlaceholders(key, javaFolder), resolvePlaceholders(propertiesAttr[key], javaFolder)]];
            }
        }

        classPath = [[NSMutableArray alloc] init];
        id classPathAttr = info[@"JVMClassPath"];
        if([classPathAttr isKindOfClass:[NSArray class]]) {
            for(NSString *pathElement in classPathAttr) {
                [classPath addObject:resolvePlaceholders(pathElement, javaFolder)];
            }
        } else if(classPathAttr != nil) {
            [classPath addObject:resolvePlaceholders(classPathAttr, javaFolder)];
        } else {
            [classPath addObject:[javaFolder stringByAppendingString:@"/*"]];
        }

        jvmDefaultOptions = [[NSMutableArray alloc] init];
        id vmOptionsAttr = info[@"JVMDefaultOptions"];
        for(NSString *pathElement in vmOptionsAttr) {
            [jvmDefaultOptions addObject:resolvePlaceholders(pathElement, javaFolder)];
        }

        mainArgs = [[NSMutableArray alloc] init];
        id argumentsAttr = info[@"JVMArguments"];
        if([argumentsAttr isKindOfClass:[NSArray class]]) {
            for(NSString *pathElement in argumentsAttr) {
                [mainArgs addObject:resolvePlaceholders(pathElement, javaFolder)];
            }
        } else if(argumentsAttr != nil) {
            [mainArgs addObject:resolvePlaceholders(argumentsAttr, javaFolder)];
        }

        jvmVersion = info[@"JVMVersion"];
        jvmOptionsFile = info[@"JVMOptionsFile"];
        bootstrapScript = info[@"BootstrapScript"];
    }
    if([jvmVersion containsString:@";"]) {
        NSArray *stringParts = [jvmVersion componentsSeparatedByString:@";"];
        jvmVersion = stringParts[0];
        jvmMaxVersion = stringParts[1];
    }
    NSLog(@"[%s] [JavaRequirement] JVM minimum version: %@", appName, jvmVersion);
    NSLog(@"[%s] [JavaRequirement] JVM minimum version: %@", appName, jvmMaxVersion);

    if(jvmVersion != nil && !isValidRequirement(jvmVersion)) {
        NSString *errorMsg = [NSString stringWithFormat:MSG_JVMVERSION_REQ_INVALID, jvmVersion];
        NSLog(@"[%s] [EXIT 4] %@", appName, errorMsg);
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:[NSString stringWithFormat:MSG_ERROR_LAUNCHING, appName]];
        [alert setInformativeText:errorMsg];
        [alert runModal];
        exit(4);
    }
    if(jvmVersion != nil && !isValidRequirement(jvmMaxVersion)) {
        NSString *errorMsg = [NSString stringWithFormat:MSG_JVMVERSION_REQ_INVALID, jvmMaxVersion];
        NSLog(@"[%s] [EXIT 5] %@", appName, MSG_MISSING_MAINCLASS);
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:[NSString stringWithFormat:MSG_ERROR_LAUNCHING, appName]];
        [alert setInformativeText:errorMsg];
        [alert runModal];
        exit(5);
    }

    NSLog(@"[%s] [JavaSearch] Checking for $JAVA_HOME ...", appName);
    NSString *javaHome = [[[NSProcessInfo processInfo] environment] objectForKey:@"JAVA_HOME"];
    NSString *javaCmd = nil;
    if(javaHome != nil) {
        NSLog(@"[%s] [JavaSearch] ... found JAVA_HOME with value %@", appName, javaHome);
        if([javaHome characterAtIndex:0] == '/') {
            javaCmd = [javaHome stringByAppendingString:@"/bin/java"];
            NSLog(@"[%s] [JavaSearch] ... parsing JAVA_HOME as absolute path to the executable '%@'", appName, javaCmd);
        } else {
            javaCmd = [[main bundlePath] stringByAppendingString:[@"/" stringByAppendingString:[javaHome stringByAppendingString:@"/bin/java"]]];
            NSLog(@"[%s] [JavaSearch] ... parsing JAVA_HOME as relative path inside the App bundle to the executable '%@'", appName, javaCmd);
        }
    } else {
        NSLog(@"[%s] [JavaSearch] ... haven't found JAVA_HOME", appName);
    }

    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (javaCmd == nil || ![fileManager isExecutableFileAtPath:javaCmd]) {
        if(javaCmd != nil) {
            NSLog(@"[%s] [JavaSearch] ... but no 'java' executable was found at the JAVA_HOME location!", appName);
            javaCmd = nil;
        }

        NSLog(@"[%s] [JavaSearch] Searching for JavaVirtualMachines on the system ...", appName);

        NSMutableArray *allJvms = [[NSMutableArray alloc] init];

        NSString *javaHomeRaw = execute(@"/usr/libexec/java_home", @[@"--xml"]);
        NSData* plistData = [javaHomeRaw dataUsingEncoding:NSUTF8StringEncoding];
        NSArray* plist = [NSPropertyListSerialization propertyListWithData:plistData options:NSPropertyListImmutable format:nil error:nil];
        if(plist != nil) {
            for(NSDictionary *entry in plist) {
                JVMMetadata *metadata = [[JVMMetadata alloc] init];
                [metadata setPath:[entry[@"JVMHomePath"] stringByAppendingString:@"/bin/java"]];
                [metadata setVersion:normalizeJavaVersion(entry[@"JVMVersion"])];
                [allJvms addObject:metadata];
            }
        }

        if([fileManager isExecutableFileAtPath:@"/Library/Java/Home/bin/java"]) {
            JVMMetadata *metadata = [[JVMMetadata alloc] init];
            [metadata setPath:@"/Library/Java/Home/bin/java"];
            [metadata setVersion:normalizeJavaVersion(fetchJavaVersion([metadata path]))];
            [allJvms addObject:metadata];
        }

        if([fileManager isExecutableFileAtPath:@"/Library/Internet Plug-Ins/JavaAppletPlugin.plugin/Contents/Home/bin/java"]) {
            JVMMetadata *metadata = [[JVMMetadata alloc] init];
            [metadata setPath:@"/Library/Internet Plug-Ins/JavaAppletPlugin.plugin/Contents/Home/bin/java"];
            [metadata setVersion:normalizeJavaVersion(fetchJavaVersion([metadata path]))];
            [allJvms addObject:metadata];
        }

        BOOL isDir = NO;
        NSString *searchBase = [@"~/.sdkman/candidates/java" stringByExpandingTildeInPath];
        if([fileManager fileExistsAtPath:searchBase isDirectory:&isDir] && isDir) {
            for(NSString *path in [fileManager contentsOfDirectoryAtPath:searchBase error:nil]) {
                if([path isEqualToString:@"current/"]) {
                    continue;
                }
                JVMMetadata *metadata = [[JVMMetadata alloc] init];
                [metadata setPath:[NSString stringWithFormat:@"%@/%@/bin/java", searchBase, path]];
                if([fileManager isExecutableFileAtPath:[metadata path]]) {
                    [metadata setVersion:normalizeJavaVersion(fetchJavaVersion([metadata path]))];
                    [allJvms addObject:metadata];
                }
            }
        }

        searchBase = [@"~/.asdf/installs/java" stringByExpandingTildeInPath];
        if([fileManager fileExistsAtPath:searchBase isDirectory:&isDir] && isDir) {
            for(NSString *path in [fileManager contentsOfDirectoryAtPath:searchBase error:nil]) {
                JVMMetadata *metadata = [[JVMMetadata alloc] init];
                [metadata setPath:[NSString stringWithFormat:@"%@/%@/bin/java", searchBase, path]];
                if([fileManager isExecutableFileAtPath:[metadata path]]) {
                    [metadata setVersion:normalizeJavaVersion(fetchJavaVersion([metadata path]))];
                    [allJvms addObject:metadata];
                }
            }
        }

        for(JVMMetadata *metadata in allJvms) {
            NSLog(@"[%s] [JavaSearch] ... found JVM: %@", appName, metadata);
        }

        NSLog(@"[%s] [JavaSearch]  Filtering the result list for JVMs matching the min/max version requirement ...", appName);

        NSMutableArray *matchingJvms = [[NSMutableArray alloc] init];
        for(JVMMetadata *metadata in allJvms) {
            if(jvmVersion != nil && !versionMeetsConstraint([metadata version], normalizeJavaVersion(jvmVersion), jvmMaxVersion != nil)) {
                continue;
            }
            if(jvmMaxVersion != nil && !versionMeetsMaxConstraint([metadata version], normalizeJavaVersion(jvmMaxVersion))) {
                continue;
            }
            [matchingJvms addObject:metadata];
        }

        for(JVMMetadata *metadata in matchingJvms) {
            NSLog(@"[%s] [JavaSearch] ... matches all requirements: %@", appName, metadata);
        }
        NSArray *sortedMatchingJvms = [matchingJvms sortedArrayUsingComparator:^NSComparisonResult(JVMMetadata *obj1, JVMMetadata *obj2) {
            return [[obj2 version] compare:[obj1 version] options:NSNumericSearch];
        }];
        for(JVMMetadata *metadata in sortedMatchingJvms) {
            if([fileManager isExecutableFileAtPath: [metadata path]]) {
                javaCmd = [metadata path];
                break;
            }
        }
    }

    NSLog(@"[%s] [JavaCommand] '%@'", appName, javaCmd);
    NSLog(@"[%s] [JavaVersion] %@", appName, javaCmd == nil ? nil : fetchJavaVersion(javaCmd));

    if(javaCmd == nil || ![fileManager isExecutableFileAtPath:javaCmd]) {
        if(jvmVersion != nil) {
            NSString *expandedMessage;
            if(jvmMaxVersion == nil) {
                expandedMessage = [NSString stringWithFormat:MSG_NO_SUITABLE_JAVA, [
                        [normalizeJavaVersion(jvmVersion) stringByReplacingOccurrencesOfString:@"*" withString: MSG_JAVA_VERSION_LATEST]
                        stringByReplacingOccurrencesOfString:@"+" withString: MSG_JAVA_VERSION_OR_LATER]];
            } else {
                expandedMessage = [NSString stringWithFormat:@"%@ %@",
                                   [NSString stringWithFormat:MSG_NO_SUITABLE_JAVA, normalizeJavaVersion(jvmVersion)],
                                   [NSString stringWithFormat:MSG_JAVA_VERSION_MAX, [normalizeJavaVersion(jvmMaxVersion) stringByReplacingOccurrencesOfString:@"*" withString: MSG_JAVA_VERSION_LATEST]]];
            }
            NSLog(@"[%s] [EXIT 3] %@", appName, expandedMessage);
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setMessageText:[NSString stringWithFormat:MSG_ERROR_LAUNCHING, appName]];
            [alert setInformativeText:[NSString stringWithFormat:@"%@\n%@", expandedMessage, MSG_NO_SUITABLE_JAVA_CHECK]];
            [alert addButtonWithTitle:MSG_LATER];
            [alert addButtonWithTitle:MSG_VISIT_JAVA_DOT_COM];
            [alert addButtonWithTitle:MSG_VISIT_ADOPTIUM];
            NSModalResponse res = [alert runModal];
            if(res == NSAlertSecondButtonReturn) {
                [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://www.java.com/download/"]];
            } else if(res == NSAlertThirdButtonReturn) {
                [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://adoptium.net/temurin/releases/"]];
            }
            exit(3);
        } else {
            NSLog(@"[%s] [EXIT 1] %@", appName, MSG_INSTALL_JAVA);
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setMessageText:[NSString stringWithFormat:MSG_ERROR_LAUNCHING, appName]];
            [alert setInformativeText:MSG_INSTALL_JAVA];
            [alert addButtonWithTitle:MSG_LATER];
            [alert addButtonWithTitle:MSG_VISIT_JAVA_DOT_COM];
            [alert addButtonWithTitle:MSG_VISIT_ADOPTIUM];
            NSModalResponse res = [alert runModal];
            if(res == NSAlertSecondButtonReturn) {
                [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://www.java.com/download/"]];
            } else if(res == NSAlertThirdButtonReturn) {
                [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://adoptium.net/temurin/releases/"]];
            }
            exit(1);
        }
    }

    if(mainClass == nil) {
        NSLog(@"[%s] [EXIT 2] %@", appName, MSG_MISSING_MAINCLASS);
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:[NSString stringWithFormat:MSG_ERROR_LAUNCHING, appName]];
        [alert setInformativeText:MSG_MISSING_MAINCLASS];
        [alert runModal];
        exit(2);
    }

    chdir([workingDirectory UTF8String]);
    char cwd[PATH_MAX];
    getcwd(cwd, PATH_MAX);
    NSLog(@"[%s] [WorkingDirectory] %s", appName, cwd);
    if(bootstrapScript != nil && [fileManager isExecutableFileAtPath:bootstrapScript]) {
        execute(bootstrapScript, @[]);
    }
    if(jvmOptionsFile != nil && [fileManager fileExistsAtPath:jvmOptionsFile]) {
        NSString *optionsFile = [[NSString alloc] initWithData:[fileManager contentsAtPath:jvmOptionsFile] encoding:NSUTF8StringEncoding];
        NSArray *lines = [optionsFile componentsSeparatedByString:@"\n"];
        for(NSString *line in lines) {
            if([line hasPrefix:@"#"]) {
                continue;
            }
            [jvmDefaultOptions addObject:line];
        }
    }
    NSMutableArray *allArgs = [[NSMutableArray alloc] init];
    [allArgs addObject:javaCmd];
    [allArgs addObject:@"-cp"];
    [allArgs addObject:[classPath componentsJoinedByString:@":"]];
    if(splashFile != nil) {
        [allArgs addObject:[@"-splash:" stringByAppendingFormat:@"%@/%@", [main resourcePath], splashFile]];
    }
    [allArgs addObject:[@"-Xdock:icon=" stringByAppendingFormat:@"%@/%@", [main resourcePath], iconFile]];
    [allArgs addObject:[@"-Xdock:name=" stringByAppendingString:info[@"CFBundleName"]]];
    [allArgs addObjectsFromArray:jvmOptions];
    [allArgs addObjectsFromArray:jvmDefaultOptions];
    [allArgs addObject:mainClass];
    [allArgs addObjectsFromArray:mainArgs];
    for(int i = 1; i < argc; i++) {
        NSString *cliArg = [[NSString alloc] initWithCString:argv[i] encoding:NSUTF8StringEncoding];
        if(i == 1 && [cliArg hasPrefix:@"-psn"]) {
            break;
        }
        [allArgs addObject:cliArg];
    }

    int count = [allArgs count];
    char** cargs = malloc(sizeof(char*) * (count + 1));

    for (int i = 0; i < count; ++i) {
        cargs[i] = (char *) [[allArgs objectAtIndex:i] UTF8String];
    }

    cargs[count] = nil;
    NSLog(@"[%s] [Exec] %@", appName, [allArgs componentsJoinedByString:@" "]);

    execv([javaCmd UTF8String], cargs);
}

@implementation JVMMetadata
- (NSString *)description {
    return [NSString stringWithFormat: @"JVMMetadata: path=%@, version=%@", _path, _version];
}
@end

NSString *resolvePlaceholders(NSString *src, NSString *javaFolder) {
    NSBundle *main = [NSBundle mainBundle];

    NSString *ret = src;
    ret = [ret
            stringByReplacingOccurrencesOfString:@"$APP_PACKAGE"
                                      withString:[main bundlePath]];
    ret = [ret
            stringByReplacingOccurrencesOfString:@"$APP_ROOT"
                                      withString:[main bundlePath]];
    ret = [ret
            stringByReplacingOccurrencesOfString:@"$JAVAROOT"
                                      withString:javaFolder];
    ret = [ret
            stringByReplacingOccurrencesOfString:@"$USER_HOME"
                                      withString:NSHomeDirectory()];
    return ret;
}

NSString *execute(NSString *command, NSArray *args) {
    NSTask *task = [[NSTask alloc]init];
    [task setLaunchPath:command];
    [task setArguments:args];

    NSPipe *pipe = [[NSPipe alloc]init];
    [task setStandardOutput: pipe];
    [task setStandardError: pipe];
    [task launch];

    NSData *data = [[pipe fileHandleForReading] readDataToEndOfFile];
    NSString *output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

    [task waitUntilExit];

    return output;
}

NSString *fetchJavaVersion(NSString *path) {
    NSString *result = execute(path, @[@"-version"]);
    // The actual version will be between the first two quotes in the result
    // We can reasonably ignore all the rest of the output
    return [result componentsSeparatedByString:@"\""][1];
}

NSString *normalizeJavaVersion(NSString *version) {
    if([version hasPrefix:@"1."]) {
        version = [version substringFromIndex:2];
    }
    return [version stringByReplacingOccurrencesOfString:@"_" withString:@"."];
}

BOOL isValidRequirement(NSString *version) {
    NSString *versionPatterns = @"^(1\\.[4-8](\\.[0-9]+)?(\\.0_[0-9]+)?[*+]?|[0-9]+(-ea|[*+]|(\\.[0-9]+){1,2}[*+]?)?)$";
    NSPredicate *test = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", versionPatterns];

    return [test evaluateWithObject: version];
}

BOOL versionMeetsConstraint(NSString *version, NSString *constraint, BOOL hasMax) {
    NSArray *versionParts = [version componentsSeparatedByString:@"."];
    NSArray *constraintParts = [constraint componentsSeparatedByString:@"."];
    BOOL exceeds = NO;
    for(int i = 0; i < constraintParts.count; i++) {
        int v = [versionParts[i] intValue];
        int c = [constraintParts[i] intValue];
        if(v < c) {
            return NO;
        }
        if(v > c) {
            exceeds = YES;
            break;
        }
    }
    // At this point the numeric parts are all the same or greater, so compare the suffixes
    // to see which rule to apply
    char constraintModifier = [constraint characterAtIndex:([constraint length] - 1)];
    // If there's a max, the bottom constraint is always effectively a min
    if(constraintModifier == '+' || hasMax) {
        return YES;
    } else {
        // no modifier is equivalent to an implicit *
        return !exceeds;
    }
}

BOOL versionMeetsMaxConstraint(NSString *version, NSString *constraint) {
    NSArray *versionParts = [version componentsSeparatedByString:@"."];
    NSArray *constraintParts = [constraint componentsSeparatedByString:@"."];
    BOOL exceeds = NO;
    for(int i = 0; i < [constraintParts count]; i++) {
        if([constraintParts[i] length] == 0) {
            break;
        }
        int v = [versionParts[i] intValue];
        int c = [constraintParts[i] intValue];
        if(v < c) {
            return YES;
        }
        if(v > c) {
            exceeds = YES;
            break;
        }
    }

    // At this point the numeric parts are all the same or greater, so compare the suffixes
    // to see which rule to apply
    char constraintModifier = [constraint characterAtIndex:([constraint length] - 1)];
    if(constraintModifier == '+') {
        return YES;
    } else if(constraintModifier == '*') {
        return !exceeds;
    } else {
        // no modifier means it must match exactly
        return !exceeds && [constraintParts count] == [versionParts count];
    }
}