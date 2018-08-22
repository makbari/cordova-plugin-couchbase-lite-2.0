#import "CBLite.h"

#import "CouchbaseLite.h"
#import "CBLDatabase.h"

#import "CBLReplicator.h"
#import <Cordova/CDV.h>

@implementation CBLite

static NSMutableDictionary *dbs;
static NSMutableDictionary *replications;
static NSMutableArray *callbacks;


static NSThread *cblThread;

#pragma mark UTIL
- (void)changesDatabase:(CDVInvokedUrlCommand *)urlCommand {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_NO_RESULT];
        [pluginResult setKeepCallbackAsBool:YES];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];

        [callbacks addObject:urlCommand.callbackId];

        dispatch_cbl_async(cblThread, ^{
            NSString* dbName = [urlCommand.arguments objectAtIndex:0];
             CBLDatabase *db = dbs[dbName];
            [db addChangeListener:^(CBLDatabaseChange *change ) {
                 NSLog(@"Replication changessssssssss %@", change);



                    CDVPluginResult* pluginResult =
                    [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                      messageAsString:[[NSString alloc] initWithData: [NSJSONSerialization dataWithJSONObject:change.documentIDs
                                                                                                                                    options:0 //or NSJSONWritingPrettyPrinted
                                                                                                                                     error:nil] encoding:NSUTF8StringEncoding]];
                    [pluginResult setKeepCallbackAsBool:YES];
                    [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
            }];

        });
}

- (void)changesReplication:(CDVInvokedUrlCommand *)urlCommand {
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_NO_RESULT];
    [pluginResult setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];

    [callbacks addObject:urlCommand.callbackId];

    dispatch_cbl_async(cblThread, ^{


        NSString* dbName = [urlCommand.arguments objectAtIndex:0];
        for (NSString *r in replications) {
            [replications[r] addChangeListener:^(CBLReplicatorChange *change) {
                NSString *response;
                if (change.status.activity == kCBLReplicatorStopped) {
                    NSLog(@"Replication stopped");
                    response = [CBLite jsonSyncStatus:@"REPLICATION_STOPPED" withDb:dbName withType:r progressTotal:change.status.progress.total progressCompleted:change.status.progress.completed];
                } else if (change.status.activity == kCBLReplicatorOffline) {
                    NSLog(@"Replication Offline");
                    response = [CBLite jsonSyncStatus:@"REPLICATION_OFFLINE" withDb:dbName withType:r progressTotal:change.status.progress.total progressCompleted:change.status.progress.completed];
                } else if (change.status.activity == kCBLReplicatorConnecting) {
                    NSLog(@"Replication Connecting");
                    response = [CBLite jsonSyncStatus:@"REPLICATION_CONNECTING" withDb:dbName withType:r progressTotal:change.status.progress.total progressCompleted:change.status.progress.completed];
                } else if (change.status.activity == kCBLReplicatorIdle) {
                    NSLog(@"Replication kCBLReplicatorIdle");
                    response = [CBLite jsonSyncStatus:@"REPLICATION_IDLE" withDb:dbName withType:r progressTotal:change.status.progress.total progressCompleted:change.status.progress.completed];
                } else if (change.status.activity == kCBLReplicatorBusy) {
                    NSLog( @"%@", [NSString stringWithFormat:@"Replication Busy Reolication %llu di %llu",change.status.progress.completed,change.status.progress.total]);
                    response = [CBLite jsonSyncStatus:@"REPLICATION_ACTIVE" withDb:dbName withType:r progressTotal:change.status.progress.total progressCompleted:change.status.progress.completed];
                }

                CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:response];
                [pluginResult setKeepCallbackAsBool:YES];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];


            }];

        }
        //        [[NSNotificationCenter defaultCenter]
        //         addObserverForName:kCBLReplicationChangeNotification
        //         object:replications[[NSString stringWithFormat:@"%@%@", dbName, @"_push"]]
        //         queue:nil
        //         usingBlock:^(NSNotification *n) {
        //             CBLReplication *push = replications[[NSString stringWithFormat:@"%@%@", dbName, @"_push"]];
        //             NSString *response;
        //             BOOL active = (push.status == kCBLReplicationActive);
        //             if(active) response = [CBLite jsonSyncStatus:@"REPLICATION_ACTIVE" withDb:dbName withType:@"push"];
        //             else response = [CBLite jsonSyncStatus:@"REPLICATION_IDLE" withDb:dbName withType:@"push"];
        //
        //             NSError *error = push.lastError ? push.lastError : nil;
        //             if(error != nil){
        //                 if(error.code == 401) response = [CBLite jsonSyncStatus:@"REPLICATION_UNAUTHORIZED" withDb:dbName withType:@"error_push"];
        //                 if(error.code == 404) response = [CBLite jsonSyncStatus:@"REPLICATION_NOT_FOUND" withDb:dbName withType:@"error_push"];
        //             }
        //             CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:response];
        //             [pluginResult setKeepCallbackAsBool:YES];
        //             [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
        //        }];
        //
        //        [[NSNotificationCenter defaultCenter]
        //         addObserverForName:kCBLReplicationChangeNotification
        //         object:replications[[NSString stringWithFormat:@"%@%@", dbName, @"_pull"]]
        //         queue:nil
        //         usingBlock:^(NSNotification *n) {
        //             CBLReplication *pull = replications[[NSString stringWithFormat:@"%@%@", dbName, @"_pull"]];
        //             NSString *response;
        //             BOOL active = (pull.status == kCBLReplicationActive);
        //             if(active) response = [CBLite jsonSyncStatus:@"REPLICATION_ACTIVE" withDb:dbName withType:@"pull"];
        //             else response = [CBLite jsonSyncStatus:@"REPLICATION_IDLE" withDb:dbName withType:@"pull"];
        //
        //             NSError *error = pull.lastError ? pull.lastError : nil;
        //             if(error != nil){
        //                 if(error.code == 401) response = [CBLite jsonSyncStatus:@"REPLICATION_UNAUTHORIZED" withDb:dbName withType:@"error_pull"];
        //                 if(error.code == 404) response = [CBLite jsonSyncStatus:@"REPLICATION_NOT_FOUND" withDb:dbName withType:@"error_pull"];
        //             }
        //             CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:response];
        //             [pluginResult setKeepCallbackAsBool:YES];
        //             [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
        //         }];
    });
}

