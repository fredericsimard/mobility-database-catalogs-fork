import Foundation

enum column : Int, CaseIterable {
    case timestamp               = 0
    case provider                = 1
    case regioncity              = 2
    case currenturl              = 3
    case updatednewsourceurl     = 4
    case datatype1               = 5
    case request                 = 6
    case downloadurl             = 7
    case country                 = 8
    case subdivision_name        = 9
    case municipality            = 10
    case name                    = 11
    case yournameorg             = 12
    case license_url             = 13
    case tripupdatesurl          = 14
    case servicealertsurl        = 15
    case genunknownrturl         = 16
    case authentication_type     = 17
    case authentication_info_url = 18
    case api_key_parameter_name  = 19
    case note                    = 20
    case gtfsschedulefeatures    = 21
    case gtfsschedulestatus      = 22
    case gtfsrealtimestatus      = 23
    case youremail               = 24
    case dataproduceremail       = 25
    case realtimefeatures        = 26
    case isocountrycode          = 27
    case feedupdatestatus        = 28
}

enum requestType: String {
    case isAddNewFeed = "New source"
    case isUpdateExistingFeed = "Source update"
    case isToRemoveFeed = "removed"
}

enum dataType: String {
    case schedule = "Schedule"
    case realtime = "Realtime"
}

enum bin {
    case bash
    case git
    case python
    case python3
    case swift
}

let arguments = CommandLine.arguments

