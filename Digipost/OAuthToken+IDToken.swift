//
//  OAuthToken+IDToken.swift
//  Digipost
//
//  Created by Håkon Bogen on 19/05/15.
//  Copyright (c) 2015 Posten. All rights reserved.
//

import UIKit

extension OAuthToken {

    class func isIdTokenValid(idToken : String?, nonce : String) -> Bool {
        if let actualIDToken = idToken {
            let idTokenContentArray  = idToken?.componentsSeparatedByString(".")
            if idTokenContentArray?.count == 2 {
                if let base64EncodedJson = idTokenContentArray?[1] {
                    var numberOfCharactersAdded = 0
                    var error : NSError?
                    var alteredBase64EncodedJson = base64EncodedJson
                    var base64Data : NSData?
                    while base64Data == nil {
                        base64Data = NSData(base64EncodedString: alteredBase64EncodedJson, options: NSDataBase64DecodingOptions.IgnoreUnknownCharacters)
                        alteredBase64EncodedJson = alteredBase64EncodedJson.stringByAppendingString("=")
                        numberOfCharactersAdded++
                        if numberOfCharactersAdded > 7 {
                            return false
                        }
                    }
                    let string = NSString(data: base64Data!, encoding: NSASCIIStringEncoding)

                    if let jsonDictionary = NSJSONSerialization.JSONObjectWithData(base64Data!, options: NSJSONReadingOptions.AllowFragments, error: &error) as? [String : AnyObject] {
                        if let aud = jsonDictionary["aud"] as? String, let nonceInJson = jsonDictionary["nonce"] as? String {
                            if aud != OAUTH_CLIENT_ID {
                                return false
                            }
                            if nonce != nonceInJson {
                                return false
                            }
                        } else {
                            return false
                        }
                    }

                    let signature = "\(idTokenContentArray![0]).\(idTokenContentArray![1])"
                    let hmacEncodedBase64Json = base64EncodedJson.hmacsha256(OAUTH_SECRET)
                    if signature != hmacEncodedBase64Json {
                        return true
                    }
                    return true
                }
            }
        }

        return false

    }
}
