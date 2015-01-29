#import <UIKit/UIKit.h>
#import "GPUImage.h"

@interface SimpleImageViewController : UIViewController
{
    GPUImageRawDataInput *sourcePicture;
    GPUImageOutput<GPUImageInput> *sepiaFilter, *sepiaFilter2;
    
    UISlider *imageSlider;
}

// Image filtering
- (void)setupDisplayFiltering;
- (void)setupImageFilteringToDisk;
- (void)setupImageResampling;

- (IBAction)updateSliderValue:(id)sender;

@end
