
import Foundation

class ArcGISAuth {
    class func getToken() {
        let params = [
            "client_id"         : ArcGISConfiguration.clientID,
            "client_secret"     : ArcGISConfiguration.clientSecret,
            "grant_type"        : "client_credentials",
            "expiration"        : 20160, // Minutes
            ] as Dictionary<String, Any>

        var request = URLRequest(url: ArcGISConfiguration.oauthURL)
        request.httpMethod = "POST"

        // ArcGIS requires form encoding for authentication POSTs
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = params.percentEscaped().data(using: .utf8)
        
        let session = URLSession.shared
        let task = session.dataTask(with: request, completionHandler: { data, response, error -> Void in
            do {
                guard let data = data else {
                    throw ParsingError.invalidResponse
                }
                guard let json = try JSONSerialization.jsonObject(with: data) as? Dictionary<String, AnyObject> else {
                    throw ParsingError.invalidJSON
                }
                
                if let accessToken = json["access_token"],
                    let expiresIn = json["expires_in"] {
                    print("The Access token \(accessToken) expires in \(expiresIn) minutes")
                }
                
            } catch {
                print("error")
            }
        })

        task.resume()
    }
}

enum ParsingError : Error {
    case invalidResponse
    case invalidJSON
}

extension Dictionary {
    func percentEscaped() -> String {
        return map { (key, value) in
            let escapedKey = "\(key)".addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
            let escapedValue = "\(value)".addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
            return escapedKey + "=" + escapedValue
        }
        .joined(separator: "&")
    }
}

extension CharacterSet {
    static let urlQueryValueAllowed: CharacterSet = {
        let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let subDelimitersToEncode = "!$&'()*+,;="

        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")
        return allowed
    }()
}
