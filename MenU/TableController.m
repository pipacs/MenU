//
//  TableController.m
//  MenU
//
//  Created by Akos Polster on 15/05/15.
//  Copyright (c) 2015 Akos Polster. All rights reserved.
//

#import "TableController.h"
#import "ISO8601DateFormatter.h"

static const NSTimeInterval kUpdateInterval = 60. * 60. * 8.;
static NSString * const kUrl = @"http://unwire-menu.herokuapp.com/menus";
static const CGFloat kRowHeight = 240;

@interface TableController()
@property (nonatomic, strong) NSTimer *updateTimer;
@property (nonatomic, strong) NSArray *menu;
@property (nonatomic, strong) ISO8601DateFormatter *inputDateFormatter;
@property (nonatomic, strong) NSDateFormatter *outputDateFormatter;
@end

@implementation TableController

- (instancetype)init {
    self = [super init];
    if (self) {
        self.menu = [NSMutableArray array];
        self.updateTimer = [NSTimer timerWithTimeInterval:kUpdateInterval target:self selector:@selector(update) userInfo:nil repeats:YES];
        self.inputDateFormatter = [[ISO8601DateFormatter alloc] init];
        self.inputDateFormatter.parsesStrictly = NO;
        self.outputDateFormatter = [[NSDateFormatter alloc] init];
        [self.outputDateFormatter setDateStyle:NSDateFormatterLongStyle];
        [self.outputDateFormatter setTimeStyle:NSDateFormatterNoStyle];
        [self update];
    }
    return self;
}

- (void)dealloc {
    [self.updateTimer invalidate];
}

- (void)update {
    NSLog(@"TableController:update");
    NSURL *url = [NSURL URLWithString:kUrl];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
    dispatch_async(queue, ^{
        NSURLResponse *response = nil;
        NSError *error = nil;
        NSData *receivedData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        if (error || !receivedData) {
            NSLog(@"TableController:update: %@", error? error: @"Request failed");
            return;
        }
        NSError *jsonError = nil;
        NSArray *newMenu = [NSJSONSerialization JSONObjectWithData:receivedData options:0 error:&jsonError];
        if (jsonError || !newMenu) {
            NSLog(@"TableController:update: %@", jsonError? jsonError: @"Invalid response");
            return;
        }
        NSLog(@"TableController:update: Got menu: %@", newMenu);
        self.menu = newMenu;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self reloadTable];
        });
    });
}

- (void)reloadTable {
    [self.tableView reloadData];
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.menu.count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSTextField *result = [tableView makeViewWithIdentifier:@"MyView" owner:self];
    if (result == nil) {
         result = [[NSTextField alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, kRowHeight)];
         result.bordered = NO;
         result.identifier = @"MyView";
         result.backgroundColor = [NSColor clearColor];
         result.editable = NO;
      }
      result.stringValue = [self formatMenuItem:row];
      return result;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    return kRowHeight;
}

- (NSString *)formatMenuItem:(NSInteger)row {
    if (row < 0 || row >= self.menu.count) {
        return nil;
    }
    NSDictionary *item = self.menu[row];
    NSMutableString *text = [NSMutableString stringWithString:@""];
    if (item[@"serving_date"]) {
        NSDate *servingDate = [self.inputDateFormatter dateFromString:item[@"serving_date"]];
        [text appendFormat:@"%@", [self.outputDateFormatter stringFromDate:servingDate]];
    }
    if (item[@"main_course"]) {
        [text appendFormat:@"\n\nMain Course: %@", item[@"main_course"]];
    }
    if (item[@"sides"]) {
        [text appendFormat:@"\n\nSides: %@", item[@"sides"]];
    }
    [text appendFormat:@"\n\nCake: %@\n", [item[@"cake"] boolValue]? @"Yes": @"No"];
    return text;
}

@end
