//
//  ViewController.m
//  Tools
//
//  Created by 吴狄 on 16/3/2.
//  Copyright © 2016年 wudi. All rights reserved.
//

#import "ViewController.h"


@interface ViewController ()<NSTextViewDelegate>

@property (unsafe_unretained) IBOutlet NSTextView *inputTextView;

@property (unsafe_unretained) IBOutlet NSTextView *outputTextView;

@property (nonatomic,strong) NSMutableString *inputStr;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
    
    self.inputTextView.delegate = self;
    
}


#pragma mark -- NSTextViewDelegate -- start

- (void)textDidEndEditing:(NSNotification *)notification{
    
    NSTextView *textView =  notification.object;
    
    NSLog(@"%@",textView.string);
    
    self.inputStr = [NSMutableString stringWithString:textView.string];
    
    [self.inputStr replaceOccurrencesOfString:@" " withString:@"" options:NSBackwardsSearch range:NSMakeRange(0, self.inputStr.length)];
    
    
     NSLog(@"self.inputStr:%@",self.inputStr);
    
     ClearRecvFlag();
    
    for (int i =0; i< self.inputStr.length; i+=2) {
        
        char data = ([self.inputStr characterAtIndex:i] -'0')*16 + ([self.inputStr characterAtIndex:i+1] - '0');
        
        data = strtoul([[self.inputStr substringWithRange:NSMakeRange(i, 2)] UTF8String],0 ,16);
        
        if (BreakupRecvPack(data) == 0) {
            
            self.outputTextView.string = output;
            
            
        }
        
    }
    
}
#pragma mark -- NSTextViewDelegate -- end



- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

@end
