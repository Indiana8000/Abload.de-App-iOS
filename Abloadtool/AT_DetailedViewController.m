//
//  AT_DetailedViewController.m
//  Abloadtool
//
//  Created by Andreas Kreisl on 11.01.18.
//  Copyright © 2018 Andreas Kreisl. All rights reserved.
//

#import "AT_DetailedViewController.h"


@interface AT_DetailedViewController ()
@property UIPageControl* pageControl;
@property UIButton* arrowLeft;
@property UIButton* arrowRight;

@end


@implementation AT_DetailedViewController

- (id)init {
    self = [super init];
    if (self) {
        self.navigationItem.title = NSLocalizedString(@"label_loading", @"Image");
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"label_zoom", @"Image") style:UIBarButtonItemStylePlain target:self action:@selector(changeZoom)];
        self.view.backgroundColor = [UIColor lightGrayColor];
        
        self.detailedScrollView = [[UIScrollView alloc] init];
        self.detailedScrollView.delegate = self;
        self.detailedScrollView.backgroundColor = [UIColor clearColor];
        self.detailedScrollView.scrollEnabled = YES;
        self.detailedScrollView.canCancelContentTouches = NO;
        self.detailedScrollView.clipsToBounds = YES;
        self.detailedScrollView.indicatorStyle = UIScrollViewIndicatorStyleDefault;
        self.detailedScrollView.maximumZoomScale = 10.0;
        self.detailedScrollView.minimumZoomScale = 0.05;
        self.detailedScrollView.contentMode = UIViewContentModeCenter;
        //self.view = self.detailedScrollView;
        [self.view addSubview:self.detailedScrollView];
        
        self.imageView = [[UIImageView alloc] init];
        self.imageView.backgroundColor = [UIColor clearColor];
        [self.detailedScrollView addSubview:self.imageView];
        
        self.pageControl = [[UIPageControl alloc] init];
        self.pageControl.hidesForSinglePage = YES;
        self.pageControl.numberOfPages = 1;
        [self.view addSubview:self.pageControl];
        [self.pageControl addTarget:self action:@selector(pageChanged:) forControlEvents:UIControlEventValueChanged];
        
        self.arrowLeft = [UIButton buttonWithType:UIButtonTypeCustom];
        self.arrowLeft.alpha = 0.35f;
        self.arrowLeft.layer.shadowColor = [UIColor blackColor].CGColor;
        self.arrowLeft.layer.shadowRadius = 2.0f;
        self.arrowLeft.layer.shadowOpacity = 1.0f;
        self.arrowLeft.layer.shadowOffset = CGSizeMake(2.0f, 2.0f);
        [self.arrowLeft setImage:[UIImage imageNamed:@"arrow_left"] forState:UIControlStateNormal];
        [self.view addSubview:self.arrowLeft];
        [self.arrowLeft addTarget:self action:@selector(loadPrev) forControlEvents:UIControlEventTouchDown];

        self.arrowRight = [UIButton buttonWithType:UIButtonTypeCustom];
        self.arrowRight.alpha = 0.35f;
        self.arrowRight.layer.shadowColor = [UIColor blackColor].CGColor;
        self.arrowRight.layer.shadowRadius = 2.0f;
        self.arrowRight.layer.shadowOpacity = 1.0f;
        self.arrowRight.layer.shadowOffset = CGSizeMake(2.0f, 2.0f);
        [self.arrowRight setImage:[UIImage imageNamed:@"arrow_right"] forState:UIControlStateNormal];
        [self.view addSubview:self.arrowRight];
        [self.arrowRight addTarget:self action:@selector(loadNext) forControlEvents:UIControlEventTouchDown];


        UITapGestureRecognizer *tapTwice = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(changeZoom)];
        tapTwice.numberOfTapsRequired = 2;
        [self.view addGestureRecognizer:tapTwice];
        
        UISwipeGestureRecognizer *swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(loadNext)];
        swipeLeft.direction = UISwipeGestureRecognizerDirectionLeft;
        [self.view addGestureRecognizer:swipeLeft];

        UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(loadPrev)];
        swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
        [self.view addGestureRecognizer:swipeRight];

        UILongPressGestureRecognizer* longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onSelfLongPressGestureDetected:)];
        [self.view addGestureRecognizer:longPressGesture];
    }
    return self;
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return YES;
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    self.detailedScrollView.frame = self.view.bounds;

    CGSize pageControlleSize = [self.pageControl sizeForNumberOfPages:self.pageControl.numberOfPages];
    self.pageControl.frame = CGRectMake(  self.view.safeAreaInsets.left
                                        , self.view.bounds.size.height -self.view.safeAreaInsets.top -pageControlleSize.height
                                        , self.view.bounds.size.width -self.view.safeAreaInsets.left -self.view.safeAreaInsets.right
                                        , pageControlleSize.height);
    self.arrowLeft.frame = CGRectMake(  self.view.safeAreaInsets.left
                                      , self.view.bounds.size.height/2 -self.arrowLeft.currentImage.size.height/2
                                      , self.arrowLeft.currentImage.size.width
                                      , self.arrowLeft.currentImage.size.height);
    self.arrowRight.frame = CGRectMake( self.view.bounds.size.width -self.view.safeAreaInsets.right -self.arrowLeft.currentImage.size.width
                                       , self.view.bounds.size.height/2 -self.arrowLeft.currentImage.size.height/2
                                       , self.arrowLeft.currentImage.size.width
                                       , self.arrowLeft.currentImage.size.height);
}

