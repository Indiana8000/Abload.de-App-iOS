//
//  AT_AboutViewController.m
//  Abloadtool
//
//  Created by Andreas Kreisl on 27.10.17.
//  Copyright © 2017 Andreas Kreisl. All rights reserved.
//

#import "AT_AboutViewController.h"

@interface AT_AboutViewController ()
    @property (nonatomic) UILabel* abloadLabel;
    @property (nonatomic) UILabel* bluepawLabel;
    @property (nonatomic) UIImageView* abloadImage;
    @property (nonatomic) UIImageView* bluepawImage;
@end

@implementation AT_AboutViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor lightGrayColor];
    self.navigationItem.title = NSLocalizedString(@"About Us", @"About Us");

    
    self.abloadLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 80.0, self.view.frame.size.width, 30.0)];
    [self initLabel:self.abloadLabel];
    self.abloadLabel.text = NSLocalizedString(@"This service is brought to you by", @"This service is brought to you by");
    [self.view addSubview:self.abloadLabel];
    
    self.abloadImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo_abload"]];
    [self initImage:self.abloadImage];
    self.abloadImage.center = CGPointMake(self.view.center.x, self.abloadImage.frame.size.height/2 + 80 +30);
    [self.view addSubview:self.abloadImage];

    
    self.bluepawLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 240.0, self.view.frame.size.width, 30.0)];
    [self initLabel:self.bluepawLabel];
    self.bluepawLabel.text = NSLocalizedString(@"App developed by", @"App developed by");
    [self.view addSubview:self.bluepawLabel];
    
    self.bluepawImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo_bluepaw"]];
    [self initImage:self.bluepawImage];
    self.bluepawImage.center = CGPointMake(self.view.center.x, self.bluepawImage.frame.size.height/2 + 240 + 30);
    [self.view addSubview:self.bluepawImage];
}

- (void)initLabel:(UILabel*)lbl {
    lbl.backgroundColor = [UIColor clearColor];
    lbl.textColor = [UIColor whiteColor];
    lbl.textAlignment = NSTextAlignmentCenter;
    lbl.font = [UIFont systemFontOfSize:18];
    lbl.layer.shadowColor = [UIColor blackColor].CGColor;
    lbl.layer.shadowOpacity = 0.85;
    lbl.layer.shadowRadius = 1.5;
    lbl.layer.shadowOffset = CGSizeMake(1.0, 2.0);
}

- (void)initImage:(UIImageView*)img {
    img.layer.shadowColor = [UIColor blackColor].CGColor;
    img.layer.shadowOpacity = 0.70;
    img.layer.shadowRadius = 2.5;
    img.layer.shadowOffset = CGSizeMake(1.0, 2.0);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillLayoutSubviews {
    self.abloadLabel.frame = CGRectMake(0.0, self.view.center.y - self.abloadImage.frame.size.height -50, self.view.frame.size.width, 30.0);
    self.abloadImage.center = CGPointMake(self.view.center.x, self.view.center.y - self.abloadImage.frame.size.height/2 -15);

    self.bluepawLabel.frame = CGRectMake(0.0, self.view.center.y + 10, self.view.frame.size.width, 30.0);
    self.bluepawImage.center = CGPointMake(self.view.center.x, self.view.center.y + self.bluepawImage.frame.size.height/2 +45);
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [[event allTouches] anyObject];
    NSDictionary *tmpDict = [[NSDictionary alloc] initWithObjectsAndKeys: @"x", @"x", nil];
    if ( [touch locationInView:self.view].y < self.view.center.y ) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.abload.de/"] options:tmpDict completionHandler:nil];
    } else {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.bluepaw.de/"] options:tmpDict completionHandler:nil];
    }
}

@end
