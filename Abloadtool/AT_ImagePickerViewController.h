//
//  AT_ImagePickerViewController.h
//  Abloadtool
//
//  Created by Andreas Kreisl on 19.03.18.
//  Copyright © 2018 Andreas Kreisl. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import "UIImage+Scale.h"

#import "NetworkManager.h"
#import "AT_ImagePickerCollectionViewCell.h"

@interface AT_ImagePickerViewController : UICollectionViewController <UIImagePickerControllerDelegate>
@property NSMutableArray *albumArr;
@property NSInteger selectedAlbum;
@property NSMutableIndexSet* selectedImages;
@property BOOL firstView;

- (void)prepareDisplay;

@end