+ (NSString *) jsonSyncStatus:(NSString *)status withDb:(NSString *)db withType:(NSString *)type progressTotal: (uint64_t)total progressCompleted: (uint64_t )completed {
    return [NSString stringWithFormat:@"{\"db\":\"%@\",\"type\": \"%@\", \"total\": \"%llu\", \"completed\": \"%llu\" ,\"message\":\"%@\" }",db, type, total, completed, status ];
}


- (void)compact:(CDVInvokedUrlCommand *)urlCommand {
    dispatch_cbl_async(cblThread, ^{
        NSString* dbName = [urlCommand.arguments objectAtIndex:0];
        CBLDatabase *db = dbs[dbName];
        NSError * _Nullable __autoreleasing * error2 = NULL;
        [db compact:error2];
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"compact complete"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
    });
}

- (void)info:(CDVInvokedUrlCommand *)urlCommand {
    //    dispatch_cbl_async(cblThread, ^{
    //        NSString* dbName = [urlCommand.arguments objectAtIndex:0];
    //        CBLDatabase *db = dbs[dbName];
    //        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsNSUInteger:db.documentCount];
    //        [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
    //    });
}

- (void)initDb:(CDVInvokedUrlCommand *)urlCommand {
    dispatch_cbl_async(cblThread, ^{
        NSString* dbName = [urlCommand.arguments objectAtIndex:0];
        NSArray* index =[[NSArray alloc] init];
        if([urlCommand.arguments count]>1){
        index =[urlCommand.arguments objectAtIndex:1];
        }
        NSError *error;
        if(dbs == nil){dbs = [NSMutableDictionary dictionary];}


        
        CBLDatabase* db=[[CBLDatabase alloc] initWithName:dbName error:&error];
        dbs[dbName] =db;
        if([index count]>0){
            for (NSDictionary* ind in index) {
                NSMutableArray* arrField=[[NSMutableArray alloc]init];
                for(NSString* field in [ind valueForKey:@"fileds"]){
                    [arrField addObject: [CBLValueIndexItem property:field]];
                }
                CBLIndex* index = [CBLIndexBuilder valueIndexWithItems:arrField];
                [db createIndex:index withName:[ind valueForKey:@"name"] error:&error];
            }
            
            
        }
        
        
        CDVPluginResult* pluginResult;
        if (!dbs[dbName]) pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Could not init DB"];
        else pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"CBL db init success"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
    });
}