#pragma mark - View

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self loadImage];
}

//- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
//    return YES;
//}

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
    self.navigationController.visibleViewController.title = [NSString stringWithFormat:NSLocalizedString(@"label_zoomed %.2fx", @"Image"),s1];
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
    self.navigationController.visibleViewController.title = [NSString stringWithFormat:NSLocalizedString(@"label_zoomed %.2fx", @"Image"),scale];
}

- (void)changeZoom {
    if(self.detailedScrollView.zoomScale != 1.0) {
        [self.detailedScrollView setZoomScale:1.0 animated:YES];
        self.navigationController.visibleViewController.title = [NSString stringWithFormat:NSLocalizedString(@"label_zoomed %.2fx", @"Image"),1.0];
    } else {
        float s1 = self.detailedScrollView.frame.size.width / self.imageView.image.size.width;
        float s2 = self.detailedScrollView.frame.size.height / self.imageView.image.size.height;
        if(s2 < s1) s1 = s2;
        if(s1 >= self.detailedScrollView.minimumZoomScale && s1 <= self.detailedScrollView.maximumZoomScale)
            [self.detailedScrollView setZoomScale:s1 animated:YES];
        self.navigationController.visibleViewController.title = [NSString stringWithFormat:NSLocalizedString(@"label_zoomed %.2fx", @"Image"),s1];
    }
}


#pragma mark - Image

- (void)loadImage {
    if([[self.imageList objectAtIndex:self.imageID] objectForKey:@"_uploaded"] && ([[[self.imageList objectAtIndex:self.imageID] objectForKey:@"_uploaded"] intValue] < 1)) {
        self.imageURL = [NSURL fileURLWithPath:[[self.imageList objectAtIndex:self.imageID] objectForKey:@"_path"]];
    } else {
        self.imageURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/img/%@", cURL_BASE, [[self.imageList objectAtIndex:self.imageID] objectForKey:@"_filename"]]];
    }
    
    self.pageControl.numberOfPages = [self.imageList count];
    self.pageControl.currentPage = self.imageID;

    __unsafe_unretained typeof(self) weakSelf = self;
    [self.detailedScrollView setZoomScale:1.0 animated:NO];
    [self.imageView setFrame:CGRectMake(0, 0, 128, 128)];
    [[NetworkManager sharedManager] showProgressHUD];
    self.imageView.hidden = YES;
    [self.imageView setImageWithURLRequest:[NSURLRequest requestWithURL:self.imageURL] placeholderImage:[UIImage imageNamed:@"AppIcon"] success:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, UIImage * _Nonnull image) {
        weakSelf.imageView.hidden = NO;
        [[NetworkManager sharedManager] hideProgressHUD];
        weakSelf.imageView.image = image;
        [weakSelf.imageView setFrame:CGRectMake(0, 0, weakSelf.imageView.image.size.width, weakSelf.imageView.image.size.height)];
        
        float s1 = self.detailedScrollView.frame.size.width / self.imageView.image.size.width;
        float s2 = self.detailedScrollView.frame.size.height / self.imageView.image.size.height;
        if(s2 < s1) s1 = s2;
        if(s1 >= self.detailedScrollView.minimumZoomScale && s1 <= self.detailedScrollView.maximumZoomScale)
            [weakSelf.detailedScrollView setZoomScale:s1 animated:NO];
        weakSelf.navigationController.visibleViewController.title = [NSString stringWithFormat:NSLocalizedString(@"label_zoomed %.2fx", @"Image"),s1];
        [weakSelf.imageView becomeFirstResponder];
    } failure:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, NSError * _Nonnull error) {
        [[NetworkManager sharedManager] hideProgressHUD];
        [NetworkManager showMessage:[error localizedDescription]];
    }];
}

