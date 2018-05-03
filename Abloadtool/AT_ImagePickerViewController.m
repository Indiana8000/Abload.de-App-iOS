//
//  AT_ImagePickerViewController.m
//  Abloadtool
//
//  Created by Andreas Kreisl on 19.03.18.
//  Copyright © 2018 Andreas Kreisl. All rights reserved.
//

#import "AT_ImagePickerViewController.h"

@interface AT_ImagePickerViewController ()
@property MBProgressHUD *progressHUD;
@property BOOL firstLoad;
@property PHFetchOptions *fetchOptions;
@property UICollectionViewController* collectionViewController;
@property UIBarButtonItem* btnDone;
@property UIBarButtonItem* btnCount;
@property UIImageView* btnCountView;
@property UILabel* btnCountLabel;
@property UIBarButtonItem* btnCamera;
@property UIImagePickerController* pickerController;
@property NSInteger observerEnabled;
@end

@implementation AT_ImagePickerViewController

#pragma mark - Contructor

- (instancetype)initWithCollectionViewLayout:(UICollectionViewLayout *)layout {
    self = [super initWithCollectionViewLayout:layout];
    self.selectedImages = [[NSMutableIndexSet alloc] init];
    self.firstLoad = YES;
    
    self.fetchOptions = [[PHFetchOptions alloc] init];
    self.fetchOptions.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", PHAssetMediaTypeImage];
    
    [self.collectionView registerClass:[AT_ImagePickerCollectionViewCell class] forCellWithReuseIdentifier:@"cCollectionViewCellImage"];
    self.collectionView.alwaysBounceVertical = YES;
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"label_cancel", @"ImagePicker") style:UIBarButtonItemStylePlain target:self action:@selector(cancleView)];
    
    UIBarButtonItem* btnSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    self.btnCamera = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:self action:@selector(takePicture)];
    if(![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        self.btnCamera.enabled = NO;
    }
    self.btnDone = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"label_done", @"ImagePicker") style:UIBarButtonItemStyleDone target:self action:@selector(saveAndDone)];

    self.btnCountView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"photo_number_icon"]];
    self.btnCount = [[UIBarButtonItem alloc] initWithCustomView:self.btnCountView];
    
    self.btnCountLabel = [[UILabel alloc] init];
    self.btnCountLabel.adjustsFontSizeToFitWidth = YES;
    self.btnCountLabel.text = @"0";
    self.btnCountLabel.textAlignment = NSTextAlignmentCenter;
    self.btnCountLabel.textColor = [UIColor whiteColor];
    [self.btnCountView addSubview:self.btnCountLabel];
    self.btnCountLabel.frame = CGRectMake(2.0, 0.0, self.btnCountView.bounds.size.width -4.0, self.btnCountView.bounds.size.height);

    [self setToolbarItems:@[self.btnCamera, btnSpace, self.btnCount, self.btnDone]];
    
    self.pickerController = [[UIImagePickerController alloc] init];
    self.pickerController.delegate = (id)self;

    self.observerEnabled = 0;
    
    return self;
}

#pragma mark - ViewDelegate

- (void)prepareDisplay {
    [self showProgressHUD];
    if(self.firstLoad) {
        [self getAllAlbums];
        self.selectedAlbum = 0;
        self.firstLoad = NO;
    } else {
        [self getImages];
    }
    [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:(id)self];
    [self hideProgressHUD];
}

- (void)cancleView {
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:(id)self];
    [self.selectedImages removeAllIndexes];
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.collectionView reloadData];
    self.navigationItem.title = [[self.albumArr objectAtIndex:self.selectedAlbum] objectForKey:@"localizedTitle"];
    [self.navigationController setToolbarHidden:NO animated:animated];
    [self updateCounterButton];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setToolbarHidden:YES animated:animated];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [self setItemSize:size];
    [self.collectionView reloadData];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    [self setItemSize:self.view.bounds.size];
}

- (void)setItemSize:(CGSize)newSize {
    UICollectionViewFlowLayout *flowLayout = (id)self.collectionViewLayout;
    CGFloat itemMargin = 3.0f;
    flowLayout.sectionInset = UIEdgeInsetsMake(itemMargin, itemMargin, itemMargin, itemMargin);
    flowLayout.minimumInteritemSpacing = itemMargin;
    flowLayout.minimumLineSpacing = itemMargin;
    CGFloat i = ceil(newSize.width / 120.0);
    if(i < 3) i = 3; if(i > 6) i = 6;
    CGFloat itemSize = (newSize.width - (i + 1) * itemMargin) / i;
    flowLayout.itemSize = CGSizeMake(itemSize, itemSize);
}

