#import <Cordova/CDV.h>


@interface CBLite : CDVPlugin


//UTIL
- (void)changesDatabase:(CDVInvokedUrlCommand*)urlCommand;
- (void)changesReplication:(CDVInvokedUrlCommand*)urlCommand;
- (void)compact:(CDVInvokedUrlCommand*)urlCommand;
- (void)info:(CDVInvokedUrlCommand*)urlCommand;
- (void)initDb:(CDVInvokedUrlCommand*)urlCommand;
- (void)lastSequence:(CDVInvokedUrlCommand*)urlCommand;
- (void)replicateFrom:(CDVInvokedUrlCommand*)urlCommand;
- (void)replicateTo:(CDVInvokedUrlCommand*)urlCommand;
- (void)reset:(CDVInvokedUrlCommand*)urlCommand;
- (void)stopReplication:(CDVInvokedUrlCommand*)urlCommand;
- (void)sync:(CDVInvokedUrlCommand*)urlCommand;
- (void)resetCallbacks:(CDVInvokedUrlCommand*)urlCommand;

//READ
- (void)allDocs:(CDVInvokedUrlCommand*)urlCommand;
- (void)get:(CDVInvokedUrlCommand*)urlCommand;
- (void)getDocRev:(CDVInvokedUrlCommand*)urlCommand;

//WRITE
- (void)putAttachment:(CDVInvokedUrlCommand*)urlCommand;
- (void)upsert:(CDVInvokedUrlCommand*)urlCommand;

- (void)uploadLogs:(CDVInvokedUrlCommand*)urlCommand;
- (void)attachmentCount:(CDVInvokedUrlCommand*)urlCommand;
@end