- (void)loadNext {
    if([self.imageList count] > (++self.imageID)) {
        [self loadImage];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)loadPrev {
    if(0 <= (--self.imageID)) {
        [self loadImage];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)pageChanged:(id) sender {
    self.imageID = self.pageControl.currentPage;
    [self loadImage];
}

- (void)onSelfLongPressGestureDetected:(UILongPressGestureRecognizer*)pGesture {
    if(pGesture.state == UIGestureRecognizerStateBegan) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                       message:nil
                                                                preferredStyle:UIAlertControllerStyleActionSheet];
        
        UIAlertAction *btnSave = [UIAlertAction actionWithTitle:NSLocalizedString(@"label_download_image", @"Image") style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action) {
                                                       UIImageWriteToSavedPhotosAlbum(self.imageView.image, nil, nil, nil);
                                                   }];
        [alert addAction:btnSave];
        
        if([[self.imageList objectAtIndex:self.imageID] objectForKey:@"_uploaded"] && ([[[self.imageList objectAtIndex:self.imageID] objectForKey:@"_uploaded"] intValue] < 1)) {
            // Local Image have no Link
        } else {
            UIAlertAction *btnCopy = [UIAlertAction actionWithTitle:NSLocalizedString(@"btn_slide_copylink", @"Upload Tab") style:UIAlertActionStyleDefault
                                                            handler:^(UIAlertAction * action) {
                                                                [self showCopyLinkTypes];
                                                            }];
            [alert addAction:btnCopy];
        }
        
        UIAlertAction *btnCancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"net_login_cancel", @"NetworkManager") style:UIAlertActionStyleCancel
                                                       handler:^(UIAlertAction * action) {
                                                           [alert dismissViewControllerAnimated:YES completion:nil];
                                                       }];
        [alert addAction:btnCancel];
        
        alert.popoverPresentationController.sourceView = self.view;
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)showCopyLinkTypes {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    for(int i = 0;i < [[[NetworkManager sharedManager] settingAvailableOutputLinkList] count];++i) {
        UIAlertAction *linkX = [UIAlertAction actionWithTitle:[[[[NetworkManager sharedManager] settingAvailableOutputLinkList] objectAtIndex:i] objectForKey:@"name"]  style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * action) {
                                                          [[NetworkManager sharedManager] saveOutputLinkSelected:i];
                                                          [UIPasteboard generalPasteboard].string = [[NetworkManager sharedManager] generateLinkForImage:[[self.imageList objectAtIndex:self.imageID] objectForKey:@"_filename"]];
                                                      }];
        [alert addAction:linkX];
    }
    UIAlertAction *btnCancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"net_login_cancel", @"NetworkManager") style:UIAlertActionStyleCancel
                                                      handler:^(UIAlertAction * action) {
                                                          [alert dismissViewControllerAnimated:YES completion:nil];
                                                      }];
    [alert addAction:btnCancel];

    alert.popoverPresentationController.sourceView = self.view;
    [self presentViewController:alert animated:YES completion:nil];
}


@end
