# UNDER DEVELOPMENT
This repository is originaly fork from [happio/cordova-plugin-couchbase-lite](https://github.com/happieio/cordova-plugin-couchbase-lite) which provides a standard cordova API used for couchbase-mobile version 1.4.1 (also, with small modification, it can be used for couchbase-mobile version 1.5).



With release of couchbase-lite mobile version 2.0, several native classes are updated ([more information](https://developer.couchbase.com/documentation/mobile/current/whatsnew.html)) (It also can be safe to say it is almost rewritten of previous version). New query system, indexing, full-text search, on-device replicas and eventing capabilities are the new features implemented in the latest version.

Integrating with [ionic 3](https://ionicframework.com/), now you can use [WKWebView](https://developer.apple.com/documentation/webkit/wkwebview).

It is not fully implementations of couchbase-lite funcionalities. There are more to come. (needles to say, use it at your own risk ;) )

Contributor: [Ricky](https://github.com/rickymediaengine), [Flo](https://github.com/flolovebit)

## Installation
First add the plugin to your project by

    ionic cordova plugin add https://github.com/makbari/cordova-plugin-couchbase-lite.git


## Example

I try to compose a simple todo application with [ionic 3](https://ionicframework.com/), and place it in this repo. 


# Existing API Overview
## initDb
```
Params: [dbId:string]
Returns: Promise -> string
```

    
## get
Get a document from the database
```
Params: [dbId:string, docId:string]
Returns: Promise -> Doc
```


## putDoc
```
Params: [doc, isLocal: boolean = false]
Returns: Promise -> string
```

## allDocs
Returns all documents in the database in array batches.
```
Params: [dbId:string]
Returns: Observable -> [docs...]
```

## sync
Starts continuous push and pull replication against a database
```
Params: [dbId:string, syncUrl:string, user:string, pass:string]
Returns: Promise -> boolean
```

## upsert
Create or update a document. always makes itself the winning revision.
```
Params: [dbId:string, docId:string, jsonString:string, isLocal:string ("local" || "normal")]
Returns: Promise -> string
```

 ## changesDatabase
Starts a never ending (until reset is called) stream of database changes
```
Params: [dbId:string]
Returns: Observable -> {docId:string, is_delete:bool, seq_num:number}
```


## changesReplication
Starts a never ending (until reset is called) stream of replication changes
```
Params: [dbId:string]
Returns: Observable -> 'string status'
```


## stopReplication
Stops all replications.
```
Params: []
Returns: Promise -> boolean
```

### lastSequence
Gets the current sequence number of the given database
```
Params: [dbId:string]
Returns: Promise -> number
```

# Coming Soon APIs

## info
Gets the doc count of a local database
```
Params: [dbId:string]
Returns: Promise -> number

```

## compact
Runs database compaction
```
Params: [dbId:string]
Returns: Promise -> string
```

## reset
Removes all the database instances from the native array, cancels all change listeners 
on databases and replications.

```
Params: []
Returns: Promise -> boolean
```
    
## getDocRev
Gets the current revision of a document
```
Params: [dbId:string, docId:string]
Returns: Promise -> string
```

## putAttachment
Adds an attachment to a document. the directory path of the file is relative to the 
files folder on android or the root of the app sandbox on ios.
```
Params: [dbId:string, docId:string, fileName:string, attachmentName:string, mimeType:string, dirPath:string ]
Returns: Promise -> number
```
    

# Contributing
Your Help in developing plugin wrapper (ionic) for the andriod and implementing other functionalities is much appreciated.


# [happio/cordova-plugin-couchbase-lite](https://github.com/happieio/cordova-plugin-couchbase-lite)
Couchbase Lite Cordova plugin that provides a standard cordova interface instead of relying on the 
 built in REST Server or another HTTP API layer. The native implementations run on their own
 background thread(iOS)/threads(android) so operations will never block the UI.
 This repo is intentionally not forked from the main
[couchbase-lite-phonegap](https://github.com/couchbaselabs/Couchbase-Lite-PhoneGap-Plugin)
repo. A seperate issue tracker is needed to track issues and progress with the cordova interface
 code. This repo does not intend to provide improvements ahead of the main
 repository for the native code. This code will be manually updated as it is
 released from couchbase.
 
 The native API was developed partially out of performance concerns with the REST server and
 also in preparation for Couchbase Lite 2.

This project depends on
[RxJS 5.x](https://medialize.github.io/URI.js/), [lodash](https://lodash.com/docs) and an
[A+ compliant Promise library](https://github.com/promises-aplus/promises-spec/blob/master/implementations.md)
  to be globally available in the implementing project.
