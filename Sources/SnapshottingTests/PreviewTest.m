#import "PreviewTest.h"
#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>
#import <objc/runtime.h>

@interface PreviewTest()
@property (nonatomic, strong) NSMutableArray<NSString *> *dynamicTestSelectors;
@end

@implementation PreviewTest

static NSString *resultPath;
static NSMutableArray<NSString *> *imagePaths;

NSString* getDylibPath(NSString* dylibName) {
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const char *imagePath = _dyld_get_image_name(i);
        NSString *imagePathStr = [NSString stringWithUTF8String:imagePath];
        if ([imagePathStr.lastPathComponent isEqualToString:dylibName]) {
            return imagePathStr;
        }
    }
    return nil;
}

+ (NSArray<NSInvocation *> *)testInvocations {
  PreviewTest *dynamicTest = [[self alloc] init];
    [dynamicTest generateSnapshots];

    NSMutableArray<NSInvocation *> *invocations = [NSMutableArray array];
    for (NSString *testName in dynamicTest.dynamicTestSelectors) {
        SEL selector = NSSelectorFromString(testName);
        NSMethodSignature *signature = [dynamicTest methodSignatureForSelector:selector];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        invocation.selector = selector;
        [invocations addObject:invocation];
    }
    return invocations;
}

- (XCUIApplication *)getApp {
  return nil;
}

- (NSArray<NSString *> *)snapshotPreviews {
  return NULL;
}

- (void)generateSnapshots {

  XCUIApplication *app = [self getApp];

  if (app == nil) {
    return;
  }

  NSString *path = getDylibPath(@"Snapshotting");
  NSMutableDictionary *launchEnvironment = [@{
    @"EMERGE_IS_RUNNING_FOR_SNAPSHOTS": @"1",
    @"DYLD_INSERT_LIBRARIES": path
  } mutableCopy];
  NSArray *previews = [self snapshotPreviews];
  if (previews) {
    launchEnvironment[@"SNAPSHOT_PREVIEWS"] = previews;
  }
  app.launchEnvironment = launchEnvironment;
  [app launch];

  XCUIElement *label = app.staticTexts[@"emg_finished_label"];
  NSPredicate *exists = [NSPredicate predicateWithFormat:@"exists == 1"];

  [self expectationForPredicate:exists evaluatedWithObject:label handler:nil];
  [self waitForExpectationsWithTimeout:14 handler:nil];

  XCTAssertTrue(label.exists);

  resultPath = label.label;

  NSLog(@"Images can be found in %@", path);

  NSError *error = nil;
  NSArray<NSString *> *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:resultPath error:&error];
  if (error) {
    XCTFail(@"Error while fetching directory files: %@", [error localizedDescription]);
  } else {
    imagePaths = [NSMutableArray array];
    self.dynamicTestSelectors = [NSMutableArray array];
    NSArray<NSString *> *sortedFiles = [files sortedArrayUsingSelector:@selector(compare:)];
    int i = 0;
      for (NSString *file in sortedFiles) {
          if ([file hasSuffix:@".png"]) {
            [imagePaths addObject:file];
            NSString *testSelectorName = [NSString stringWithFormat:@"%@-%d", [file stringByDeletingPathExtension], i];
            [self.dynamicTestSelectors addObject:testSelectorName];

            class_addMethod([self class], NSSelectorFromString(testSelectorName), (IMP) dynamicTestMethod, "v@:");
            i++;
          }
      }
  }
}

void dynamicTestMethod(id self, SEL _cmd) {
    NSString *selectorName = NSStringFromSelector(_cmd);
  NSString *testNumber = [selectorName componentsSeparatedByString:@"-"].lastObject;
  int index = testNumber.intValue;

  NSString *imageName = imagePaths[index];
  NSString *imagePath = [resultPath stringByAppendingFormat:@"/%@", imageName];
  UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
  NSData *imageData = UIImagePNGRepresentation(image);
  if (imageData) {
    XCTAttachment *attachment = [XCTAttachment attachmentWithUniformTypeIdentifier:@"public.png" name:@"Rendered Preview" payload:imageData userInfo:nil];
      attachment.lifetime = XCTAttachmentLifetimeKeepAlways;
      [self addAttachment:attachment];
  }
}

@end
