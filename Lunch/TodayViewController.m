//
//  TodayViewController.m
//  Lunch
//
//  Created by Akos Polster on 18/05/15.
//  Copyright (c) 2015 Akos Polster. All rights reserved.
//

#import "TodayViewController.h"
#import <NotificationCenter/NotificationCenter.h>
#import "Menu.h"

static const CGFloat kTopMargin = 40;
static const CGFloat kBottomMargin = 60;

@interface TodayViewController () <NCWidgetProviding>
@property (weak) IBOutlet NSTextField *todayTextField;
@property (nonatomic, strong) NSDateFormatter *outputDateFormatter;
@property (nonatomic, strong) Menu *model;
@end

@implementation TodayViewController

#pragma mark - Life Cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        self.model = [Menu instance];
        self.outputDateFormatter = [[NSDateFormatter alloc] init];
        [self.outputDateFormatter setDateStyle:NSDateFormatterLongStyle];
        [self.outputDateFormatter setTimeStyle:NSDateFormatterNoStyle];
        [self.model addObserver:self forKeyPath:@"allMenus" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    }
    return self;
}

- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult result))completionHandler {
    [self updateUi];
    completionHandler(NCUpdateResultNewData);
}

#pragma mark - Utilities

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateUi];
    });
}

- (void)updateUi {
    NSDictionary *todaysItem = [self.model todaysMenu];
    NSAttributedString *text = [self formatMenuItem:todaysItem];
    CGRect rect = [text boundingRectWithSize:CGSizeMake(self.todayTextField.bounds.size.width, 10000) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading];
    [self.todayTextField setAttributedStringValue:[self formatMenuItem:todaysItem]];
    self.preferredContentSize = CGSizeMake(self.preferredContentSize.width, rect.size.height + kBottomMargin + kTopMargin);
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

