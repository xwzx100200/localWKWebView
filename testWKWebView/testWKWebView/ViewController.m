//
//  ViewController.m
//  testWKWebView
//
//  Created by i2p on 2020/8/4.
//  Copyright © 2020 i2p. All rights reserved.
//

#import "ViewController.h"
#import <WebKit/WebKit.h>
#import <SSZipArchive/SSZipArchive.h>
#import <AFNetworking/AFNetworking.h>
#import <MBProgressHUD/MBProgressHUD.h>

@interface ViewController ()<WKNavigationDelegate,WKUIDelegate>
@property(nonatomic,strong)WKWebView* webView;
@property(nonatomic,strong)MBProgressHUD* loadingView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self createLoadingView];
    [self loadHtmlSource];
}

//加载zip数据包
-(void)loadHtmlSource{
    
    
    NSString* urlStr = @"https://codeload.github.com/xwzx100200/myHtmlSource/zip/master";
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer.timeoutInterval = 60;
    manager.requestSerializer = [AFHTTPRequestSerializer serializer];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    [manager GET:urlStr parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {

        // 获取数据流，写入本地
        [self writeToFile:responseObject fileName:@"myHtmlSource-master"];

    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"%@",error);
    }];
    
    
}

// 写入文件
-(void)writeToFile:(NSData *)data fileName:(NSString *)fileName{

    NSString* document = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask,YES) firstObject];
    fileName = [NSString stringWithFormat:@"%@.zip",fileName];
    NSString * filePath = [document stringByAppendingPathComponent:fileName];
    BOOL success = [data writeToFile:filePath atomically:YES];
    NSLog(@"fileDataPath is %@", filePath);
    if (success) {
        [self decompressionFile];
    }
}

// 解压
-(void)decompressionFile {
    /*
        1、把原来的删除
        2、解压
     */
    
    NSString* document = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask,YES) firstObject];
    NSString* sourcePath = [document stringByAppendingString:@"myHtmlSource-master"];
    NSString *zipPath = [document stringByAppendingString:@"/myHtmlSource-master.zip"];
    NSFileManager* manager = [NSFileManager defaultManager];
    BOOL hasDir = [manager fileExistsAtPath:sourcePath];
    if (hasDir) {
        NSError* err;
        BOOL remove = [manager removeItemAtPath:sourcePath error:&err];
        if (!remove) {
            UIAlertView* alert = [[UIAlertView alloc]initWithTitle:@"" message:@"解压失败！" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:@"取消", nil];
            [alert show];
            return;
        }
    }
    
    [SSZipArchive unzipFileAtPath:zipPath toDestination:document progressHandler:^(NSString * _Nonnull entry, unz_file_info zipInfo, long entryNumber, long total) {
        NSLog(@"%@",entry);
        NSLog(@"entryNumber:%ld",entryNumber);
        NSLog(@"total:%ld",total);
    } completionHandler:^(NSString * _Nonnull path, BOOL succeeded, NSError * _Nullable error) {
        NSLog(@"解压成功！");
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.loadingView hideAnimated:YES];
            [self createWKWebView];
        });
    }];
}

// 加载webView
-(void)createWKWebView{

    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    config.allowsPictureInPictureMediaPlayback = YES;
    _webView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT) configuration:config];
    [self.view addSubview:_webView];
    _webView.allowsBackForwardNavigationGestures = YES;
    NSString* document = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask,YES) firstObject];
     NSString *path2 = [document stringByAppendingString:@"/myHtmlSource-master"];
    NSString* htmlPath = [path2 stringByAppendingString:@"/JStoOC.html"];
    //加载本地html文件
    [_webView loadFileURL:[NSURL fileURLWithPath:htmlPath] allowingReadAccessToURL:[NSURL fileURLWithPath:path2]];
}

// 加载loadingView
-(void)createLoadingView{
   self.loadingView =  [MBProgressHUD showHUDAddedTo:self.view animated:YES];
}


@end
