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
            appointment.title = "Innkalling: \(creatorName)"
            appointment.subTitle = metadata.json["subTitle"] as! String
            appointment.startTime = stringToDate(timeString: metadata.json["startTime"] as! String)
            appointment.endTime = stringToDate(timeString: metadata.json["endTime"] as! String)
            appointment.arrivalTime = metadata.json["arrivalTime"] as! String
            appointment.place = metadata.json["place"] as! String
            
            if let location = metadata.json["address"] as? Dictionary<String, String> {
                appointment.city = location["city"]!
                appointment.postalCode = location["postalCode"]!
                appointment.streetAddress = location["streetAddress"]!
            }

            if let infoList = metadata.json["info"] as? [[String: String]] {
                if infoList.count > 0 {
                    appointment.infoTitle1 = infoList[0]["title"]!
                    appointment.infoText1 = infoList[0]["text"]!
                }
                if infoList.count > 1 {
                    appointment.infoTitle1 = infoList[1]["title"]!
                    appointment.infoText1 = infoList[1]["text"]!
                    
                }
            }
            
            return appointment
        }
        return POSMetadataObject(type: POSMetadata.TYPE.NIL) as! POSAppointment
    }
    
    static func stringToDate(timeString: String) -> Date{
        return Date()
    }
}
