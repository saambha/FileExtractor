#!/usr/bin/swift
import Foundation

enum FileExtractorType: String {
    
    case Photo  = "Photo"
    case Video  = "Video"
    case Audio  = "Audio"
    case PDF    = "PDF"
    case Default = "All"
    
    func supportFileFormats() -> [String] {
        switch self {
        case .Photo:
            return ["jpg", "JPG", "jpeg", "png", "tiff"]
        case .Video:
            return ["mp4", "mkv", "vid"]
        case .Audio:
            return ["mp3"]
        case .PDF:
            return ["pdf"]
        case .Default:
            return ["jpg", "jpeg", "png", "gif", "mp4", "mkv", "mp3", "pdf", "JPG"]
        }
    }
}



class FileExtractor{
    
    func validateScriptParams(_ args: [String]) -> (FileExtractorType) {
        if args.count < 1 || args.count > 2 {
            print("Please enter the valid format.\n<Script Name> <File Type> \nPhoto\nVideo\nPDF>")
            exit(0)
        }else{
            if let fileType = args.last {
                if let filetypeValue = FileExtractorType(rawValue: fileType){
                    return filetypeValue
                }
            }
        }
        return FileExtractorType(rawValue: "All")!
    }
    
    func findAndExtractWith(type value: FileExtractorType) {
        
        for types in value.supportFileFormats() {
            let results = self.extractAllFile(atPath: FileManager.default.currentDirectoryPath, withExtension: types)
            print("\nFor type: \(types) \nResults Count: \(results.count)\n\n")
            self.copyFileAt(relativeFolderPath: types, withFiles: results)
        }
    }
    
    func extractAllFile(atPath path: String, withExtension fileExtension:String) -> [String] {
        let pathURL = NSURL(fileURLWithPath: path, isDirectory: true)
        var allFilesPath: [String] = []
        let fileManager = FileManager.default
        let pathString = path.replacingOccurrences(of: "file:", with: "")
        if let enumerator = fileManager.enumerator(atPath: pathString) {
            for file in enumerator {
                if #available(iOS 9.0, *) {
                    if let path = NSURL(fileURLWithPath: file as! String, relativeTo: pathURL as URL).path, path.hasSuffix(".\(fileExtension)"){
                        allFilesPath.append(path.lowercased())
                    }
                } else {
                    // Fallback on earlier versions
                    print("Not available, #available iOS 9.0 & above")
                }
            }
        }
        return allFilesPath
    }
    
    func copyFileAt(relativeFolderPath path: String?, withFiles names: [String])  {

        let fileManager = FileManager.default
        let paths = NSSearchPathForDirectoriesInDomains(.desktopDirectory, .userDomainMask, true)
        let desktopPath = paths.first
        let desktopUrl = URL(fileURLWithPath: desktopPath!, isDirectory: true)
        let scriptPhotoDir = desktopUrl.appendingPathComponent("ScriptsPhotos/" + path!.lowercased(), isDirectory: true)
        
        var isDir:ObjCBool = true

        if fileManager.fileExists(atPath: scriptPhotoDir.path, isDirectory: &isDir) == false {
            do {
                try fileManager.createDirectory(atPath: scriptPhotoDir.path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Error creating directory : \(error.localizedDescription)")
            }
        }
        print(scriptPhotoDir)
        
        DispatchQueue.global(qos: .default).async {
            do {
                for name in names {
                    let fileName = (name as NSString).lastPathComponent
                    try fileManager.copyItem(atPath: name, toPath: scriptPhotoDir.path  + "/" + fileName)
                }
            }catch {
                print("Failed Copying Files")
            }
        }
    }
}

let arguments       = CommandLine.arguments
let classInstance   = FileExtractor()
let fileType        = classInstance.validateScriptParams(arguments)
print("fileType: \(fileType)")
classInstance.findAndExtractWith(type: fileType)
