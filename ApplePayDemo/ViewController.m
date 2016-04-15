//
//  ViewController.m
//  ApplePayDemo
//
//  Created by mac on 16/2/22.
//  Copyright © 2016年 汤威. All rights reserved.
//

#import "ViewController.h"
#import <PassKit/PassKit.h>
#import <AddressBook/AddressBook.h>
@interface ViewController ()<PKPaymentAuthorizationViewControllerDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller
                       didAuthorizePayment:(PKPayment *)payment
                                completion:(void (^)(PKPaymentAuthorizationStatus status))completion
{
    // 授权支付回调
    // do an async call to the server to complete the payment.
    // See PKPayment class reference for object parameters that can be passed
    BOOL asyncSuccessful = FALSE;
    
    if(asyncSuccessful) {
        completion(PKPaymentAuthorizationStatusSuccess);
        
        NSLog(@"Payment was successful");
        
    } else {
        completion(PKPaymentAuthorizationStatusFailure);
        
        NSLog(@"Payment was unsuccessful");
    }
    
}

- (void)paymentAuthorizationViewControllerDidFinish:(PKPaymentAuthorizationViewController *)controller
{
    NSLog(@"Finishing payment view controller");
    
    [controller dismissViewControllerAnimated:TRUE completion:nil];
}

// 上面的代码早就有人写好，但是实际操作起来用户的一些信息其实服务器已经有了，直接将这些数据设置上去，就不用用户重新填写自己的订单地址了。
- (IBAction)checkPay:(id)sender
{
    // [Crittercism beginTransaction:@"checkout"];
    
    if([PKPaymentAuthorizationViewController canMakePayments]) {
        
        
        PKPaymentRequest *request = [[PKPaymentRequest alloc] init];
        
        PKPaymentSummaryItem *widget1 = [PKPaymentSummaryItem summaryItemWithLabel:@"显示1"
                                                                            amount:[NSDecimalNumber decimalNumberWithString:@"0.99"]];
        
        PKPaymentSummaryItem *widget2 = [PKPaymentSummaryItem summaryItemWithLabel:@"显示2"
                                                                            amount:[NSDecimalNumber decimalNumberWithString:@"1.00"]];
        
        PKPaymentSummaryItem *total = [PKPaymentSummaryItem summaryItemWithLabel:@"显示3"
                                                                          amount:[NSDecimalNumber decimalNumberWithString:@"1.99"]];
        
        request.paymentSummaryItems = @[widget1, widget2, total];
        request.countryCode = @"US"; // 货币单位
        request.currencyCode = @"USD";
        request.supportedNetworks = @[PKPaymentNetworkAmex, PKPaymentNetworkMasterCard, PKPaymentNetworkVisa];
        request.merchantIdentifier = @"此处填写的是添加applePay的生成文件名";
        request.merchantCapabilities = PKMerchantCapabilityEMV | PKMerchantCapability3DS;// 支付卡的类型，分信用卡，借记卡等
        
        request.requiredBillingAddressFields = PKAddressFieldEmail | PKAddressFieldPostalAddress; // 账单邮寄地址选邮箱或者实际地址
        request.requiredShippingAddressFields = PKAddressFieldPostalAddress | PKAddressFieldPhone;// 这个是送货地址
        
        ABRecordRef record = ABPersonCreate();
        CFErrorRef error;
        BOOL success;
        success = ABRecordSetValue(record, kABPersonFirstNameProperty, @"自己的名字", &error);
        if (!success) { /* ... handle error ... */ }
        success = ABRecordSetValue(record, kABPersonLastNameProperty, @"自己的名字", &error); // 加上会多显示一次自己名字
        if (!success) { /* ... handle error ... */ }
        ABMultiValueRef shippingAddress = ABMultiValueCreateMutable(kABMultiDictionaryPropertyType);
        NSDictionary *addressDictionary = @{
                                            (NSString *) kABPersonAddressStreetKey: @"自己的地址",
                                            (NSString *) kABPersonAddressCityKey: @"城市名",
                                            (NSString *) kABPersonAddressStateKey: @"城市名缩写",
                                            (NSString *) kABPersonAddressZIPKey: @"城市地区邮编"
                                            };
        ABMultiValueAddValueAndLabel(shippingAddress,
                                     (__bridge CFDictionaryRef) addressDictionary,
                                     kABOtherLabel,
                                     nil);
        success = ABRecordSetValue(record, kABPersonAddressProperty, shippingAddress, &error);
        
        request.shippingAddress = record;
        request.billingAddress = record; // 为了简便，账单地址和送货地址都填写的一样。
        
        CFRelease(shippingAddress);
        CFRelease(record);
        request.currencyCode = @"USD"; // 这个是设置全球交易的币种，USD代表美元。默认是美元。
        
        // 下面添加送货联系人
        PKContact *contact = [[PKContact alloc] init];
        NSPersonNameComponents *name = [[NSPersonNameComponents alloc] init];
        name.givenName = @"曾经用名";
        contact.name = name;
        contact.phoneNumber = [CNPhoneNumber phoneNumberWithStringValue:@"个人电话号码"];
        contact.supplementarySubLocality = @"1";
        contact.postalAddress = [[CNPostalAddress alloc] init];
        contact.emailAddress = @"个人邮箱号";
        request.shippingContact = contact;
        
        PKPaymentAuthorizationViewController *paymentPane = [[PKPaymentAuthorizationViewController alloc] initWithPaymentRequest:request];
        paymentPane.delegate = self;
        
        if (paymentPane) {
            [self presentViewController:paymentPane animated:TRUE completion:nil];
        }
        
    } else {
        NSLog(@"This device cannot make payments");
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
