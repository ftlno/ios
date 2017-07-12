//
// Copyright (C) Posten Norge AS
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//         http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation

@objc class POSMetadataMapper : NSObject{
    
    static func get(metadata : POSMetadata, creatorName: String) -> Any? {
        if metadata.type == POSMetadata.TYPE.APPOINTMENT {
            return parseAppointment(metadata: metadata, creatorName: creatorName)
        }
        return POSMetadataObject(type: POSMetadata.TYPE.NIL)
    }
    
    static func appointment(metadata: POSMetadata, creatorName: String) -> Any? {
        if metadata.type == POSMetadata.TYPE.APPOINTMENT {
            return parseAppointment(metadata: metadata, creatorName: creatorName)
        }
        return POSMetadataObject(type: POSMetadata.TYPE.NIL)
    }
    
    private static func parseAppointment(metadata: POSMetadata, creatorName: String) -> POSAppointment {
        if metadata.json.count > 0 {
            
            let appointment = POSAppointment()
            appointment.title = "Du har fått en innkalling fra \(creatorName)"
            appointment.subTitle = metadata.json["subTitle"] as! String
            
            if let startTime = stringToDate(timeString: metadata.json["startTime"] as! String){
                appointment.startTime = startTime
            }
            
            if let endTime = stringToDate(timeString: metadata.json["endTime"] as! String){
                appointment.endTime = endTime
            }
            
            if let arrivalTimeDate = stringToDate(timeString: metadata.json["arrivalTime"] as! String) {
                appointment.arrivalTimeDate = arrivalTimeDate
            } else {
                appointment.arrivalTime = metadata.json["arrivalTime"] as! String
            }            
            appointment.place = metadata.json["place"] as! String

            if let location = metadata.json["address"] as? Dictionary<String, String> {
                appointment.streetAddress = location["streetAddress"]!
                appointment.postalCode = location["postalCode"]!
                appointment.city = location["city"]!
                appointment.address = "\(appointment.streetAddress), \(appointment.postalCode) \(appointment.city)"
            }

            if let infoList = metadata.json["info"] as? [[String: String]] {
                if infoList.count > 0 {
                    if let infoTitle = infoList[0]["title"], let infoText = infoList[0]["text"] {
                        appointment.infoTitle1 = infoTitle
                        appointment.infoText1 = infoText
                    }
                }
                
                if infoList.count > 1 {
                    if let infoTitle = infoList[1]["title"], let infoText = infoList[1]["text"] {
                        appointment.infoTitle2 = infoTitle
                        appointment.infoText2 = infoText
                    }
                }
            }
            
            return appointment
        }
        return POSMetadataObject(type: POSMetadata.TYPE.NIL) as! POSAppointment
    }
    
    static func stringToDate(timeString: String) -> Date?{
        if #available(iOS 10.0, *) {
            let formatter = ISO8601DateFormatter()
            if let date =  formatter.date(from: timeString) {
                return date
            }
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZ"
        if let date = formatter.date(from: timeString) {
            return date
        }
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZ"
        if let date = formatter.date(from: timeString) {
            return date
        }
        return nil
    }
}
