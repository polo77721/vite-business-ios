// Objective-C API for talking to github.com/vitelabs/go-vite/mobile/ioscrypto Go package.
//   gobind -lang=objc github.com/vitelabs/go-vite/mobile/ioscrypto
//
// File is generated by gobind. Do not edit.

#ifndef __Ioscrypto_H__
#define __Ioscrypto_H__

@import Foundation;
#include "Universe.objc.h"


@class IoscryptoEd25519KeyPair;
@class IoscryptoSignDataResult;

@interface IoscryptoEd25519KeyPair : NSObject <goSeqRefInterface> {
}
@property(strong, readonly) id _ref;

- (instancetype)initWithRef:(id)ref;
- (instancetype)init;
- (NSData*)publicKey;
- (void)setPublicKey:(NSData*)v;
- (NSData*)privateKey;
- (void)setPrivateKey:(NSData*)v;
@end

@interface IoscryptoSignDataResult : NSObject <goSeqRefInterface> {
}
@property(strong, readonly) id _ref;

- (instancetype)initWithRef:(id)ref;
- (instancetype)init;
- (NSData*)publicKey;
- (void)setPublicKey:(NSData*)v;
- (NSData*)message;
- (void)setMessage:(NSData*)v;
- (NSData*)signature;
- (void)setSignature:(NSData*)v;
@end

FOUNDATION_EXPORT NSData* IoscryptoAesCTRXOR(NSData* key, NSData* inText, NSData* iv, NSError** error);

FOUNDATION_EXPORT NSData* IoscryptoEd25519PrivToCurve25519(NSData* ed25519Priv);

FOUNDATION_EXPORT NSData* IoscryptoEd25519PubToCurve25519(NSData* ed25519Pub);

FOUNDATION_EXPORT IoscryptoEd25519KeyPair* IoscryptoGenerateEd25519KeyPair(NSData* seed, NSError** error);

FOUNDATION_EXPORT NSData* IoscryptoHash(long size, NSData* data);

FOUNDATION_EXPORT NSData* IoscryptoHash256(NSData* data);

FOUNDATION_EXPORT IoscryptoSignDataResult* IoscryptoSignData(NSData* priv, NSData* message);

FOUNDATION_EXPORT BOOL IoscryptoVerifySignature(NSData* pub, NSData* message, NSData* signData, BOOL* ret0_, NSError** error);

FOUNDATION_EXPORT NSData* IoscryptoX25519ComputeSecret(NSData* private, NSData* peersPublic, NSError** error);

#endif