- (void)lastSequence:(CDVInvokedUrlCommand *)urlCommand {
    NSString* dbName = [urlCommand.arguments objectAtIndex:0];
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsNSUInteger:[dbs[dbName] sequence]];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];

}


- (void)reset:(CDVInvokedUrlCommand *)urlCommand {
    [self onReset];
}

- (void)stopReplication:(CDVInvokedUrlCommand*)urlCommand {
    dispatch_cbl_async(cblThread, ^{
        for (NSString *r in replications) {
            CBLReplicator * repl = replications[r];
            [repl stop];
        }
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"all replications stopped"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
    });
}

- (void)deleteDatabase:(CDVInvokedUrlCommand*)urlCommand {
    dispatch_cbl_async(cblThread, ^{
        NSString* dbName = [urlCommand.arguments objectAtIndex:0];
        NSError *error;
        CDVPluginResult* pluginResult;
        if (!dbs[dbName]){
            
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"DB not started"];
        }else{
            CBLDatabase* db=dbs[dbName];
            [db delete:&error];
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"CBL db delete success"];
            
        }
        [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
    });
}



- (void)sync:(CDVInvokedUrlCommand *)urlCommand {
    dispatch_cbl_async(cblThread, ^{
        NSString* dbName = [urlCommand.arguments objectAtIndex:0];
        NSString* syncURL = [urlCommand.arguments objectAtIndex:1];
        NSString* user = [urlCommand.arguments objectAtIndex:2];
        NSString* pass = [urlCommand.arguments objectAtIndex:3];
        NSString* replicationType=@"PushPull";
        if([urlCommand.arguments count]>4){
            replicationType=[urlCommand.arguments objectAtIndex:4];
        }
        NSArray* channlesArray=NULL;
        if([urlCommand.arguments count]>5){
            channlesArray=[urlCommand.arguments objectAtIndex:5];
        }
        

        if(replications == nil){replications = [NSMutableDictionary dictionary];}

        if(replications[[NSString stringWithFormat:@"%@%@", dbName, replicationType]] != nil){ [replications[[NSString stringWithFormat:@"%@%@", dbName, replicationType]] stop]; }
        //        if(replications[[NSString stringWithFormat:@"%@%@", dbName, @"_pull"]] != nil){ [replications[[NSString stringWithFormat:@"%@%@", dbName, @"_pull"]] stop]; }
        //
        //        CBLReplication *push = [dbs[dbName] createPushReplication: [NSURL URLWithString: syncURL]];
        //        CBLReplication *pull = [dbs[dbName] createPullReplication:[NSURL URLWithString: syncURL]];
        //
        //        push.continuous = pull.continuous = YES;
        //
        //        id<CBLAuthenticator> auth;
        //        auth = [CBLAuthenticator basicAuthenticatorWithName: user
        //                                                   password: pass];
        //        push.authenticator = pull.authenticator = auth;
        //
        //        [push start]; [pull start];
        NSURL *url = [NSURL URLWithString:syncURL];
        CBLURLEndpoint *target = [[CBLURLEndpoint alloc] initWithURL: url];
        CBLReplicatorConfiguration *config = [[CBLReplicatorConfiguration alloc] initWithDatabase:dbs[dbName]
                                                                                           target:target];
        
        if([replicationType isEqualToString:@"PushPull"]){
            config.replicatorType = kCBLReplicatorTypePushAndPull;
        }else if([replicationType isEqualToString:@"Push"]){
            config.replicatorType = kCBLReplicatorTypePush;
        }else if([replicationType isEqualToString:@"Pull"]){
            config.replicatorType = kCBLReplicatorTypePull;
        }
        if(channlesArray!=NULL){
            config.channels=channlesArray;
        }
        
        config.continuous = true;
        
        config.authenticator = [[CBLBasicAuthenticator alloc] initWithUsername:user password:pass];
        CBLReplicator *replicator = [[CBLReplicator alloc] initWithConfig:config];
        [replicator start];
        replications[[NSString stringWithFormat:@"%@%@", dbName, replicationType]] = replicator;
        //        replications[[NSString stringWithFormat:@"%@%@", dbName, @"_pull"]] = pull;
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"native sync started"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
    });
}

