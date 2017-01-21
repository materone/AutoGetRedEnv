//
//  autoGetRedEnv.m
//  autoGetRedEnv
//
//  Created by East on 16/3/21.
//  Copyright (c) 2016年 __MyCompanyName__. All rights reserved.
//

#import "CaptainHook.h"
#import <UIKit/UIKit.h>

/**
 *  插件功能
 */
static int const kCloseRedEnvPlugin = 0;
static int const kOpenRedEnvPlugin = 1;
static int const kCloseRedEnvPluginForMyself = 2;
static int const kCloseRedEnvPluginForMyselfFromChatroom = 3;

//0：关闭红包插件
//1：打开红包插件
//2: 不抢自己的红包
//3: 不抢群里自己发的红包
static int HBPluginType = 1;
//Delay ms
static int HBDelay = 2000;
static NSMutableDictionary *perDict = [NSMutableDictionary dictionary];

#define SAVESETTINGS(dict) { \
NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES); \
NSString *docDir = [paths objectAtIndex:0]; \
if (!docDir){ return;} \
NSString *path = [docDir stringByAppendingPathComponent:@"HBPluginSettings.txt"]; \
[dict writeToFile:path atomically:YES]; \
}

//#define LOADSETTINGS(dict) { \
//NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES); \
//NSString *docDir = [paths objectAtIndex:0]; \
//if (!docDir){ return} \
//NSString *path = [docDir stringByAppendingPathComponent:@"HBPluginSettings.txt"]; \
//dict = [[NSMutableDictionary alloc] initWithContentsOfFile:path]; \
//}

CHDeclareClass(CMessageMgr);

