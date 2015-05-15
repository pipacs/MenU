//
//  ViewController.m
//  MenU
//
//  Created by Akos Polster on 15/05/15.
//  Copyright (c) 2015 Akos Polster. All rights reserved.
//

#import "ViewController.h"

@interface ViewController() 
@end

@implementation ViewController

#pragma mark - Life Cycle

- (instancetype)initWithCoder:(NSCoder *)coder {
    NSLog(@"ViewController:initWithCoder");
    self = [super initWithCoder:coder];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
}

//- (void)setRepresentedObject:(id)representedObject {
//    [super setRepresentedObject:representedObject];
//
//    // Update the view, if already loaded.
//}

@end
