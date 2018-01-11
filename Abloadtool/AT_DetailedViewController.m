//
//  AT_DetailedViewController.m
//  Abloadtool
//
//  Created by Andreas Kreisl on 11.01.18.
//  Copyright © 2018 Andreas Kreisl. All rights reserved.
//

#import "AT_DetailedViewController.h"

@interface AT_DetailedViewController ()

@end

@implementation AT_DetailedViewController

- (id)init
{
    self = [super init];
    if (self) {
        // Init Navigation Controller + Buttons
        self.navigationItem.title = @"---";
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Zoom", @"Zoom") style:UIBarButtonItemStylePlain target:self action:@selector(changeZoom)];

        // Init Scroll View
        self.detailedScrollView = [[UIScrollView alloc] init];
        self.detailedScrollView.delegate = self;
        self.detailedScrollView.backgroundColor = [UIColor lightGrayColor];
        self.detailedScrollView.scrollEnabled = YES;
        self.detailedScrollView.canCancelContentTouches = NO;
        self.detailedScrollView.clipsToBounds = YES;
        self.detailedScrollView.indicatorStyle = UIScrollViewIndicatorStyleDefault;
        self.detailedScrollView.maximumZoomScale = 10.0;
        self.detailedScrollView.minimumZoomScale = 0.05;
        self.detailedScrollView.contentMode = UIViewContentModeCenter;
        self.view = self.detailedScrollView;
        
        // Init Image View
        self.imageView = [[UIImageView alloc] init];
        self.imageView.backgroundColor = [UIColor yellowColor];
        [self.view addSubview:self.imageView];
        
        // Tab
        UITapGestureRecognizer *tapTwice = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(changeZoom)];
        tapTwice.numberOfTapsRequired = 2;
        [self.view addGestureRecognizer:tapTwice];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.imageView setFrame:CGRectMake(0, 0, 128, 128)];
    [self.imageView setImageWithURLRequest:[NSURLRequest requestWithURL:self.imageURL] placeholderImage:[UIImage imageNamed:@"AppIcon"] success:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, UIImage * _Nonnull image) {
        self.imageView.image = image;
        [self.imageView setFrame:CGRectMake(0, 0, self.imageView.image.size.width, self.imageView.image.size.height)];
        [self changeZoom];
    } failure:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, NSError * _Nonnull error) {
        NSLog(@"ERROR");
    }];
}

- (void) viewDidDisappear:(BOOL)animated {
    [self.detailedScrollView setZoomScale:1.0 animated:NO];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    if(toInterfaceOrientation == UIInterfaceOrientationPortrait) {
        [self.navigationController setNavigationBarHidden:NO animated:YES];
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:YES];
        [self.tabBarController.tabBar setHidden:NO];
    } else {
        [self.navigationController setNavigationBarHidden:YES animated:YES];
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:YES];
        [self.tabBarController.tabBar setHidden:YES];
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    float s1 = self.detailedScrollView.frame.size.width / self.imageView.image.size.width;
    float s2 = self.detailedScrollView.frame.size.height / self.imageView.image.size.height;
    if(s2 < s1) s1 = s2;
    if(s1 >= self.detailedScrollView.minimumZoomScale && s1 <= self.detailedScrollView.maximumZoomScale)
        [self.detailedScrollView setZoomScale:s1 animated:YES];
    self.navigationController.visibleViewController.title = [NSString stringWithFormat:NSLocalizedString(@"Zoom: %.2fx", @"Zoom Title"),s1];
}

#pragma mark - ScrollView

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return [[scrollView subviews] objectAtIndex:0];
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale {
    if(self.imageView.frame.size.width < scrollView.frame.size.width && self.imageView.frame.size.height < scrollView.frame.size.height) {
        float s1 = scrollView.frame.size.width / self.imageView.image.size.width;
        float s2 = scrollView.frame.size.height / self.imageView.image.size.height;
        if(s2 < s1) s1 = s2;
        if(s1 >= scrollView.minimumZoomScale && s1 <= scrollView.maximumZoomScale)
            [scrollView setZoomScale:s1 animated:YES];
    }
    self.navigationController.visibleViewController.title = [NSString stringWithFormat:NSLocalizedString(@"Zoom: %.2fx", @"Zoom Title"),scale];
}

- (void)changeZoom {
    NSLog(@"\n\no:%ld - w:%0.1lf h:%0.1lf - w:%0.1lf h:%0.1lf   \n\n", self.imageView.image.imageOrientation, self.imageView.image.size.width, self.imageView.image.size.height, self.detailedScrollView.contentSize.width, self.detailedScrollView.contentSize.height);
    if(self.detailedScrollView.zoomScale != 1.0) {
        [self.detailedScrollView setZoomScale:1.0 animated:YES];
        self.navigationController.visibleViewController.title = [NSString stringWithFormat:NSLocalizedString(@"Zoom: %.2fx", @"Zoom Title"),1.0];
    } else {
        float s1 = self.detailedScrollView.frame.size.width / self.imageView.image.size.width;
        float s2 = self.detailedScrollView.frame.size.height / self.imageView.image.size.height;
        if(s2 < s1) s1 = s2;
        if(s1 >= self.detailedScrollView.minimumZoomScale && s1 <= self.detailedScrollView.maximumZoomScale)
            [self.detailedScrollView setZoomScale:s1 animated:YES];
        self.navigationController.visibleViewController.title = [NSString stringWithFormat:NSLocalizedString(@"Zoom: %.2fx", @"Zoom Title"),s1];
    }
}



@end