CHMethod(2, void, CMessageMgr, AsyncOnAddMsg, id, arg1, MsgWrap, id, arg2)
{
    CHSuper(2, CMessageMgr, AsyncOnAddMsg, arg1, MsgWrap, arg2);
    Ivar uiMessageTypeIvar = class_getInstanceVariable(objc_getClass("CMessageWrap"), "m_uiMessageType");
    ptrdiff_t offset = ivar_getOffset(uiMessageTypeIvar);
    unsigned char *stuffBytes = (unsigned char *)(__bridge void *)arg2;
    NSUInteger m_uiMessageType = * ((NSUInteger *)(stuffBytes + offset));
    
    Ivar nsFromUsrIvar = class_getInstanceVariable(objc_getClass("CMessageWrap"), "m_nsFromUsr");
    id m_nsFromUsr = object_getIvar(arg2, nsFromUsrIvar);
    
    Ivar nsContentIvar = class_getInstanceVariable(objc_getClass("CMessageWrap"), "m_nsContent");
    id m_nsContent = object_getIvar(arg2, nsContentIvar);
    
    switch(m_uiMessageType) {
        case 1:
        {
            //普通消息
            //红包插件功能
            //0：关闭红包插件 
            //1：打开红包插件
            //2: 不抢自己的红包
            //3: 不抢群里自己发的红包
            //微信的服务中心
            Method methodMMServiceCenter = class_getClassMethod(objc_getClass("MMServiceCenter"), @selector(defaultCenter));
            IMP impMMSC = method_getImplementation(methodMMServiceCenter);
            id MMServiceCenter = impMMSC(objc_getClass("MMServiceCenter"), @selector(defaultCenter));
            //通讯录管理器
            id contactManager = ((id (*)(id, SEL, Class))objc_msgSend)(MMServiceCenter, @selector(getService:),objc_getClass("CContactMgr"));
            id selfContact = objc_msgSend(contactManager, @selector(getSelfContact));
            
            Ivar nsUsrNameIvar = class_getInstanceVariable([selfContact class], "m_nsUsrName");
            id m_nsUsrName = object_getIvar(selfContact, nsUsrNameIvar);
            BOOL isMesasgeFromMe = NO;
            if ([m_nsFromUsr isEqualToString:m_nsUsrName]) {
                //发给自己的消息
                isMesasgeFromMe = YES;
            }
            
            if (isMesasgeFromMe)
            {
                NSRange r;
                bool flag = true;
                if ([m_nsContent rangeOfString:@"打开红包插件"].location != NSNotFound || [m_nsContent rangeOfString:@"on"].location != NSNotFound)
                {
                    HBPluginType = kOpenRedEnvPlugin;
                }
                else if ([m_nsContent rangeOfString:@"关闭红包插件"].location != NSNotFound || [m_nsContent rangeOfString:@"off"].location != NSNotFound)
                {
                    HBPluginType = kCloseRedEnvPlugin;
                }
                else if ([m_nsContent rangeOfString:@"关闭抢自己红包"].location != NSNotFound || [m_nsContent rangeOfString:@"offself"].location != NSNotFound)
                {
                    HBPluginType = kCloseRedEnvPluginForMyself;
                }
                else if ([m_nsContent rangeOfString:@"打开抢自己红包"].location != NSNotFound || [m_nsContent rangeOfString:@"onself"].location != NSNotFound)
                {
                    HBPluginType = kCloseRedEnvPluginForMyselfFromChatroom;
                }
                else {
                    r = [m_nsContent rangeOfString:@"delay"] ;
                    if (r.location != NSNotFound) {
                        NSString *d = [m_nsContent substringFromIndex:(r.location + r.length)];
                        HBDelay = [d intValue];
                        CHLogSource(@"HBDelay is %d",HBDelay);
                        NSLog(@"HBDelay is %d",HBDelay);
                    }else{
                        flag = false;
                    }
                }
                //update pref file
                if (flag) {
                    [perDict setValue:[NSNumber numberWithInt:HBPluginType] forKey:@"HBPluginType"];
                    [perDict setValue:[NSNumber numberWithInt:HBDelay] forKey:@"HBDelay"];
                    SAVESETTINGS(perDict);
                }
            }
        }
            break;
        case 49: {
            // 49=红包
            
            //微信的服务中心
            Method methodMMServiceCenter = class_getClassMethod(objc_getClass("MMServiceCenter"), @selector(defaultCenter));
            IMP impMMSC = method_getImplementation(methodMMServiceCenter);
            id MMServiceCenter = impMMSC(objc_getClass("MMServiceCenter"), @selector(defaultCenter));
            //红包控制器
            id logicMgr = ((id (*)(id, SEL, Class))objc_msgSend)(MMServiceCenter, @selector(getService:),objc_getClass("WCRedEnvelopesLogicMgr"));
            //通讯录管理器
            id contactManager = ((id (*)(id, SEL, Class))objc_msgSend)(MMServiceCenter, @selector(getService:),objc_getClass("CContactMgr"));
            
            Method methodGetSelfContact = class_getInstanceMethod(objc_getClass("CContactMgr"), @selector(getSelfContact));
            IMP impGS = method_getImplementation(methodGetSelfContact);
            id selfContact = impGS(contactManager, @selector(getSelfContact));
            
            Ivar nsUsrNameIvar = class_getInstanceVariable([selfContact class], "m_nsUsrName");
            id m_nsUsrName = object_getIvar(selfContact, nsUsrNameIvar);
            BOOL isMesasgeFromMe = NO;
            BOOL isChatroom = NO;
            if ([m_nsFromUsr isEqualToString:m_nsUsrName]) {
                isMesasgeFromMe = YES;
            }
            if ([m_nsFromUsr rangeOfString:@"@chatroom"].location != NSNotFound)
            {
                isChatroom = YES;
            }
            if (isMesasgeFromMe && kCloseRedEnvPluginForMyself == HBPluginType && !isChatroom) {
                //不抢自己的红包
                break;
            }
            else if(isMesasgeFromMe && kCloseRedEnvPluginForMyselfFromChatroom == HBPluginType && isChatroom)
            {
                //不抢群里自己的红包
                break;
            }
            if ([m_nsContent rangeOfString:@"wxpay://"].location != NSNotFound)
            {
                NSString *nativeUrl = m_nsContent;
                NSRange rangeStart = [m_nsContent rangeOfString:@"wxpay://c2cbizmessagehandler/hongbao"];
                if (rangeStart.location != NSNotFound)
                {
                    NSUInteger locationStart = rangeStart.location;
                    nativeUrl = [nativeUrl substringFromIndex:locationStart];
                }
                
                NSRange rangeEnd = [nativeUrl rangeOfString:@"]]"];
                if (rangeEnd.location != NSNotFound)
                {
                    NSUInteger locationEnd = rangeEnd.location;
                    nativeUrl = [nativeUrl substringToIndex:locationEnd];
                }
                
                NSString *naUrl = [nativeUrl substringFromIndex:[@"wxpay://c2cbizmessagehandler/hongbao/receivehongbao?" length]];
                
                NSArray *parameterPairs =[naUrl componentsSeparatedByString:@"&"];
                
                NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithCapacity:[parameterPairs count]];
                for (NSString *currentPair in parameterPairs) {
                    NSRange range = [currentPair rangeOfString:@"="];
                    if(range.location == NSNotFound)
                        continue;
                    NSString *key = [currentPair substringToIndex:range.location];
                    NSString *value =[currentPair substringFromIndex:range.location + 1];
                    [parameters setObject:value forKey:key];
                }
                
                //红包参数
                NSMutableDictionary *params = [@{} mutableCopy];
                
                [params setObject:parameters[@"msgtype"]?:@"null" forKey:@"msgType"];
                [params setObject:parameters[@"sendid"]?:@"null" forKey:@"sendId"];
                [params setObject:parameters[@"channelid"]?:@"null" forKey:@"channelId"];
                
                id getContactDisplayName = objc_msgSend(selfContact, @selector(getContactDisplayName));
                id m_nsHeadImgUrl = objc_msgSend(selfContact, @selector(m_nsHeadImgUrl));
                
                [params setObject:getContactDisplayName forKey:@"nickName"];
                [params setObject:m_nsHeadImgUrl forKey:@"headImg"];
                [params setObject:[NSString stringWithFormat:@"%@", nativeUrl]?:@"null" forKey:@"nativeUrl"];
                [params setObject:m_nsFromUsr?:@"null" forKey:@"sessionUserName"];
                
                if (kCloseRedEnvPlugin != HBPluginType) {
                    //delay HBDelay ms
                    //slow the click
                    Ivar nsCreateTimeIvar = class_getInstanceVariable(objc_getClass("CMessageWrap"), "m_uiCreateTime");
                    id m_nsCreateTimeIvar = object_getIvar(arg2, nsCreateTimeIvar);
                    NSUInteger ctime = (NSInteger)m_nsCreateTimeIvar;
                    NSDate *now = [NSDate date];
                    NSUInteger interval = round([now timeIntervalSince1970]);
                    //如果红包发放时间小于10s，就暂停设定的时间
                    NSString *s = [NSString stringWithFormat:@"Ctime:%lu == Inter:%lu",(unsigned long)ctime,(unsigned long)interval];
                    UIAlertView * alert = [[UIAlertView alloc]initWithTitle:@"Param of HB" message:s delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
                    NSLog(@"HongBAO %@",s);
                    [alert show];
                    if((interval - ctime) < 10){
                        // 创建队列，异步等待延时后执行
                        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
                        
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(HBDelay * NSEC_PER_MSEC)), queue, ^{
                            // HBDelay 毫秒后需要执行的任务
                            CHLogSource(@" %lu hbtime, %lu now",(unsigned long)ctime,(unsigned long)interval);
                            //自动抢红包
                            ((void (*)(id, SEL, NSMutableDictionary*))objc_msgSend)(logicMgr, @selector(OpenRedEnvelopesRequest:), params);
                        });
                    }else{//大于10s，直接开抢
                        ((void (*)(id, SEL, NSMutableDictionary*))objc_msgSend)(logicMgr, @selector(OpenRedEnvelopesRequest:), params);
                    }
                    [alert release];
                    [s release];
                }
                return;
            }
            
            break;
        }
        default:
            break;
    }
}

__attribute__((constructor)) static void entry()
{
    CHLoadLateClass(CMessageMgr);
    CHClassHook(2, CMessageMgr, AsyncOnAddMsg, MsgWrap);
    //load pref
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDir = [paths objectAtIndex:0];
    if (!docDir){ return;};
    NSString *path = [docDir stringByAppendingPathComponent:@"HBPluginSettings.txt"];
    perDict = [[NSMutableDictionary alloc] initWithContentsOfFile:path];
    if (!perDict){ return;};
    id val = [perDict valueForKey:@"HBPluginType"];
    if(val != NULL) HBPluginType = [val intValue];
    val = [perDict valueForKey:@"HBDelay"];
    if(val != NULL) HBDelay = [val intValue];
}