if arguments.count >= 3 {

    let csvLineSeparator   : String = "\n"
    let csvColumnSeparator : String = ","

    let csvURLStringArg   = arguments[1]
    let dateFormatGREP    = arguments[2]
    let dateFormatDesired = arguments[3]
    
    // print("csvURLStringArg: \(csvURLStringArg), dateFormatterArg: \(dateFormatterArg)")

    let dateFormatter : DateFormatter = DateFormatter(); let today = Date()
    dateFormatter.dateFormat = dateFormatDesired
    let todayDate = dateFormatter.string(from: today) // Ex.: 07/27/2023

    var csvData = ""
    if let csvURL = URL(string: csvURLStringArg) {
        //print("download step 1")
        downloadCSV(from: csvURL) { result in
            // print("download step 2")
            switch result {
            case .success(let tempCsvData): csvData = tempCsvData
            case .failure(let error): print("Error downloading CSV: \(error)")
                // Handle the error
            }
        }
    } else {
        print("Error downloading CSV: invalid URL")
    }

    let csvLines : [String] = csvData.components(separatedBy: csvLineSeparator) ; var csvArray : [[String]] = []
    let csvLinesFinal : Array<String>.SubSequence = csvLines.dropFirst(csvLines.count - 2)
    for currentLine : String in csvLinesFinal {
        csvArray.append(currentLine.components(separatedBy: csvColumnSeparator))
    }
    
    var PYTHON_SCRIPT_OUTPUT : String = ""

    for line : [String] in csvArray {

        // Default values for variables
        var PYTHON_SCRIPT_ARGS_TEMP : String = ""

        if line.count >= column.allCases.count {
            let timestamp               : String = line[column.timestamp.rawValue]
            let provider                : String = line[column.provider.rawValue]
            let datatype1               : String = line[column.datatype1.rawValue]
            let request                 : String = line[column.request.rawValue]
            let country                 : String = line[column.country.rawValue]
            let subdivision_name        : String = line[column.subdivision_name.rawValue]
            let municipality            : String = line[column.municipality.rawValue]
            let name                    : String = line[column.name.rawValue]
            let license_url             : String = line[column.license_url.rawValue]
            let downloadURL             : String = line[column.downloadurl.rawValue]
            let authentication_type     : String = line[column.authentication_type.rawValue]
            let authentication_info_url : String = line[column.authentication_info_url.rawValue]
            let api_key_parameter_name  : String = line[column.api_key_parameter_name.rawValue]
            let note                    : String = line[column.note.rawValue]
            let gtfsschedulefeatures    : String = line[column.gtfsschedulefeatures.rawValue]
            let gtfsschedulestatus      : String = line[column.gtfsschedulestatus.rawValue]
            let gtfsrealtimestatus      : String = line[column.gtfsrealtimestatus.rawValue]
            let realtimefeatures        : String = line[column.realtimefeatures.rawValue]
            
            let dateFromCurrentLine     : String = extractDate(from: timestamp, usingGREP: dateFormatGREP)
            
            if dateFromCurrentLine == todayDate { // ...the row has been added today, process it.
                // print("\(terminalColor.green)    -> Found one row added today: \(provider)\(terminalColor.reset)")
                
                if request == requestType.isAddNewFeed.rawValue {
                    // print("\(terminalColor.cyan)    -> NEW SOURCE\(terminalColor.reset)")
                    
                    if datatype1.contains(dataType.schedule.rawValue) { // add_gtfs_schedule_source
                        
                        PYTHON_SCRIPT_ARGS_TEMP = "add_gtfs_schedule_source(provider=\"\(provider)\", country_code=\"\(country)\", direct_download_url=\"\(downloadURL)\", authentication_type=\"\(authentication_type)\", authentication_info_url=\"\(authentication_info_url)\", api_key_parameter_name=\"\(api_key_parameter_name)\", subdivision_name=\"\(subdivision_name)\", municipality=\"\(municipality)\", license_url=\"\(license_url)\", name=\"\(name)\", status=\"\(gtfsschedulestatus)\", features=\"\(gtfsschedulefeatures)\")"
                        
                    } else if datatype1.contains(dataType.realtime.rawValue) { // add_gtfs_realtime_source
                        // Emma: entity_type matches the realtime Data type options of Vehicle Positions, Trip Updates, or Service Alerts. If one of those three are selected, add it. If not, omit it.
                        
                        PYTHON_SCRIPT_ARGS_TEMP = "add_gtfs_realtime_source(entity_type=\"\(datatype1)\", provider=\"\(provider)\", direct_download_url=\"\(downloadURL)\", authentication_type=\"\(authentication_type)\", authentication_info_url=\"\(authentication_info_url)\", api_key_parameter_name=\"\(api_key_parameter_name)\", license_url=\"\(license_url)\", name=\"\(name)\", static_reference=\"\", note=\"\(note)\", status=\"\(gtfsrealtimestatus)\", features=\"\(realtimefeatures)\")"
                        
                    }
                    
                } else if request.contains(requestType.isUpdateExistingFeed.rawValue) {
                    // print("\(terminalColor.cyan)    -> SOURCE UPDATE\(terminalColor.reset)")
                    
                    if datatype1.contains(dataType.schedule.rawValue) { // update_gtfs_schedule_source
                        
                        PYTHON_SCRIPT_ARGS_TEMP = "update_gtfs_schedule_source(mdb_source_id=\"\", provider=\"\(provider)\", name=\"\(name)\", country_code=\"\(country)\", subdivision_name=\"\(subdivision_name)\", municipality=\"\(municipality)\", direct_download_url=\"\(downloadURL)\", authentication_type=\"\(authentication_type)\", authentication_info_url=\"\(authentication_info_url)\", api_key_parameter_name=\"\(api_key_parameter_name)\", license_url=\"\(license_url)\", status=\"\(gtfsschedulestatus)\", features=\"\(gtfsschedulefeatures)\")"
                        
                    } else if datatype1.contains(dataType.realtime.rawValue) { // update_gtfs_realtime_source
                        
                        PYTHON_SCRIPT_ARGS_TEMP = "update_gtfs_realtime_source(mdb_source_id=\"\", entity_type=\"\(datatype1)\", provider=\"\(provider)\", direct_download_url=\"\(downloadURL)\", authentication_type=\"\(authentication_type)\", authentication_info_url=\"\(authentication_info_url)\", api_key_parameter_name=\"\(api_key_parameter_name)\", license_url=\"\(license_url)\", name=\"\(name)\", static_reference=\"TO_BE_PROVIDED\", note=\"\(note)\", status=\"\(gtfsrealtimestatus)\", features=\"\(realtimefeatures)\")"
                    }
                    
                }  else if request.contains(requestType.isToRemoveFeed.rawValue) {
                    // print("\(terminalColor.cyan)    -> REMOVING SOURCE REQUEST\(terminalColor.reset)")
                    
                    if datatype1.contains(dataType.schedule.rawValue) { // update_gtfs_schedule_source
                        
                        PYTHON_SCRIPT_ARGS_TEMP = "update_gtfs_schedule_source(mdb_source_id=\"\", provider=\"\(provider)\", name=\"**** Requested for removal ****\", country_code=\"\(country)\", subdivision_name=\"\(subdivision_name)\", municipality=\"\(municipality)\", direct_download_url=\"\(downloadURL)\", authentication_type=\"\(authentication_type)\", authentication_info_url=\"\(authentication_info_url)\", api_key_parameter_name=\"\(api_key_parameter_name)\", license_url=\"\(license_url)\", status=\"\(gtfsschedulestatus)\", features=\"\(gtfsschedulefeatures)\")"
                        
                    } else if datatype1.contains(dataType.realtime.rawValue) { // update_gtfs_realtime_source
                        
                        PYTHON_SCRIPT_ARGS_TEMP = "update_gtfs_realtime_source(mdb_source_id=\"\", entity_type=\"\(datatype1)\", provider=\"\(provider)\", direct_download_url=\"\(downloadURL)\", authentication_type=\"\(authentication_type)\", authentication_info_url=\"\(authentication_info_url)\", api_key_parameter_name=\"\(api_key_parameter_name)\", license_url=\"\(license_url)\", name=\"**** Requested for removal ****\", static_reference=\"TO_BE_PROVIDED\", note=\"\(note)\", status=\"\(gtfsrealtimestatus)\", features=\"\(realtimefeatures)\")"
                        
                    }
                    
                } else {
                    // ... assume this is a new source by default :: add_gtfs_schedule_source
                    // print("\(terminalColor.red)    -> REQUEST TYPE NOT SPECIFIED, ASSUMING DEFAULT: NEW SOURCE\(terminalColor.reset)")
                    
                    PYTHON_SCRIPT_ARGS_TEMP = "add_gtfs_schedule_source(provider=\"\(provider)\", country_code=\"\(country)\", direct_download_url=\"\(downloadURL)\", authentication_type=\"\(authentication_type)\", authentication_info_url=\"\(authentication_info_url)\", api_key_parameter_name=\"\(api_key_parameter_name)\", subdivision_name=\"\(subdivision_name)\", municipality=\"\(municipality)\", license_url=\"\(license_url)\", name=\"\(name)\", status=\"\(gtfsschedulestatus)\", features=\"\(gtfsschedulefeatures)\")"
                    
                }
                
            }
            
        } else { print("Error: Insufficient components in the line. Skipping this entry.") } // END ...the row has been added today, process it.
        
        if PYTHON_SCRIPT_ARGS_TEMP.count > 0 { PYTHON_SCRIPT_OUTPUT = ( PYTHON_SCRIPT_OUTPUT + "\n" + PYTHON_SCRIPT_ARGS_TEMP ) }

    } // END FOR LOOP

    print(PYTHON_SCRIPT_OUTPUT.trimmingCharacters(in: .whitespacesAndNewlines))

} else {
    print("Insufficient arguments provided to the script. Expected a string with the URL and a date format and the date format desired.")
}

