//
//  Menu.m
//  MenU
//
//  Created by Akos Polster on 26/05/15.
//  Copyright (c) 2015 Akos Polster. All rights reserved.
//

#import "Menu.h"

static const NSTimeInterval kUpdateInterval = 60. * 60. * 8.;
static NSString * const kUrl = @"http://unwire-menu.herokuapp.com/menus";
static NSString * const kAppGroup = @"group.dk.unwire.MenU";
static NSString * const kStorageKeyMenu = @"menu";

@interface Menu()
@property (nonatomic, strong) NSTimer *updateTimer;
@property (nonatomic, strong) NSArray *completeMenu;
@property (nonatomic, strong) NSUserDefaults *sharedDefaults;
@end

@implementation Menu

#pragma mark - Public API

+ (Menu *)instance {
    static Menu *instance_;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        instance_ = [[Menu alloc] init];
    });
    return instance_;
}

- (NSArray *)allMenus {
    NSData *data = [self.sharedDefaults objectForKey:kStorageKeyMenu];
    return data? (NSArray *)[NSKeyedUnarchiver unarchiveObjectWithData:data]: nil;
}

- (void)setAllMenus:(NSArray *)allMenus {
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:allMenus];
    if (data) {
        [self.sharedDefaults setObject:data forKey:kStorageKeyMenu];
    } else {
        [self.sharedDefaults removeObjectForKey:kStorageKeyMenu];
    }
    [self.sharedDefaults synchronize];
}

- (NSDictionary *)todaysMenu {
    NSInteger today = (NSInteger)([[NSDate date] timeIntervalSince1970] / 3600. / 24.);
    for (NSDictionary *item in self.allMenus) {
        if (!item[@"serving_date"]) {
            continue;
        }
        double servingSeconds = [item[@"serving_date"] doubleValue];
        NSInteger servingDay = (NSInteger)(servingSeconds / 3600. / 24.);
        if (servingDay == today) {
            return item;
        }
    }
    return nil;
}

#pragma mark - Life Cycle

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:kUpdateInterval target:self selector:@selector(update) userInfo:nil repeats:YES];
    [self.updateTimer fire];
    self.sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:kAppGroup];
    [self update];
    return self;
}

- (void)dealloc {
    [self.updateTimer invalidate];
}

#pragma mark - Internal

- (void)update {
    NSURL *url = [NSURL URLWithString:kUrl];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
    dispatch_async(queue, ^{
        NSURLResponse *response = nil;
        NSError *error = nil;
        NSData *receivedData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        if (error || !receivedData) {
            NSLog(@"Menu:update: %@", error? error: @"Request failed");
            return;
        }
        NSError *jsonError = nil;
        NSArray *newMenu = [NSJSONSerialization JSONObjectWithData:receivedData options:0 error:&jsonError];
        if (jsonError || !newMenu) {
            NSLog(@"Menu:update: %@", jsonError? jsonError: @"Invalid response");
            return;
        }
        self.allMenus = newMenu;
    });
}

@end
