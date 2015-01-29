#import <UIKit/UIKit.h>
#import "GPUImageOutput.h"


@interface GPUImagePicture : GPUImageOutput
{
    CGSize pixelSizeOfImage;
    BOOL hasProcessedImage;
    BOOL reprocessImageWhenDone;
		
    dispatch_semaphore_t imageUpdateSemaphore;
}

// Initialization and teardown
- (id)initWithURL:(NSURL *)url;
- (id)initWithImage:(UIImage *)newImageSource;
- (id)initWithCGImage:(CGImageRef)newImageSource;
- (id)initWithImage:(UIImage *)newImageSource smoothlyScaleOutput:(BOOL)smoothlyScaleOutput;
- (id)initWithCGImage:(CGImageRef)newImageSource smoothlyScaleOutput:(BOOL)smoothlyScaleOutput;

//pomfort-extension: create image from float data buffer
- (id)initWithFloatImageData:(NSData *)floatImageData imageSize:(CGSize)imageSize;

// Image rendering
- (void)processImage;
- (CGSize)outputImageSize;

/**
 * Process image with all targets and filters asynchronously
 * The completion handler is called after processing finished in the
 * GPU's dispatch queue - and only if this method did not return NO.
 *
 * @returns NO if resource is blocked and processing is discarded, YES otherwise
 */
- (BOOL)processImageWithCompletionHandler:(void (^)(void))completion;

/**
 * Optional argument extends method above.
 * The final completion will be triggered when no new image processes are queued
 */
- (BOOL)processImageWithCompletionHandler:(void (^)(void))completion finalCompletionBlock:(void (^)(void))finalCompletion;

@end