#pragma mark READ
- (void)allDocs:(CDVInvokedUrlCommand *)urlCommand {
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_NO_RESULT];
    [pluginResult setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
    dispatch_cbl_async(cblThread, ^{
        NSString* dbName = [urlCommand.arguments objectAtIndex:0];
        int batchSize = 5000;
        CBLQuery* idQuery = [CBLQueryBuilder select:@[[CBLQuerySelectResult all]]
                                               from:[CBLQueryDataSource database:dbs[dbName]]
                             ];

        NSError *idQueryError;
        NSMutableArray *allIds = [NSMutableArray array];
        CBLQueryResultSet *result = [idQuery execute:&idQueryError];
        for (CBLQueryRow* row in result) {
            @autoreleasepool {
                [allIds addObject:[row valueForKey:dbName]];
            }
        }

        NSMutableArray *idBatches = [NSMutableArray array];
        NSUInteger remainingIds = [allIds count];
        int j = 0;

        while(remainingIds){
            @autoreleasepool {
                NSRange batchRange = NSMakeRange(j, MIN(batchSize, remainingIds));
                NSArray *batch = [allIds subarrayWithRange: batchRange];
                [idBatches addObject:batch];
                remainingIds -= batchRange.length;
                j += batchRange.length;
            }
        }

        for(NSArray *batch in idBatches){
            @autoreleasepool{
                [self processAllDocsBatch:batch withUrlCommand:urlCommand onDatabase:dbName];
            }
        }

        CDVPluginResult* finalPluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"complete"];
        [finalPluginResult setKeepCallbackAsBool:NO];
        [self.commandDelegate sendPluginResult:finalPluginResult callbackId:urlCommand.callbackId];
    });
}
//
- (void) processAllDocsBatch:(NSArray *) batch withUrlCommand:(CDVInvokedUrlCommand *) urlCommand onDatabase:(NSString *)dbName {
    dispatch_cbl_async(cblThread, ^{
        @autoreleasepool{
            CBLQuery* batchQuery = [CBLQueryBuilder select:@[[CBLQuerySelectResult all]]
                                                      from:[CBLQueryDataSource database:dbs[dbName]]
                                    ];

            NSError *queryError;
            CBLQueryResultSet *result = [batchQuery execute:&queryError];
            NSMutableArray *responseBuffer = [[NSMutableArray alloc] init];
            for (CBLQueryRow* row in result) {
                NSError *error;
                @try{
                    CBLDictionary *dict = [row valueForKey:dbName];
                    NSData *data = [NSJSONSerialization dataWithJSONObject:[dict toDictionary]
                                                                   options:0 //or NSJSONWritingPrettyPrinted
                                                                     error:&error];
                    [responseBuffer addObject:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
                }
                @catch(NSException *e){
                    NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:
                                          [row valueForKey:@"_id"], @"id",
                                          [row valueForKey:@"_rev"], @"rev",
                                          [error localizedDescription], @"description",
                                          [error localizedFailureReason], @"cause",
                                          nil];
                    NSLog( @"ERROR %@", dict );
                }
            }

            CDVPluginResult* pluginResult =
            [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArrayBuffer:[[NSString stringWithFormat:@"[%@]", [responseBuffer componentsJoinedByString:@","]] dataUsingEncoding:NSUTF8StringEncoding]];
            [pluginResult setKeepCallbackAsBool:YES];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
        }
    });
}




