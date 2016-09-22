//
//  ViewController.m
//  Face
//
//  Created by Keith on 16/9/22.
//  Copyright © 2016年 Keith. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()<UIImagePickerControllerDelegate,UINavigationControllerDelegate>

@property (nonatomic,weak) IBOutlet UIImageView *imageView;
@property (nonatomic,weak) IBOutlet UILabel *label;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.title = @"人脸识别";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"选择图片" style:UIBarButtonItemStylePlain target:self action:@selector(addImage:)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"人脸识别" style:UIBarButtonItemStylePlain target:self action:@selector(faceRecognition:)];
}

-(void)addImage:(id)sender{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"添加照片" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *p = [UIAlertAction actionWithTitle:@"拍照" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self takePhoto:UIImagePickerControllerSourceTypeCamera];
    }];
    [alert addAction:p];
    UIAlertAction *s = [UIAlertAction actionWithTitle:@"从相册选择" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self takePhoto:UIImagePickerControllerSourceTypePhotoLibrary];
    }];
    [alert addAction:s];
    UIAlertAction *c = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
        
    }];
    [alert addAction:c];
    [self.navigationController presentViewController:alert animated:YES completion:nil];
}

-(void)takePhoto:(UIImagePickerControllerSourceType)sourceType{
    if (![UIImagePickerController isSourceTypeAvailable:sourceType]) {
        return;
    }
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    picker.sourceType = sourceType;
    [self.navigationController presentViewController:picker animated:YES completion:nil];
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
    [picker dismissViewControllerAnimated:YES completion:nil];
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    self.label.hidden = YES;
    image = [self rotateImage:image];
    self.imageView.image = image;
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

-(void)faceRecognition:(id)sender{
    UIImage *image = self.imageView.image;
    for (UIView *v in self.imageView.subviews) {
        [v removeFromSuperview];
    }
    CIImage *ciimage = [CIImage imageWithCGImage:image.CGImage];
    NSDictionary *opts = @{CIDetectorAccuracy:CIDetectorAccuracyHigh};
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeFace context:nil options:opts];
    NSArray *faces = [detector featuresInImage:ciimage];
    if (!faces.count) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:@"未检测到人脸" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *c = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            [self.navigationController dismissViewControllerAnimated:YES completion:nil];
        }];
        [alert addAction:c];
        [self.navigationController presentViewController:alert animated:YES completion:nil];
        return;
    }
    for (CIFaceFeature *face in faces) {
        
        CGRect frame = [self faceRect:face.bounds];
        UIView *view = [[UIView alloc] initWithFrame:frame];
        view.layer.borderWidth = 1;
        view.layer.borderColor = [UIColor redColor].CGColor;
        [self.imageView addSubview:view];
        CGFloat width = view.bounds.size.width / 4;
        
        //left eye
        if (face.hasLeftEyePosition) {
            UIView* leftEyeView = [[UIView alloc] initWithFrame:CGRectMake(0,0, width * 0.3, width * 0.3)];
            [leftEyeView setBackgroundColor:[[UIColor redColor] colorWithAlphaComponent:0.5]];
            [leftEyeView setCenter:[self facePoint:face.leftEyePosition]];
            leftEyeView.layer.cornerRadius = width * 0.15;
            [self.imageView addSubview:leftEyeView];
        }
        
        //right eye
        if (face.hasRightEyePosition) {
            UIView* rightEyeView = [[UIView alloc] initWithFrame:CGRectMake(0,0, width * 0.3, width * 0.3)];
            [rightEyeView setBackgroundColor:[[UIColor redColor] colorWithAlphaComponent:0.5]];
            [rightEyeView setCenter:[self facePoint:face.rightEyePosition]];
            rightEyeView.layer.cornerRadius = width * 0.15;
            [self.imageView  addSubview:rightEyeView];
        }
        
        // mouth
        if (face.hasMouthPosition) {
            UIView* mouth = [[UIView alloc] initWithFrame:CGRectMake(face.mouthPosition.x - width * 0.2,face.mouthPosition.y - width * 0.2, width * 0.4, width * 0.4)];
            [mouth setBackgroundColor:[[UIColor greenColor] colorWithAlphaComponent:0.5]];
            [mouth setCenter:[self facePoint:face.mouthPosition]];
            mouth.layer.cornerRadius = width * 0.2;
            [self.imageView addSubview:mouth];
        }
    }
}

