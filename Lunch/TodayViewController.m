//
//  TodayViewController.m
//  Lunch
//
//  Created by Akos Polster on 18/05/15.
//  Copyright (c) 2015 Akos Polster. All rights reserved.
//

#import "TodayViewController.h"
#import <NotificationCenter/NotificationCenter.h>

#import "ISO8601DateFormatter.h"

static NSString * const kUrl = @"http://unwire-menu.herokuapp.com/menus";
static NSString * const kAppGroup = @"group.dk.unwire.MenU";
static NSString * const kStorageKeyMenu = @"menu";
static const CGFloat kTopMargin = 40;
static const CGFloat kBottomMargin = 60;

@interface TodayViewController () <NCWidgetProviding>
@property (weak) IBOutlet NSTextField *todayTextField;
@property (nonatomic, strong) NSArray *completeMenu;
@property (nonatomic, strong) ISO8601DateFormatter *inputDateFormatter;
@property (nonatomic, strong) NSDateFormatter *outputDateFormatter;
@property (nonatomic, strong) NSUserDefaults *sharedDefaults;
@end

@implementation TodayViewController

#pragma mark - Life Cycle

- (instancetype)init {
    NSLog(@"TodayViewController:init");
    self = [super init];
    if (self) {
        self.completeMenu = [NSArray array];
        self.inputDateFormatter = [[ISO8601DateFormatter alloc] init];
        self.inputDateFormatter.parsesStrictly = NO;
        self.outputDateFormatter = [[NSDateFormatter alloc] init];
        [self.outputDateFormatter setDateStyle:NSDateFormatterLongStyle];
        [self.outputDateFormatter setTimeStyle:NSDateFormatterNoStyle];
        self.sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:kAppGroup];
    }
    return self;
}

- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult result))completionHandler {
    // Update your data and prepare for a snapshot. Call completion handler when you are done
    // with NoData if nothing has changed or NewData if there is new data since the last
    // time we called you
    NSLog(@"TodayViewController:widgetPerformUpdateWithCompletionHandler");
    [self update];
    completionHandler(NCUpdateResultNewData);
}

#pragma mark - Menu Property

- (void)setCompleteMenu:(NSArray *)menu {
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:menu];
    [self.sharedDefaults setObject:data forKey:kStorageKeyMenu];
    [self.sharedDefaults synchronize];
}

- (NSArray *)completeMenu {
    NSData *data = [self.sharedDefaults objectForKey:kStorageKeyMenu];
    if (data) {
        return (NSArray *)[NSKeyedUnarchiver unarchiveObjectWithData:data];
    } else {
        return nil;
    }
}

#pragma mark - Utilities

- (void)update {
    NSLog(@"TodayViewController:update");
    [self updateUi];
    NSURL *url = [NSURL URLWithString:kUrl];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
    dispatch_async(queue, ^{
        NSURLResponse *response = nil;
        NSError *error = nil;
        NSData *receivedData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        if (error || !receivedData) {
            NSLog(@"TodayViewController:update: %@", error? error: @"Request failed");
            return;
        }
        NSError *jsonError = nil;
        NSArray *newMenu = [NSJSONSerialization JSONObjectWithData:receivedData options:0 error:&jsonError];
        if (jsonError || !newMenu) {
            NSLog(@"TodayViewController:update: %@", jsonError? jsonError: @"Invalid response");
            return;
        }
        NSLog(@"TodayViewController:update: Got menu: %@", newMenu);
        self.completeMenu = newMenu;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateUi];
        });
    });
}

- (void)updateUi {
    NSDictionary *todaysItem = [self findTodaysItem];
    NSAttributedString *text = [self formatMenuItem:todaysItem];
    CGRect rect = [text boundingRectWithSize:CGSizeMake(self.todayTextField.bounds.size.width, 10000) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading];
    [self.todayTextField setAttributedStringValue:[self formatMenuItem:todaysItem]];
    NSLog(@"TodayViewController: %@x%@ -> %@x%@", @(self.preferredContentSize.width), @(self.preferredContentSize.height), @(rect.size.width), @(rect.size.height));
    self.preferredContentSize = CGSizeMake(self.preferredContentSize.width, rect.size.height + kBottomMargin + kTopMargin);
}

- (NSDictionary *)findTodaysItem {
    NSInteger today = (NSInteger)([[NSDate date] timeIntervalSince1970] / 3600. / 24.);
    for (NSDictionary *item in self.completeMenu) {
        if (!item[@"serving_date"]) {
            continue;
        }
        NSDate *servingDate = [self.inputDateFormatter dateFromString:item[@"serving_date"]];
        NSInteger servingDay = (NSInteger)([servingDate timeIntervalSince1970] / 3600. / 24.);
        if (servingDay == today) {
            return item;
        }
    }
    return nil;
}

- (NSAttributedString *)formatMenuItem:(NSDictionary *)item {
    if (!item) {
        return [[NSAttributedString alloc] initWithString:@"No menu"];
    }
    NSMutableAttributedString *text = [[NSMutableAttributedString alloc] init];
    if (item[@"main_course"]) {
        [text appendAttributedString:[self toBold:@"Main Course: "]];
        [text appendAttributedString:[[NSAttributedString alloc] initWithString:item[@"main_course"]]];
    }
    if (item[@"sides"]) {
        [text appendAttributedString:[self toBold:@"\nSides: "]];
        [text appendAttributedString:[self toBold:item[@"sides"]]];
    }
    [text appendAttributedString:[self toBold:@"\nCake: "]];
    [text appendAttributedString:[[NSAttributedString alloc] initWithString:([item[@"cake"] boolValue]? @"Yes": @"No")]];
    return text;
}

- (NSAttributedString *)toBold:(NSString *)string {
    NSMutableAttributedString *ret = [[NSMutableAttributedString alloc] initWithString:string];
    [ret addAttribute:NSForegroundColorAttributeName value:[NSColor grayColor] range:NSMakeRange(0, string.length)];
    return ret;
}

@end