-(CBLQueryExpression *) getQueryFromString: (NSString *)method and: (NSString *)field and: (NSString *)where {
    if([method isEqualToString:@"equalTo"]){
        return [[CBLQueryExpression property:field] equalTo:[CBLQueryExpression string:where]];
    }
    else if ([method isEqualToString:@"notEqualTo"]) {
        return [[CBLQueryExpression property:field] notEqualTo:[CBLQueryExpression string:where]];
    }
    else if ([method isEqualToString:@"contains"]) {
        return [CBLQueryArrayFunction contains:[CBLQueryExpression property:field]
                                         value:[CBLQueryExpression string:where]];
    }

}

// creating query
- (void)query:(CDVInvokedUrlCommand *) urlCommand {

    dispatch_cbl_async(cblThread, ^{
        NSString* dbName = [urlCommand.arguments objectAtIndex:0];

        NSArray *field = [urlCommand.arguments objectAtIndex:1];
        NSString *searchQuery = [urlCommand.arguments objectAtIndex:2];
        NSString *isLocal = [urlCommand.arguments objectAtIndex:3];
        NSError *error;
        if ([isLocal isEqualToString:@"true"]) {

        } else {
            CBLQueryExpression *whereExpression;
            NSArray* selectExpression= @[[CBLQuerySelectResult all]];
            if([field count]>0){
                NSMutableArray* marr=[[NSMutableArray alloc]init];
                [marr addObject:[CBLQuerySelectResult expression:[CBLQueryMeta id]]];
                for (NSString* s in field) {
                    [marr addObject:[CBLQuerySelectResult property:s]];
                }
                selectExpression=[marr copy];
                
            }
            
            
            
            // Generate Where Expression
            NSData* jsonData = [searchQuery dataUsingEncoding:NSUTF8StringEncoding];
            NSError *jsonError;
            NSArray *jsonDataArray = [[NSArray alloc]init];
            jsonDataArray = [NSJSONSerialization JSONObjectWithData:[searchQuery dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:&jsonError];

            NSLog(@"jsonDataArray: %@",jsonDataArray);
                NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:&jsonError];

                if(jsonObject !=nil){
                    if([[jsonObject objectForKey:@"group"] isEqual:@"AND"]){

                        NSMutableArray *array=[jsonObject objectForKey:@"search"];

                        if(array.count>0){
                            whereExpression =[self getQueryFromString:jsonObject[@"search"][0][@"method"] and:jsonObject[@"search"][0][@"field"] and:jsonObject[@"search"][0][@"where"]];
                        }
                        if(array.count>1){
                            for(int z = 1; z<array.count;z++){

                                whereExpression=[whereExpression andExpression:[self getQueryFromString:jsonObject[@"search"][z][@"method"] and:jsonObject[@"search"][z][@"field"] and:jsonObject[@"search"][z][@"where"]]];
                            }

                        }

                    }
                    if([[jsonObject objectForKey:@"group"] isEqual:@"OR"]){

                        NSMutableArray *array=[jsonObject objectForKey:@"search"];

                        if(array.count>0){
                            whereExpression =[self getQueryFromString:jsonObject[@"search"][0][@"method"] and:jsonObject[@"search"][0][@"field"] and:jsonObject[@"search"][0][@"where"]];
                        }
                        if(array.count>1){
                            for(int z = 1; z<array.count;z++){

                                whereExpression=[whereExpression orExpression:[self getQueryFromString:jsonObject[@"search"][z][@"method"] and:jsonObject[@"search"][z][@"field"] and:jsonObject[@"search"][z][@"where"]]];
                            }

                        }

                    }

                }
            //End Generate


            NSMutableArray *responseBuffer = [[NSMutableArray alloc] init];
            //CBLQueryExpression *type = [[CBLQueryExpression property:field] equalTo:[CBLQueryExpression string:searchQuery]];
            CBLQuery *query;
            if(whereExpression!=nil){
            query= [CBLQueryBuilder select:selectExpression
                                                 from:[CBLQueryDataSource database:dbs[dbName]]
                                                where:whereExpression];
            }else{
                query= [CBLQueryBuilder select:selectExpression
                                          from:[CBLQueryDataSource database:dbs[dbName]]];
            }
            
            NSLog(@"query: %@",[query description]);
            NSArray *result = [[query execute:&error] allResults];

            for (CBLQueryRow* row in result) {
                @try{
                    if([field count]==0){
                        CBLDictionary *dict = [row valueForKey:dbName];
                        [responseBuffer addObject:[dict toDictionary]];
                    }else{
                        
                        NSDictionary *dict = [row dictionaryWithValuesForKeys:field];
                        [responseBuffer addObject:dict];
                    }
                }
                @catch(NSException *e){
                    NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:
                                          [row valueForKey:@"_id"], @"id",
                                          [row valueForKey:@"_rev"], @"rev",
                                          [error localizedDescription], @"description",
                                          [error localizedFailureReason], @"cause",
                                          nil];
                    NSLog( @"ERROR %@", dict );
                }
            }
           
           /* [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArrayBuffer:[[NSString stringWithFormat:@"[%@]", [responseBuffer componentsJoinedByString:@","]] dataUsingEncoding:NSUTF8StringEncoding]];*/
            NSData *data = [NSJSONSerialization dataWithJSONObject:responseBuffer
                                                           options:0
                                                             error:&error];
            NSString* response=[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
           CDVPluginResult* pluginResult =  [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArrayBuffer:[response dataUsingEncoding:NSUTF8StringEncoding]];
            
            [pluginResult setKeepCallbackAsBool:YES];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];


        }
    });
}
//
- (void)get:(CDVInvokedUrlCommand *)urlCommand {
    dispatch_cbl_async(cblThread, ^{
        NSString* dbName = [urlCommand.arguments objectAtIndex:0];
        NSString *id = [urlCommand.arguments objectAtIndex:1];
        NSString *isLocal = [urlCommand.arguments objectAtIndex:2];
        NSError *error;
        if([isLocal isEqualToString:@"true"]){
            CBLDocument* doc = [dbs[dbName]  documentWithID: id];
            if(doc != nil){
                @try {
                    CDVPluginResult* pluginResult =
                    [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArrayBuffer:[NSJSONSerialization dataWithJSONObject:doc options:0 error:&error]];
                    [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
                }
                @catch (NSException *exception) {
                    CDVPluginResult* pluginResult =
                    [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArrayBuffer:[@"null" dataUsingEncoding:NSUTF8StringEncoding]];
                    [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
                }
            }
            else {
                CDVPluginResult* pluginResult =
                [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArrayBuffer:[@"null" dataUsingEncoding:NSUTF8StringEncoding]];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
            }
        }
        else {
            CBLDocument* doc = [dbs[dbName]  documentWithID: id];
            if(doc == nil){
                CDVPluginResult* pluginResult =
                [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArrayBuffer:[@"null" dataUsingEncoding:NSUTF8StringEncoding]];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
            }
            @try {
                CDVPluginResult* pluginResult =
                [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArrayBuffer:[NSJSONSerialization dataWithJSONObject:[doc toDictionary] options:0 error:&error]];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
            }
            @catch (NSException *exception) {
                CDVPluginResult* pluginResult =
                [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArrayBuffer:[@"null" dataUsingEncoding:NSUTF8StringEncoding]];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
            }
        }
    });
}

- (void)getDocRev:(CDVInvokedUrlCommand *)urlCommand {
    //    dispatch_cbl_async(cblThread, ^{
    //        NSString* dbName = [urlCommand.arguments objectAtIndex:0];
    //        NSString *id = [urlCommand.arguments objectAtIndex:1];
    //
    //        CBLDocument *doc = [dbs[dbName] existingDocumentWithID: id];
    //        if(doc == nil){
    //            CDVPluginResult* pluginResult =
    //            [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"null"];
    //            [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
    //        }
    //        CDVPluginResult* pluginResult =
    //        [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:doc.currentRevisionID];
    //        [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
    //    });
}

#pragma mark WRITE
- (void)putAttachment:(CDVInvokedUrlCommand *)urlCommand{
    //    dispatch_cbl_async(cblThread, ^{
    //        @autoreleasepool{
    //            NSString* dbName = [urlCommand.arguments objectAtIndex:0];
    //            NSString* docId = [urlCommand.arguments objectAtIndex:1];
    //            NSString* fileName = [urlCommand.arguments objectAtIndex:2];
    //            NSString* name = [urlCommand.arguments objectAtIndex:3];
    //            NSString* mime = [urlCommand.arguments objectAtIndex:4];
    //            NSString* dirName = [urlCommand.arguments objectAtIndex:5];
    //            NSError *error;
    //            CBLDatabase *db = dbs[dbName];
    //            CBLDocument* doc = [db documentWithID: docId];
    //            CBLUnsavedRevision* newRev = [doc.currentRevision createRevision];
    //
    //            NSString *docsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    //            NSString *mediaPath = [NSString stringWithFormat:@"%@/%@", docsPath, dirName];
    //            NSString *filePath = [mediaPath stringByAppendingPathComponent:fileName];
    //
    //            NSData *data = [[NSFileManager defaultManager] contentsAtPath:filePath];
    //
    //            @try{
    //                [newRev setAttachmentNamed: name
    //                           withContentType: mime
    //                                   content: data];
    //                [newRev save: &error];
    //                CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"success"];
    //                [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
    //            }
    //            @catch(NSException *e){
    //                CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"putAttachment failure"];
    //                [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
    //            }
    //        }
    //    });
}

- (void)attachmentCount:(CDVInvokedUrlCommand *) urlCommand {
    //    dispatch_cbl_async(cblThread, ^{
    //        @try{
    //            NSString* dbName = [urlCommand.arguments objectAtIndex:0];
    //            NSString* docId = [urlCommand.arguments objectAtIndex:1];
    //            CBLDocument* doc = [dbs[dbName] documentWithID: docId];
    //            CBLRevision* rev = doc.currentRevision;
    //            NSArray<CBLAttachment *> *attachments = rev.attachments;
    //
    //            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsNSUInteger:attachments.count];
    //            [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
    //        }
    //        @catch(NSException *e){
    //            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:[NSString stringWithFormat:@"attachmentCount Exception: %@, Reason:%@", [e name], [e reason]]];
    //            [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
    //        }
    //    });
}

- (void)uploadLogs:(CDVInvokedUrlCommand *) urlCommand {
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"noop"];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
}

- (void)upsert:(CDVInvokedUrlCommand *)urlCommand {
    dispatch_cbl_async(cblThread, ^{
        NSString* dbName = [urlCommand.arguments objectAtIndex:0];
        NSString* docId = [urlCommand.arguments objectAtIndex:1];
        NSString* jsonString = [urlCommand.arguments objectAtIndex:2];
        NSString* isLocal = [urlCommand.arguments objectAtIndex:3];

        NSStringEncoding  encoding = NSUTF8StringEncoding;
        NSData * jsonData = [jsonString dataUsingEncoding:encoding];
        NSError * error=nil;
        NSMutableDictionary * jsonDictionary = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:&error];

        if([isLocal isEqualToString:@"local"]){
            //            NSError * _Nullable __autoreleasing * error2 = NULL;
            //            [dbs[dbName] putLocalDocument:jsonDictionary withID:docId error: error2];
        }
        else {
            //try to get doc
            CBLMutableDocument* doc = [[dbs[dbName]  documentWithID: docId] toMutable];
            //if exists, force update
            if(doc != nil){
                for (NSString* key in jsonDictionary) {

                    [doc setString:[jsonDictionary objectForKey:key] forKey:key];
                }


                if (![dbs[dbName] saveDocument:doc error:&error]) {
                    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"updated failed"];
                    [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
                }
                else {
                    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"updated document"];
                    [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
                }
            }
            //if doesnt exist, create
            else {
                CBLMutableDocument* newDoc = [[CBLMutableDocument alloc] initWithID:docId data: jsonDictionary] ;

                NSError* error;
                if (![dbs[dbName] saveDocument:newDoc error:&error]) {
                    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"failed to create document"];
                    [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
                }
                else {
                    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"created document"];
                    [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
                }
            }
        }
    });
}