-(CGRect)faceRect:(CGRect)bounds{
    UIImage *image = self.imageView.image;
    CIImage *ciimage = [CIImage imageWithCGImage:image.CGImage];
    CGSize size = ciimage.extent.size;
    CGAffineTransform tf = CGAffineTransformIdentity;
    tf = CGAffineTransformScale(tf, 1, -1);
    tf = CGAffineTransformTranslate(tf, 0, -size.height);

    CGRect rect = CGRectApplyAffineTransform(bounds, tf);
    CGFloat scale = MIN(self.imageView.frame.size.width / size.width,self.imageView.frame.size.height / size.height);
    CGFloat offsetX = (self.imageView.bounds.size.width - size.width * scale) / 2;
    CGFloat offsetY = (self.imageView.bounds.size.height - size.height * scale) / 2;
    rect = CGRectApplyAffineTransform(rect, CGAffineTransformMakeScale(scale, scale));
    rect.origin.x += offsetX;
    rect.origin.y += offsetY;
    return rect;
}

-(CGPoint)facePoint:(CGPoint)p{
    UIImage *image = self.imageView.image;
    CIImage *ciimage = [CIImage imageWithCGImage:image.CGImage];
    CGSize size = ciimage.extent.size;
    CGAffineTransform tf = CGAffineTransformIdentity;
    tf = CGAffineTransformScale(tf, 1, -1);
    tf = CGAffineTransformTranslate(tf, 0, -size.height);
    
    CGPoint point = CGPointApplyAffineTransform(p, tf);
    CGFloat scale = MIN(self.imageView.frame.size.width / size.width,self.imageView.frame.size.height / size.height);
    CGFloat offsetX = (self.imageView.bounds.size.width - size.width * scale) / 2;
    CGFloat offsetY = (self.imageView.bounds.size.height - size.height * scale) / 2;
    point = CGPointApplyAffineTransform(point, CGAffineTransformMakeScale(scale, scale));
    point.x += offsetX;
    point.y += offsetY;

    return point;
}


-(UIImage *)rotateImage:(UIImage *)image{
    int kMaxResolution = 2000; // Or whatever
    CGImageRef imgRef = image.CGImage;
    
    CGFloat width = CGImageGetWidth(imgRef);
    CGFloat height = CGImageGetHeight(imgRef);
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    CGRect bounds = CGRectMake(0, 0, width, height);
    if (width > kMaxResolution || height > kMaxResolution) {
        CGFloat ratio = width/height;
        if (ratio > 1) {
            bounds.size.width = kMaxResolution;
            bounds.size.height = bounds.size.width / ratio;
        }
        else {
            bounds.size.height = kMaxResolution;
            bounds.size.width = bounds.size.height * ratio;
        }
    }
    
    CGFloat scaleRatio = bounds.size.width / width;
    CGSize imageSize = CGSizeMake(CGImageGetWidth(imgRef), CGImageGetHeight(imgRef));
    CGFloat boundHeight;
    UIImageOrientation orient = image.imageOrientation;
    switch(orient) {
            
        case UIImageOrientationUp: //EXIF = 1
            transform = CGAffineTransformIdentity;
            break;
            
        case UIImageOrientationUpMirrored: //EXIF = 2
            transform = CGAffineTransformMakeTranslation(imageSize.width, 0.0);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            break;
            
        case UIImageOrientationDown: //EXIF = 3
            transform = CGAffineTransformMakeTranslation(imageSize.width, imageSize.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationDownMirrored: //EXIF = 4
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.height);
            transform = CGAffineTransformScale(transform, 1.0, -1.0);
            break;
            
        case UIImageOrientationLeftMirrored: //EXIF = 5
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(imageSize.height, imageSize.width);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
            
        case UIImageOrientationLeft: //EXIF = 6
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.width);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
            
        case UIImageOrientationRightMirrored: //EXIF = 7
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeScale(-1.0, 1.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
            
        case UIImageOrientationRight: //EXIF = 8
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(imageSize.height, 0.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
            
        default:
            [NSException raise:NSInternalInconsistencyException format:@"Invalid image orientation"];
            
    }
    
    UIGraphicsBeginImageContext(bounds.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    if (orient == UIImageOrientationRight || orient == UIImageOrientationLeft) {
        CGContextScaleCTM(context, -scaleRatio, scaleRatio);
        CGContextTranslateCTM(context, -height, 0);
    }
    else {
        CGContextScaleCTM(context, scaleRatio, -scaleRatio);
        CGContextTranslateCTM(context, 0, -height);
    }
    
    CGContextConcatCTM(context, transform);
    CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, width, height), imgRef);
    UIImage *imageCopy = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return imageCopy;
}
@end
