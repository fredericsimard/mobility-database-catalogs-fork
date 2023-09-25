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

enum defaults: String {
    case date = "01/01/1970"
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

// let arguments : [String] = ["unused", "https://docs.google.com/a/google.com/spreadsheets/d/1Q96KDppKsn2khdrkraZCQ7T_qRSfwj7WsvqXvuMt4Bc/gviz/tq?tq=select%20*&tqx=out:csv", "[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}|[0-9]{4}-[0-9]{2}-[0-9]{2}", "MM/dd/yyyy"]

if arguments.count == 4 {
    let csvLineSeparator   : String = "\n"
    let csvColumnSeparator : String = ","

    let csvURLStringArg      = arguments[1]
    let dateFormatGREPArg    = arguments[2]
    let dateFormatDesiredArg = arguments[3]

    print("args")
    print("\(arguments[0])\n")
    print("\(csvURLStringArg)\n")
    print("\(dateFormatGREPArg)\n")
    print("\(dateFormatDesiredArg)\nEND")

    guard let csvURLasURL = URL(string: csvURLStringArg) else {
        print("\n   ERROR: The specified URL does not appear to exist :\n   \(csvURLStringArg)\n")
        exit(1)
    }
    
    let dateFormatter : DateFormatter = DateFormatter(); let today = Date()
    dateFormatter.dateFormat = dateFormatDesiredArg
    let todayDate = dateFormatter.string(from: today) // Ex.: 07/27/2023

    let csvData = try String(contentsOf: csvURLasURL, encoding:.utf8)

    let csvLines : [String] = csvData.components(separatedBy: csvLineSeparator) ; var csvArray : [[String]] = [[]]
    // let csvLinesFinal : Array<String>.SubSequence = csvLines.dropFirst(csvLines.count - 2)
    for currentLine : String in csvLines {
        csvArray.append(currentLine.components(separatedBy: csvColumnSeparator))
    }
    
    var PYTHON_SCRIPT_OUTPUT : String = ""
    let dateFormatAsRegex = try Regex(dateFormatGREPArg)

    for line : [String] in csvArray {
        
        // Default values for variables
        var PYTHON_SCRIPT_ARGS_TEMP : String = ""

        if line.count >= column.allCases.count {

            let timestamp               : String = line[column.timestamp.rawValue].trimmingCharacters(in: .whitespacesAndNewlines)
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

            let dateFromCurrentLine = extractDate(from: timestamp, usingGREP: dateFormatAsRegex, desiredDateFormat: dateFormatDesiredArg)
            
            if dateFromCurrentLine == todayDate { // ...the row has been added today, process it.
                // print("\(terminalColor.green)    -> Found one row added today: \(provider)\(terminalColor.reset)")
                
                if request.contains(requestType.isAddNewFeed.rawValue) {
                    // print("\(terminalColor.cyan)    -> NEW SOURCE\(terminalColor.reset)")
                    
                    if datatype1.contains(dataType.schedule.rawValue) { // add_gtfs_schedule_source
                        
                        PYTHON_SCRIPT_ARGS_TEMP = "add_gtfs_schedule_source(provider=\(provider), country_code=\(country), direct_download_url=\(downloadURL), authentication_type=\(authentication_type), authentication_info_url=\(authentication_info_url), api_key_parameter_name=\(api_key_parameter_name), subdivision_name=\(subdivision_name), municipality=\(municipality), license_url=\(license_url), name=\(name), status=\(gtfsschedulestatus), features=\(gtfsschedulefeatures))"
                        
                    } else if datatype1.contains(dataType.realtime.rawValue) { // add_gtfs_realtime_source
                        // Emma: entity_type matches the realtime Data type options of Vehicle Positions, Trip Updates, or Service Alerts. If one of those three are selected, add it. If not, omit it.
                        
                        PYTHON_SCRIPT_ARGS_TEMP = "add_gtfs_realtime_source(entity_type=\(datatype1), provider=\(provider), direct_download_url=\(downloadURL), authentication_type=\(authentication_type), authentication_info_url=\(authentication_info_url), api_key_parameter_name=\(api_key_parameter_name), license_url=\(license_url), name=\(name), static_reference=, note=\(note), status=\(gtfsrealtimestatus), features=\(realtimefeatures))"
                        
                    }
                    
                } else if request.contains(requestType.isUpdateExistingFeed.rawValue) {
                    // print("\(terminalColor.cyan)    -> SOURCE UPDATE\(terminalColor.reset)")
                    
                    if datatype1.contains(dataType.schedule.rawValue) { // update_gtfs_schedule_source
                        
                        PYTHON_SCRIPT_ARGS_TEMP = "update_gtfs_schedule_source(mdb_source_id=, provider=\(provider), name=\(name), country_code=\(country), subdivision_name=\(subdivision_name), municipality=\(municipality), direct_download_url=\(downloadURL), authentication_type=\(authentication_type), authentication_info_url=\(authentication_info_url), api_key_parameter_name=\(api_key_parameter_name), license_url=\(license_url), status=\(gtfsschedulestatus), features=\(gtfsschedulefeatures))"
                        
                    } else if datatype1.contains(dataType.realtime.rawValue) { // update_gtfs_realtime_source
                        
                        PYTHON_SCRIPT_ARGS_TEMP = "update_gtfs_realtime_source(mdb_source_id=, entity_type=\(datatype1), provider=\(provider), direct_download_url=\(downloadURL), authentication_type=\(authentication_type), authentication_info_url=\(authentication_info_url), api_key_parameter_name=\(api_key_parameter_name), license_url=\(license_url), name=\(name), static_reference=TO_BE_PROVIDED, note=\(note), status=\(gtfsrealtimestatus), features=\(realtimefeatures))"
                    }
                    
                }  else if request.contains(requestType.isToRemoveFeed.rawValue) {
                    // print("\(terminalColor.cyan)    -> REMOVING SOURCE REQUEST\(terminalColor.reset)")
                    
                    if datatype1.contains(dataType.schedule.rawValue) { // update_gtfs_schedule_source
                        
                        PYTHON_SCRIPT_ARGS_TEMP = "update_gtfs_schedule_source(mdb_source_id=, provider=\(provider), name=\"**** Requested for removal ****\", country_code=\(country), subdivision_name=\(subdivision_name), municipality=\(municipality), direct_download_url=\(downloadURL), authentication_type=\(authentication_type), authentication_info_url=\(authentication_info_url), api_key_parameter_name=\(api_key_parameter_name), license_url=\(license_url), status=\(gtfsschedulestatus), features=\(gtfsschedulefeatures))"
                        
                    } else if datatype1.contains(dataType.realtime.rawValue) { // update_gtfs_realtime_source
                        
                        PYTHON_SCRIPT_ARGS_TEMP = "update_gtfs_realtime_source(mdb_source_id=, entity_type=\(datatype1), provider=\(provider), direct_download_url=\(downloadURL), authentication_type=\(authentication_type), authentication_info_url=\(authentication_info_url), api_key_parameter_name=\(api_key_parameter_name), license_url=\(license_url), name=\"**** Requested for removal ****\", static_reference=\"TO_BE_PROVIDED\", note=\(note), status=\(gtfsrealtimestatus), features=\(realtimefeatures))"
                        
                    }
                    
                } else {
                    // ... assume this is a new source by default :: add_gtfs_schedule_source
                    // print("\(terminalColor.red)    -> REQUEST TYPE NOT SPECIFIED, ASSUMING DEFAULT: NEW SOURCE\(terminalColor.reset)")
                    
                    PYTHON_SCRIPT_ARGS_TEMP = "add_gtfs_schedule_source(provider=\(provider), country_code=\(country), direct_download_url=\(downloadURL), authentication_type=\(authentication_type), authentication_info_url=\(authentication_info_url), api_key_parameter_name=\(api_key_parameter_name), subdivision_name=\(subdivision_name), municipality=\(municipality), license_url=\(license_url), name=\(name), status=\(gtfsschedulestatus), features=\(gtfsschedulefeatures))"
                    
                }
                
            }
            
        } else { 
            // print("Error: Insufficient components in the line. Skipping this entry.")
        } // END ...the row has been added today, process it.
        
        if PYTHON_SCRIPT_ARGS_TEMP.count > 0 { PYTHON_SCRIPT_OUTPUT = ( PYTHON_SCRIPT_OUTPUT + "\n" + PYTHON_SCRIPT_ARGS_TEMP ) }

    } // END FOR LOOP

    // return final output
    print(PYTHON_SCRIPT_OUTPUT.dropFirst().dropLast())

} else {
    print("Incorrect number of arguments provided to the script. Expected 3: a string with the URL, a date format and the date format desired.")
    exit(1)
}

// MARK: - FUNCTIONS

func extractDate(from theDateToConvert: String, usingGREP dateFormatAsGREP: Regex<AnyRegexOutput>, desiredDateFormat desiredFormat: String) -> String {
    if let match = theDateToConvert.firstMatch(of: dateFormatAsGREP) {
        // find first match
        let matchOutput = String(match.output[0].substring!)

        // date formatter and find date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = desiredFormat
        let date = dateFormatter.date(from: matchOutput)
        
        // default date if formatter fails, otherwise return correctly formatted date
        var returnDate = defaults.date.rawValue
        if date != nil { returnDate = dateFormatter.string(from: date!) }
        return returnDate
    }
    
    // return default date
    return defaults.date.rawValue
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