- (void)updateCounterButton {
    self.btnCountLabel.text = [NSString stringWithFormat:@"%ld", [self.selectedImages count]];
    if([self.selectedImages count] > 0) {
        self.btnDone.enabled = YES;
        self.btnCountView.hidden = NO;

        NSNumber *animationScale1 = @(0.5);
        NSNumber *animationScale2 = @(1.15);
        [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut animations:^{
            [self.btnCountView.layer setValue:animationScale1 forKeyPath:@"transform.scale"];
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut animations:^{
                [self.btnCountView.layer setValue:animationScale2 forKeyPath:@"transform.scale"];
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut animations:^{
                    [self.btnCountView.layer setValue:@(1.0) forKeyPath:@"transform.scale"];
                } completion:nil];
            }];
        }];
    } else {
        self.btnDone.enabled = NO;
        self.btnCountView.hidden = YES;
    }
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [[[self.albumArr objectAtIndex:self.selectedAlbum] objectForKey:@"fetchResult"] count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    AT_ImagePickerCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cCollectionViewCellImage" forIndexPath:indexPath];
    
    if([self.selectedImages containsIndex:indexPath.row]) {
        cell.isSelected = YES;
    } else {
        cell.isSelected = NO;
    }
    
    PHFetchResult* fetchResult = [[self.albumArr objectAtIndex:self.selectedAlbum] objectForKey:@"fetchResult"];
    PHAsset* asset = [fetchResult objectAtIndex:indexPath.row];
    [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:[(UICollectionViewFlowLayout*)self.collectionViewLayout itemSize] contentMode:PHImageContentModeAspectFill options:nil resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        if (result) {
            cell.imageView.image = result;
        }
    }];
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    AT_ImagePickerCollectionViewCell *cell = (AT_ImagePickerCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    if([self.selectedImages containsIndex:indexPath.row]) {
        [self.selectedImages removeIndex:indexPath.row];
        cell.isSelected = NO;
    } else {
        [self.selectedImages addIndex:indexPath.row];
        cell.isSelected = YES;
    }
    [self updateCounterButton];
}
#pragma mark - ImagePicker

- (void)takePicture {
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
        if(granted) {
            self.observerEnabled = 2;
            self.pickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
            [self presentViewController:self.pickerController animated:YES completion:nil];
        } else {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                           message:NSLocalizedString(@"msg_no_access_camera", @"ImagePicker")
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *ok = [UIAlertAction actionWithTitle:NSLocalizedString(@"btn_settings", @"Upload Tab")  style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * action) {
                                                           [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:[[NSDictionary alloc] init] completionHandler:nil];
                                                       }];
            [alert addAction:ok];
            
            UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"net_login_cancel", @"NetworkManager") style:UIAlertActionStyleCancel
                                                           handler:^(UIAlertAction * action) {
                                                               [alert dismissViewControllerAnimated:YES completion:nil];
                                                           }];
            [alert addAction:cancel];
            
            [self presentViewController:alert animated:YES completion:nil];        }
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
    self.observerEnabled = 0;
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    if(self.selectedAlbum != 0) {
        self.selectedAlbum = 0;
        [self.selectedImages removeAllIndexes];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.navigationItem.title = [[self.albumArr objectAtIndex:self.selectedAlbum] objectForKey:@"localizedTitle"];
        });
    }
    [picker dismissViewControllerAnimated:YES completion:nil];
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        NSData *data = UIImageJPEGRepresentation(image, 0.9);
        PHAssetResourceCreationOptions *options = [[PHAssetResourceCreationOptions alloc] init];
        options.shouldMoveFile = YES;
        PHAssetCreationRequest *request = [PHAssetCreationRequest creationRequestForAsset];
        [request addResourceWithType:PHAssetResourceTypePhoto data:data options:options];
        request.creationDate = [NSDate date];
    } completionHandler:^(BOOL success, NSError *error) {
        if(success) {
            [self getImages];
            NSUInteger item = [[[self.albumArr objectAtIndex:self.selectedAlbum] objectForKey:@"fetchResult"] count] -1;
            [self.selectedImages addIndex:item];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.collectionView reloadData];
                [self updateCounterButton];
                [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:item inSection:0] atScrollPosition:UICollectionViewScrollPositionBottom animated:YES];
            });
        } else {
            NSLog(@"didFinishPickingMediaWithInfo withError: %@",error.localizedDescription);
            self.observerEnabled = 0;
        }
    }];
}

#pragma mark - Other

- (void)showProgressHUD {
    [self hideProgressHUD];
    self.progressHUD = [MBProgressHUD showHUDAddedTo:[[UIApplication sharedApplication] delegate].window animated:YES];
    [self.progressHUD removeFromSuperViewOnHide];
    self.progressHUD.label.text = NSLocalizedString(@"label_loading_album", @"ImagePicker");
    self.progressHUD.bezelView.color = [UIColor colorWithWhite:0.1 alpha:1.0];
    self.progressHUD.contentColor = [UIColor whiteColor];
}

- (void)hideProgressHUD {
    if (self.progressHUD != nil) {
        [self.progressHUD hideAnimated:YES];
        [self.progressHUD removeFromSuperview];
        self.progressHUD = nil;
    }
}

