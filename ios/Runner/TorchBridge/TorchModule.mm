//
//  TorchModule.m
//  Runner
//
//  Created by Jeff Ward on 6/1/21.
//
#import "TorchModule.h"
#import <LibTorch-Lite/LibTorch-Lite.h>

@interface TorchModule()

@property(readwrite) int objectId;

@end

@implementation TorchModule {
@protected
  torch::jit::mobile::Module _impl;
}

- (nullable instancetype)initWithFileAtPath:(NSString*)filePath objectId:(int)objectId {
  self = [super init];
  if (self) {
    try {
      _impl = torch::jit::_load_for_mobile(filePath.UTF8String);
      //_impl.eval();
      objectId = objectId;
    } catch (const std::exception& exception) {
      NSLog(@"%s", exception.what());
      return nil;
    }
  }
  return self;
}

- (NSDictionary<NSString*, NSObject*>*)executeWithData:(NSData*)data width:(int)width height:(int)height {
  // Data is argb data and needs to be converted to float32
  uint8_t* raw = (uint8_t*)[data bytes];
  float* normalizedBuffer = new float[width*height*3];
  int pixelsCount = width*height;
  for(int i = 0; i < pixelsCount; ++i) {
      normalizedBuffer[i] = raw[i * 4 + 0] / 255.0f;
      normalizedBuffer[i + pixelsCount] = raw[i*4 + 1] / 255.0f;
      normalizedBuffer[i + pixelsCount + pixelsCount] = raw[i*4 + 2] / 255.0f;
  }

  at::Tensor tensor = torch::from_blob((void *)normalizedBuffer, {1, 3, width, height}, at::kFloat);
  c10::InferenceMode guard;
  auto outputTuple = _impl.forward({tensor}).toTuple();
  at::Tensor outputTensor = outputTuple->elements()[0].toTensor();
  delete [] normalizedBuffer;

  float* floatBuffer = outputTensor.data_ptr<float>();
  at::IntArrayRef sizes = outputTensor.sizes();

  NSMutableArray* shape = [[NSMutableArray alloc] initWithCapacity:sizes.size()];
  int totalSize = 1;
  for(auto i : sizes) {
    totalSize *= i;
    [shape addObject:[NSNumber numberWithLong:i]];
  }

  NSData* resultData = [NSData dataWithBytes:(void *)floatBuffer length:sizeof(float) * totalSize];
  return @{
    @"shape": shape,
    @"data": resultData
  };
}

- (NSArray<NSNumber*>*)predictImage:(void*)imageBuffer {
  try {
    at::Tensor tensor = torch::from_blob(imageBuffer, {1, 3, 224, 224}, at::kFloat);
    torch::autograd::AutoGradMode guard(false);
    at::AutoNonVariableTypeMode non_var_type_mode(true);
    auto outputTensor = _impl.forward({tensor}).toTensor();
    float* floatBuffer = outputTensor.data_ptr<float>();
    if (!floatBuffer) {
      return nil;
    }
    NSMutableArray* results = [[NSMutableArray alloc] init];
    for (int i = 0; i < 1000; i++) {
      [results addObject:@(floatBuffer[i])];
    }
    return [results copy];
  } catch (const std::exception& exception) {
    NSLog(@"%s", exception.what());
  }
  return nil;
}

@end
