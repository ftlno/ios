//
//  APIClient+URLSessionTask.swift
//  Digipost
//
//  Created by Håkon Bogen on 14/01/15.
//  Copyright (c) 2015 Posten. All rights reserved.
//

import UIKit


extension APIClient {
    
    private func dataTask(urlRequest: NSURLRequest, success: () -> Void , failure: (error: APIError) -> () ) -> NSURLSessionTask? {
        let task = session.dataTaskWithRequest(urlRequest, completionHandler: { (data,response, error) in
            dispatch_async(dispatch_get_main_queue(), {
                let httpRespoonse = response as NSHTTPURLResponse
                println(httpRespoonse)
                let string = NSString(data: data, encoding: NSASCIIStringEncoding)
                println(string)
                if self.isUnauthorized(response as NSHTTPURLResponse?) {
                    self.removeAccessToken()
                    failure(error: APIError.UnauthorizedOAuthTokenError())
                } else if let actualError = error as NSError! {
                    failure(error: APIError(error: actualError))
                } else {
                    success()
                }
            });
        })
        lastPerformedTask = task
        return task
    }
    
    func jsonDataTask(urlrequest: NSURLRequest, success: (Dictionary<String, AnyObject>) -> Void , failure: (error: APIError) -> () ) -> NSURLSessionTask? {
        let task = session.dataTaskWithRequest(urlrequest, completionHandler: { (data, response, error) -> Void in
            dispatch_async(dispatch_get_main_queue(), {
                let httpRespoonse = response as NSHTTPURLResponse
                println(httpRespoonse)
                let string = NSString(data: data, encoding: NSASCIIStringEncoding)
                println(string)
                if self.isUnauthorized(response as NSHTTPURLResponse?) {
                    self.removeAccessToken()
                    failure(error: APIError.UnauthorizedOAuthTokenError())
                } else if let actualError = error as NSError! {
                    failure(error: APIError(error: actualError))
                } else {
                    var jsonError : NSError?
                    // TOODO make responseDictionary
                    if let actualData = data as NSData? {
                        if actualData.length == 0 {
                            failure(error:APIError(error:  NSError(domain: "", code: 232, userInfo: nil)))
                        } else {
                            let serializer = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &jsonError) as Dictionary<String, AnyObject>
                            success(serializer)
                        }
                    } else {
                        success(Dictionary<String, AnyObject>())
                    }
                }
            })
        })
        lastPerformedTask = task
        return task
    }
    
    
    func urlSessionDownloadTask(method: httpMethod, url: String, acceptHeader: String, progress: NSProgress?, success: (url: NSURL) -> Void , failure: (error: APIError) -> ()) -> NSURLSessionTask? {
        let url = NSURL(string: url)
        var urlRequest = NSMutableURLRequest(URL: url!, cachePolicy: .ReturnCacheDataElseLoad, timeoutInterval: 50)
        urlRequest.HTTPMethod = method.rawValue
        urlRequest.allHTTPHeaderFields![Constants.HTTPHeaderKeys.accept] = acceptHeader
        
        disposable = RACSignalSubscriptionNext(selector: Selector("URLSession:downloadTask:didFinishDownloadingToURL:"), fromProtocol: NSURLSessionDownloadDelegate.self) { (racTuple) -> Void in
            if let location = racTuple.objectAtIndex(2) as? NSURL {
                let contents = NSData(contentsOfURL: location)
                let stringContents = NSString(data: contents!, encoding: NSASCIIStringEncoding)
                let stringContents2 = NSString(data: contents!, encoding: NSUTF8StringEncoding)
                success(url: location)
            }
            self.disposable?.dispose()
        }
        
        RACSignalSubscriptionNext(selector:Selector("URLSession:downloadTask:didWriteData:totalBytesWritten:totalBytesExpectedToWrite:") , fromProtocol: NSURLSessionDownloadDelegate.self) { (racTuple) -> Void in
            dispatch_async(dispatch_get_main_queue(), {
                let totalBytesWritten = racTuple.fourth as NSNumber
                if let actualProgress = progress {
                    actualProgress.completedUnitCount = totalBytesWritten.longLongValue
                }
            })
        }
        let task = session.downloadTaskWithRequest(urlRequest, completionHandler: nil)
        lastPerformedTask = task
        return task
    }
    
    
    func isUnauthorized(urlResponse: NSHTTPURLResponse?) -> Bool {
        if let actualResponse = urlResponse as NSHTTPURLResponse! {
            if (actualResponse.statusCode == 403 || actualResponse.statusCode == 401) {
                return true
            }
        }
        return false
    }
    
    // Only GET allowed
    func urlSessionJSONTask(#url: String,  success: (Dictionary<String,AnyObject>) -> Void , failure: (error: APIError) -> ()) -> NSURLSessionTask? {
        let fullURL = NSURL(string: url, relativeToURL: NSURL(string: __SERVER_URI__))
        var urlRequest = NSMutableURLRequest(URL: fullURL!, cachePolicy: .ReturnCacheDataElseLoad, timeoutInterval: 50)
        urlRequest.HTTPMethod = httpMethod.get.rawValue
        for (key, value) in self.additionalHeaders {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }
        println(urlRequest.allHTTPHeaderFields)
        let task = jsonDataTask(urlRequest, success: success, failure: failure)
//        println(urlRequest.allHTTPHeaderFields)
//        println(self.session.configuration.HTTPAdditionalHeaders!)
        return task
    }
    
    func urlSessionTask(method: httpMethod, url:String, success: () -> Void , failure: (error: APIError) -> ()) -> NSURLSessionTask? {
        let url = NSURL(string: url)
        var urlRequest = NSMutableURLRequest(URL: url!, cachePolicy: .ReturnCacheDataElseLoad, timeoutInterval: 50)
        urlRequest.HTTPMethod = method.rawValue
        for (key, value) in self.additionalHeaders {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }
        let task = dataTask(urlRequest, success: success, failure: failure)
        return task
    }
    
    func urlSessionTask(method: httpMethod, url:String, parameters: Dictionary<String,AnyObject>, success: () -> Void , failure: (error: APIError) -> ()) -> NSURLSessionTask? {
        let url = NSURL(string: url)
        var urlRequest = NSMutableURLRequest(URL: url!, cachePolicy: .ReturnCacheDataElseLoad, timeoutInterval: 50)
        urlRequest.HTTPMethod = method.rawValue
        urlRequest.HTTPBody = NSJSONSerialization.dataWithJSONObject(parameters, options: NSJSONWritingOptions.PrettyPrinted, error: nil)
//        urlRequest.allHTTPHeaderFields
        for (key, value) in self.additionalHeaders {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }
        let task = dataTask(urlRequest, success: success, failure: failure)
        return task
    }
    
}