#pragma mark Plugin Boilerplate
- (void)pluginInitialize {
    [self launchCouchbaseLite];
}

- (void)onReset {
    //    dispatch_cbl_async(cblThread, ^{
    //        //cancel any change listeners
    //        [[NSNotificationCenter defaultCenter]
    //         removeObserver:self
    //         name:kCBLDatabaseChangeNotification
    //         object:nil];
    //
    //        //cancel all replications
    //        for (NSString *r in replications) {
    //            CBLReplication * repl = replications[r];
    //            [repl stop];
    //        }
    //
    //        //cancel all callbacks
    //        for (NSString *cbId in callbacks){
    //            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_NO_RESULT];
    //            [pluginResult setKeepCallbackAsBool:NO];
    //            [self.commandDelegate sendPluginResult:pluginResult callbackId:cbId];
    //        }
    //
    //        [callbacks removeAllObjects];
    //        [replications removeAllObjects];
    //        [dbs removeAllObjects];
    //    });
}

- (void)resetCallbacks:(CDVInvokedUrlCommand *)urlCommand {
    //cancel all callbacks
    dispatch_cbl_async(cblThread, ^{
        for (NSString *cbId in callbacks){
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_NO_RESULT];
            [pluginResult setKeepCallbackAsBool:NO];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:cbId];
        }

        [callbacks removeAllObjects];
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"callbacks reset"];
        [pluginResult setKeepCallbackAsBool:NO];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
    });
}

- (void)launchCouchbaseLite {
    cblThread = [[NSThread alloc] initWithTarget: self selector:@selector(cblThreadMain) object:nil];
    [cblThread start];

    dispatch_cbl_async(cblThread, ^{

        if(dbs == nil){dbs = [NSMutableDictionary dictionary];}
        if(replications == nil){replications = [NSMutableDictionary dictionary];}
        if(callbacks == nil){callbacks = [NSMutableArray array];}

    });
}

void dispatch_cbl_async(NSThread* thread, dispatch_block_t block)
{
    if ([NSThread currentThread] == thread){ block(); }
    else{
        block = [block copy];
        [(id)block performSelector: @selector(invoke) onThread: thread withObject: nil waitUntilDone: NO];
    }
}

- (void)cblThreadMain
{
    // You need the NSPort here because a runloop with no sources or ports registered with it
    // will simply exit immediately instead of running forever.
    NSPort* keepAlive = [NSPort port];
    NSRunLoop* runLoop = [NSRunLoop currentRunLoop];
    [keepAlive scheduleInRunLoop: runLoop forMode: NSRunLoopCommonModes];
    [runLoop run];
}

@end

