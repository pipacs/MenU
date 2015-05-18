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
static NSString * const kAppGroup = @"group.dk.unwire.MenU";
static NSString * const kStorageKeyMenu = @"menu";
static const CGFloat kRowHeight = 240;

@interface TableController()
@property (nonatomic, strong) NSTimer *updateTimer;
@property (nonatomic, strong) NSArray *completeMenu;
@property (nonatomic, strong) ISO8601DateFormatter *inputDateFormatter;
@property (nonatomic, strong) NSDateFormatter *outputDateFormatter;
@property (nonatomic, strong) NSUserDefaults *sharedDefaults;
@end

@implementation TableController

- (instancetype)init {
    self = [super init];
    if (self) {
        self.updateTimer = [NSTimer timerWithTimeInterval:kUpdateInterval target:self selector:@selector(update) userInfo:nil repeats:YES];
        self.inputDateFormatter = [[ISO8601DateFormatter alloc] init];
        self.inputDateFormatter.parsesStrictly = NO;
        self.outputDateFormatter = [[NSDateFormatter alloc] init];
        [self.outputDateFormatter setDateStyle:NSDateFormatterLongStyle];
        [self.outputDateFormatter setTimeStyle:NSDateFormatterNoStyle];
        self.sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:kAppGroup];
        if (!self.sharedDefaults) {
            NSLog(@"TableController:init: Could not create shared defaults");
        }
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
        self.completeMenu = newMenu;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self reloadTable];
        });
    });
}

- (void)reloadTable {
    [self.tableView reloadData];
}

#pragma mark - Menu Property

- (void)setCompleteMenu:(NSArray *)menu {
    NSLog(@"TableController:setCompleteMenu");
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:menu];
    [self.sharedDefaults setObject:data forKey:kStorageKeyMenu];
    [self.sharedDefaults synchronize];
}

- (NSArray *)completeMenu {
    NSData *data = [self.sharedDefaults objectForKey:kStorageKeyMenu];
    if (data) {
        return (NSArray *)[NSKeyedUnarchiver unarchiveObjectWithData:data];
    } else {
        NSLog(@"TableController:completeMenu: No menu");
        return nil;
    }
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.completeMenu.count;
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
      result.attributedStringValue = [self formatMenuItem:row];
      return result;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    return kRowHeight;
}

- (NSAttributedString *)formatMenuItem:(NSInteger)row {
    if (row < 0 || row >= self.completeMenu.count) {
        return nil;
    }
    NSDictionary *item = self.completeMenu[row];
    NSMutableAttributedString *text = [[NSMutableAttributedString alloc] init];
    if (item[@"serving_date"]) {
        NSDate *servingDate = [self.inputDateFormatter dateFromString:item[@"serving_date"]];
        [text appendAttributedString:[[NSAttributedString alloc] initWithString:[self.outputDateFormatter stringFromDate:servingDate]]];
    }
    if (item[@"main_course"]) {
        [text appendAttributedString:[self toBold:@"\n\nMain Course: "]];
        [text appendAttributedString:[[NSAttributedString alloc] initWithString:item[@"main_course"]]];
    }
    if (item[@"sides"]) {
        [text appendAttributedString:[self toBold:@"\n\nSides: "]];
        [text appendAttributedString:[[NSAttributedString alloc] initWithString:item[@"sides"]]];
    }
    [text appendAttributedString:[self toBold:@"\n\nCake: "]];
    [text appendAttributedString:[[NSAttributedString alloc] initWithString:([item[@"cake"] boolValue]? @"Yes": @"No")]];
    return text;
}

- (NSAttributedString *)toBold:(NSString *)string {
    NSMutableAttributedString *ret = [[NSMutableAttributedString alloc] initWithString:string];
    [ret addAttribute:NSForegroundColorAttributeName value:[NSColor darkGrayColor] range:NSMakeRange(0, string.length)];
    return ret;
}

@end
