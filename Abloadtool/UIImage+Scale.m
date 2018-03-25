//
//  UIImage+Scale.m
//  Abloadtool
//
//  Created by Andreas Kreisl on 02.06.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "UIImage+Scale.h"

@implementation UIImage (scale)

-(UIImage *)scaleToSize:(CGSize)size {
    // Create a bitmap graphics context
    // This will also set it as the current context
    UIGraphicsBeginImageContext(size);
    
    // Draw the scaled image in the current context
    [self drawInRect:CGRectMake(0, 0, size.width, size.height)];
    
    // Create a new image from current context
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    
    // Pop the current context from the stack
    UIGraphicsEndImageContext();
    
    // Return our new scaled image
    return scaledImage;
}

-(UIImage *)panToSize:(CGSize)size {
    CGRect thumbSize;
    if (self.size.width/self.size.height > size.width/size.height  ) {
        float newHeight = size.width / (self.size.width / self.size.height);
        thumbSize = CGRectMake(0, 0, size.width, newHeight);
    } else {
        float newWidth = size.height * self.size.width / self.size.height;
        thumbSize = CGRectMake(0, 0, newWidth , size.height );
    }
    
    // Create a bitmap graphics context (of the target size)
    // This will also set it as the current context
    UIGraphicsBeginImageContext(CGSizeMake(thumbSize.size.width, thumbSize.size.height));
    
    // Draw the image in the calculated area
    [self drawInRect:thumbSize];
    
    // Create a new image from current context
    UIImage *newThumbnail = UIGraphicsGetImageFromCurrentImageContext();
    
    // Pop the current context from the stack
    UIGraphicsEndImageContext();
    
    // Return our new thumbnail image
    return newThumbnail;
}

-(UIImage *)cutToSize:(CGSize)size {
    CGRect thumbSize;
    if (self.size.width/self.size.height > size.width/size.height  ) {
        float newWidth = size.height * self.size.width / self.size.height;
        thumbSize = CGRectMake( (size.width-newWidth)/2, 0, newWidth, size.height);
    } else {
        float newHeight = size.width / (self.size.width / self.size.height);
        thumbSize = CGRectMake(0, (size.height-newHeight)/2, size.width , newHeight );
    }
    
    // Create a bitmap graphics context (of the target size)
    // This will also set it as the current context
    UIGraphicsBeginImageContext(size);
    
    // Draw the image in the calculated area
    [self drawInRect:thumbSize];
    
    // Create a new image from current context
    UIImage *newThumbnail = UIGraphicsGetImageFromCurrentImageContext();
    
    // Pop the current context from the stack
    UIGraphicsEndImageContext();
    
    // Return our new thumbnail image
    return newThumbnail;
}


- (UIImage *)thumbnailOfSize:(CGSize)size {
    // Calculate new size with aspection ratio and centered in the target size
    CGRect thumbSize;
    if (self.size.width/self.size.height > size.width/size.height  ) {
        float newHeight = size.width / (self.size.width / self.size.height);
        thumbSize = CGRectMake(0, (size.height-newHeight)/2, size.width, newHeight);
    } else {
        float newWidth = size.height * self.size.width / self.size.height;
        thumbSize = CGRectMake(  (size.width-newWidth)/2 , 0 , newWidth , size.height );
    }
    
    // Create a bitmap graphics context (of the target size)
    // This will also set it as the current context
    UIGraphicsBeginImageContext(size);
    
    // Draw the image in the calculated area
    [self drawInRect:thumbSize];
    
    // Create a new image from current context
    UIImage *newThumbnail = UIGraphicsGetImageFromCurrentImageContext();
    
    // Pop the current context from the stack
    UIGraphicsEndImageContext();
    
    // Return our new thumbnail image
    return newThumbnail;
}

- (UIImage *)fixOrientation {
    // No-op if the orientation is already correct
    if (self.imageOrientation == UIImageOrientationUp)
        return self;
    
    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (self.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.width, self.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, self.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        default:
            break;
    }
    
    switch (self.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        default:
            break;
    }
    
    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, self.size.width, self.size.height,
                                             CGImageGetBitsPerComponent(self.CGImage), 0,
                                             CGImageGetColorSpace(self.CGImage),
                                             CGImageGetBitmapInfo(self.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (self.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(ctx, CGRectMake(0,0,self.size.height,self.size.width), self.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,self.size.width,self.size.height), self.CGImage);
            break;
    }
    
    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}


@end
