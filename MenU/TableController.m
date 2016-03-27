//
//  Created by Akos Polster on 15/05/15.
//  Copyright (c) 2015 Akos Polster. All rights reserved.
//

#import "TableController.h"
#import "Menu.h"

static const CGFloat kRowHeight = 240;

@interface TableController()
@property (nonatomic, strong) NSDateFormatter *modelDateFormatter;
@property (nonatomic, strong) NSDateFormatter *displayDateFormatter;
@property (nonatomic, strong) Menu *menu;
@end

@implementation TableController

- (instancetype)init {
    self = [super init];
    if (self) {
        self.modelDateFormatter = [[NSDateFormatter alloc] init];
        self.modelDateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
        self.displayDateFormatter = [[NSDateFormatter alloc] init];
        self.displayDateFormatter.dateStyle = NSDateFormatterLongStyle;
        self.displayDateFormatter.timeStyle = NSDateFormatterNoStyle;
        self.menu = [Menu instance];
        [self.menu addObserver:self forKeyPath:@"allMenus" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    }
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.menu.allMenus.count;
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
    if (row < 0 || row >= self.menu.allMenus.count) {
        return nil;
    }
    NSDictionary *item = self.menu.allMenus[row];
    NSMutableAttributedString *text = [[NSMutableAttributedString alloc] init];
    if (item[@"serving_date"]) {
        NSDate *servingDate = [self.modelDateFormatter dateFromString:item[@"serving_date"]];
        [text appendAttributedString:[[NSAttributedString alloc] initWithString:[self.displayDateFormatter stringFromDate:servingDate]]];
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
