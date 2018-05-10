#!/usr/bin/env node

var fs = require('fs');

var xcconfigPath = "platforms/ios/cordova/build.xcconfig";
//NOTE: if embedding swift code add this plugin to your project https://github.com/happieio/cordova-plugin-swiftbridge.git
// var pluginDir = "[iosProjectName]/Plugins/happie-plugin-cordova-swiftBridge/Swift-Bridging-Header.h"; //Use if you have embedded swift code

var xcodeOptions = [""];
// xcodeOptions.push('SWIFT_OBJC_BRIDGING_HEADER = ' + pluginDir); //Use if you have embedded swift code
// xcodeOptions.push('EMBEDDED_CONTENT_CONTAINS_SWIFT = YES'); //Use if you have embedded swift code
xcodeOptions.push('ENABLE_BITCODE = NO'); //switch to YES when cbl supports bit code
xcodeOptions.push('ARCHS = arm64 armv7'); //remove when cbl will slice for armv7s
xcodeOptions.push('VALID_ARCHS = arm64 armv7'); //remove when cbl will slice for armv7s
// xcodeOptions.push('LD_RUNPATH_SEARCH_PATHS = "@executable_path/Frameworks"'); //Use if you have embedded swift code
xcodeOptions.push('IPHONEOS_DEPLOYMENT_TARGET = 8.1');
fs.appendFileSync(xcconfigPath, xcodeOptions.join('\n'));
console.log("!!!!!!!!!!!!!!!!!!!!!!!!!!!!DID FINISH SIGNING & STANDARD SWIFT CONFIG !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");