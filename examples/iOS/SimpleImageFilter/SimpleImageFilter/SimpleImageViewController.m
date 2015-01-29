#import "SimpleImageViewController.h"

@implementation SimpleImageViewController

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)loadView
{    
    CGRect mainScreenFrame = [[UIScreen mainScreen] applicationFrame];	
	GPUImageView *primaryView = [[GPUImageView alloc] initWithFrame:mainScreenFrame];
	self.view = primaryView;
    
    imageSlider = [[UISlider alloc] initWithFrame:CGRectMake(25.0, mainScreenFrame.size.height - 50.0, mainScreenFrame.size.width - 50.0, 40.0)];
    [imageSlider addTarget:self action:@selector(updateSliderValue:) forControlEvents:UIControlEventValueChanged];
	imageSlider.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    imageSlider.minimumValue = -10.0;
    imageSlider.maximumValue = 10.0;
    imageSlider.value = 5.0;
    
    [primaryView addSubview:imageSlider];
    
    [self setupDisplayFiltering];
    [self updateSliderValue:imageSlider];
    
//    [self setupImageResampling];
//    [self setupImageFilteringToDisk];
    [self setup16BitImageFilteringToDisk];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if (interfaceOrientation == UIInterfaceOrientationPortrait)
    {
        return YES;
    }
    return NO;
}


- (IBAction)updateSliderValue:(id)sender
{
    CGFloat midpoint = [(UISlider *)sender value];    
    [(GPUImageExposureFilter*)sepiaFilter setExposure:midpoint];

    [sourcePicture processData];
}

#pragma mark -
#pragma mark Image filtering

- (void)setupDisplayFiltering;
{
    NSData *floatData;
    NSURL *inputDataURL;
    
    inputDataURL = [[NSBundle mainBundle] URLForResource:@"sourcef" withExtension:@"dat"];
    floatData = [NSData dataWithContentsOfURL:inputDataURL];
//    sourcePicture = [[GPUImagePicture alloc] initWithFloatImageData:floatData
//                                                          imageSize:CGSizeMake(1920, 1080)];
    
    sourcePicture = [[GPUImageRawDataInput alloc] initWithBytes:(GLubyte *)[floatData bytes]
                                                           size:CGSizeMake(1920, 1080)
                                                    pixelFormat:GPUPixelFormatRGBA
                                                           type:GPUPixelTypeFloat];
    
    sepiaFilter = [[GPUImageExposureFilter alloc] init];
    
    GPUImageView *imageView = (GPUImageView *)self.view;
    [sepiaFilter forceProcessingAtSize:imageView.sizeInPixels]; // This is now needed to make the filter run at the smaller output size
    
    [sourcePicture addTarget:sepiaFilter];
    [sepiaFilter addTarget:imageView];

    [sourcePicture processData];
}

- (void)setupImageFilteringToDisk;
{
    NSData *floatData;
    NSURL *inputDataURL;
    
    inputDataURL = [[NSBundle mainBundle] URLForResource:@"sourcef" withExtension:@"dat"];
    floatData = [NSData dataWithContentsOfURL:inputDataURL];
    //    GPUImagePicture *stillImageSource = [[GPUImagePicture alloc] initWithFloatImageData:floatData
    //                                                          imageSize:CGSizeMake(1920, 1080)];
    
    GPUImageRawDataInput *stillImageSource = [[GPUImageRawDataInput alloc] initWithBytes:(GLubyte *)[floatData bytes]
                                                                                    size:CGSizeMake(1920, 1080)
                                                                             pixelFormat:GPUPixelFormatRGBA
                                                                                    type:GPUPixelTypeFloat];
    
    GPUImageExposureFilter *stillImageFilter = [[GPUImageExposureFilter alloc] init];
    
    [stillImageSource addTarget:stillImageFilter];
    [stillImageFilter useNextFrameForImageCapture];
    [stillImageFilter setExposure:5.0];
    
    [stillImageSource processData];
    
    NSError *error = nil;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    @autoreleasepool {
        UIImage *currentFilteredImage = [stillImageFilter imageFromCurrentFramebuffer];
        
        NSData *dataForPNGFile = UIImagePNGRepresentation(currentFilteredImage);
        if (![dataForPNGFile writeToFile:[documentsDirectory stringByAppendingPathComponent:@"8bit-filtered.png"] options:NSAtomicWrite error:&error])
        {
            NSLog(@"Error: Couldn't save image 1");
        }
        dataForPNGFile = nil;
        currentFilteredImage = nil;
    }
}

- (void)setup16BitImageFilteringToDisk
{
    NSData *floatData;
    NSURL *inputDataURL;
    
    inputDataURL = [[NSBundle mainBundle] URLForResource:@"sourcef" withExtension:@"dat"];
    floatData = [NSData dataWithContentsOfURL:inputDataURL];
    //    GPUImagePicture *stillImageSource = [[GPUImagePicture alloc] initWithFloatImageData:floatData
    //                                                          imageSize:CGSizeMake(1920, 1080)];
    
    GPUImageRawDataInput *stillImageSource = [[GPUImageRawDataInput alloc] initWithBytes:(GLubyte *)[floatData bytes]
                                                                                    size:CGSizeMake(1920, 1080)
                                                                             pixelFormat:GPUPixelFormatRGBA
                                                                                    type:GPUPixelTypeFloat];
    
    GPUImageExposureFilter *stillImageFilter = [[GPUImageExposureFilter alloc] init];
    
    [stillImageSource addTarget:stillImageFilter];
    [stillImageFilter useNextFrameForImageCapture];
    [stillImageFilter setExposure:5.0];
    
    GPUTextureOptions defaultTextureOptions;
    defaultTextureOptions.minFilter = GL_LINEAR;
    defaultTextureOptions.magFilter = GL_LINEAR;
    defaultTextureOptions.wrapS = GL_CLAMP_TO_EDGE;
    defaultTextureOptions.wrapT = GL_CLAMP_TO_EDGE;
    defaultTextureOptions.internalFormat = GL_RGBA;
    defaultTextureOptions.format = GL_RGBA;
    defaultTextureOptions.type = GL_HALF_FLOAT_OES;
    
    [stillImageFilter setOutputTextureOptions:defaultTextureOptions];
    [stillImageSource processData];
    
    NSError *error = nil;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    @autoreleasepool {
        NSData *floatData = [stillImageFilter floatDataFromCurrentlyProcessedOutput];
        NSLog(@"got data: %d",((uint32_t *)[floatData bytes])[10]);
        if (![floatData writeToFile:[documentsDirectory stringByAppendingPathComponent:@"filterded-float.dat"] options:NSAtomicWrite error:&error])
        {
            NSLog(@"Error: Couldn't save image 1");
        }
        floatData = nil;
    }
}



@end