- (void)getAllAlbums {
    NSMutableArray* tmpArr = [NSMutableArray array];

    PHFetchResult *myPhotoStreamAlbum = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumMyPhotoStream options:nil];
    PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    PHFetchResult *topLevelUserCollections = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];
    PHFetchResult *syncedAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumSyncedAlbum options:nil];
    PHFetchResult *sharedAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumCloudShared options:nil];
    NSArray *allAlbums = @[myPhotoStreamAlbum,smartAlbums,topLevelUserCollections,syncedAlbums,sharedAlbums];
    
    for (PHFetchResult *fetchResult in allAlbums) {
        for (PHAssetCollection *collection in fetchResult) {
            if (![collection isKindOfClass:[PHAssetCollection class]]) continue;
            PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:self.fetchOptions];
            if (fetchResult.count < 1) continue;
            
            NSMutableDictionary* albumObj = [[NSMutableDictionary alloc] init];
            [albumObj setObject:collection forKey:@"collection"];
            [albumObj setObject:collection.localizedTitle forKey:@"localizedTitle"];
            [albumObj setObject:fetchResult forKey:@"fetchResult"];

            if(collection.assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumUserLibrary) {
                [albumObj setObject:@"1" forKey:@"isCameraRoll"];
                [tmpArr insertObject:albumObj atIndex:0];
            } else {
                [albumObj setObject:@"0" forKey:@"isCameraRoll"];
                [tmpArr addObject:albumObj];
            }
        }
    }
    self.albumArr = tmpArr;
}

- (void)getImages {
    PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:[[self.albumArr objectAtIndex:self.selectedAlbum] objectForKey:@"collection"] options:self.fetchOptions];
    [[self.albumArr objectAtIndex:self.selectedAlbum] setObject:fetchResult forKey:@"fetchResult"];
}

- (void)photoLibraryDidChange:(PHChange *)changeInfo {
    if(self.observerEnabled <= 0) {
        NSLog(@"photoLibraryDidChange");
        NSUInteger oldCount = [[[self.albumArr objectAtIndex:self.selectedAlbum] objectForKey:@"fetchResult"] count];
        NSString *oldName = [[self.albumArr objectAtIndex:self.selectedAlbum] objectForKey:@"localizedTitle"];
        [self getAllAlbums];
        if(self.selectedAlbum < [self.albumArr count]) {
            if([oldName compare:[[self.albumArr objectAtIndex:self.selectedAlbum] objectForKey:@"localizedTitle"]] == NSOrderedSame) {
                if(oldCount != [[[self.albumArr objectAtIndex:self.selectedAlbum] objectForKey:@"fetchResult"] count]) {
                    while([self.selectedImages indexGreaterThanOrEqualToIndex:[[[self.albumArr objectAtIndex:self.selectedAlbum] objectForKey:@"fetchResult"] count]] != NSNotFound) {
                        NSUInteger tooLarge = [self.selectedImages indexGreaterThanOrEqualToIndex:[[[self.albumArr objectAtIndex:self.selectedAlbum] objectForKey:@"fetchResult"] count]];
                        [self.selectedImages removeIndex:tooLarge];
                    }
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.collectionView reloadData];
                        [self updateCounterButton];
                    });
                }
            } else {
                self.selectedAlbum = 0;
                [self.selectedImages removeAllIndexes];
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.navigationItem.title = [[self.albumArr objectAtIndex:self.selectedAlbum] objectForKey:@"localizedTitle"];
                    [self.collectionView reloadData];
                    [self updateCounterButton];
                });
            }
        } else {
            self.selectedAlbum = 0;
            [self.selectedImages removeAllIndexes];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.navigationItem.title = [[self.albumArr objectAtIndex:self.selectedAlbum] objectForKey:@"localizedTitle"];
                [self.collectionView reloadData];
                [self updateCounterButton];
            });
        }
    } else {
        self.observerEnabled--;
    }
}

- (void)saveAndDone {
    [[NetworkManager sharedManager] showProgressHUD];
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
            @autoreleasepool {
                PHFetchResult* fetchResult = [[self.albumArr objectAtIndex:self.selectedAlbum] objectForKey:@"fetchResult"];
                PHImageRequestOptions* requestOptions = [[PHImageRequestOptions alloc] init];
                requestOptions.networkAccessAllowed = YES;
                requestOptions.synchronous = YES;
                requestOptions.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
                
                [self.selectedImages enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
                    PHAsset* asset = [fetchResult objectAtIndex:idx];
                    [[PHImageManager defaultManager] requestImageDataForAsset:asset options:requestOptions resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
                        if(imageData)
                            [[NetworkManager sharedManager] saveImageToDisk:imageData];
                    }];
                }];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NetworkManager sharedManager] hideProgressHUD];
                    [self cancleView];
                });
            }
    });
}



@end
