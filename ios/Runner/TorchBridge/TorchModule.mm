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

- (NSData*)executeWithData:(NSData*)data width:(int)width height:(int)height {

  at::Tensor tensor = torch::from_blob((void *)[data bytes], {1, 3, width, height}, at::kQInt32);
  torch::autograd::AutoGradMode guard(false);
  at::AutoNonVariableTypeMode non_var_type_mode(true);
  at::Tensor outputTensor = _impl.forward({tensor}).toTensor();
  float* floatBuffer = outputTensor.data_ptr<float>();
  int totalSize = 0;
  for(auto i : tensor.sizes()) {
    totalSize += i;
  }

  double* doubleBuffer = new double[totalSize];
  for(int i = 0; i < totalSize; ++i) {
    doubleBuffer[i] = (double)floatBuffer[i];
  }
  NSData* resultData = [NSData dataWithBytes:(void *)doubleBuffer length:sizeof(double) * totalSize];
  return resultData;
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