// MARK: - FUNCTIONS

func extractDate(from text: String, usingGREP dateFormatAsGREP: String) -> String {
    let dateFormatter : DateFormatter = DateFormatter()
    let regex = try! NSRegularExpression(pattern: dateFormatAsGREP)
    let range = NSRange(location: 0, length: text.utf16.count)
    if let match = regex.firstMatch(in: text, options: [], range: range) {
        let extractedDate = (text as NSString).substring(with: match.range)
        let tempDate : Date? = dateFormatter.date(from: extractedDate)
        return dateFormatter.string(from: tempDate!) // Ex.: 12/31/2023 or 01/01/2023
    }
    return ""
}

func downloadCSV(from url: URL, completion: @escaping (Result<String, Error>) -> Void) {
    let group = DispatchGroup.init()
    group.enter()
    // print("downloadCSV called : \(url)")
    let session = URLSession.shared
    let semaphore : DispatchSemaphore = DispatchSemaphore(value: 0)
    let task = session.dataTask(with: url) { data, response, error -> Void in
        defer {  // Defer makes all ends of this scope make something, here we want to leave the dispatch. This is executed when the scope ends, even if with exception.
            group.leave() // Manually subtract one from the operation count
        }
        // print(response!)
        semaphore.signal()
        // print("downloadCSV : begin")
        if let error = error {
            completion(.failure(error))
            return
        }
        
        if let data = data, let csvString = String(data: data, encoding: .utf8) {
            completion(.success(csvString))
        } else {
            let unknownError = NSError(domain: "CSVDownloadError", code: -1, userInfo: nil)
            completion(.failure(unknownError))
        }
    }
    task.resume()
    semaphore.wait()
    group.wait()  // Wait for group to end operations.
}

func runShellCommand(withBinary binary: bin, andArguments args:[String]) -> String? {

    // Class objects
    let process = Process() ; let outputPipe = Pipe()

    // Which binary & set up the process
    switch binary {
        case .bash    : process.executableURL = URL(fileURLWithPath: "/bin/bash")
        case .git     : process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/git")
        case .python  : process.executableURL = URL(fileURLWithPath: "/usr/bin/python")
        case .python3 : process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/python3")
        case .swift   : process.executableURL = URL(fileURLWithPath: "/usr/bin/swift")
    }
    process.arguments = args ; process.standardOutput = outputPipe

    // launch the process
    try! process.run() ; process.waitUntilExit()

    // get output data and return it as a String if any, else return empty string
    let scriptOutputData : Data = outputPipe.fileHandleForReading.readDataToEndOfFile()
    if let scriptOutputString : String = String(data: scriptOutputData, encoding: .utf8) { return scriptOutputString }
    
    return nil
}