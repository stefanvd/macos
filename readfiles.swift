//
//  readfiles.swift
//
//  Copyright © 2017 Stefan vd. All rights reserved.
//

import Cocoa
import Foundation

class ViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
    var bookmarks = [URL: Data]()
    var applicationDocumentsDirectory: URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!
    }
    
    func bookmarkPath() -> String
    {
        var url = applicationDocumentsDirectory
        url = url.appendingPathComponent("Bookmarks.dict")
        return url.path
    }
    
    func loadBookmarks()
    {
        let path = bookmarkPath()
        bookmarks = NSKeyedUnarchiver.unarchiveObject(withFile: path) as! [URL: Data]
        for bookmark in bookmarks
        {
            restoreBookmark(bookmark)
        }
    }
    
    func saveBookmarks()
    {
        let path = bookmarkPath()
        NSKeyedArchiver.archiveRootObject(bookmarks, toFile: path)
    }
    
    func storeBookmark(url: URL)
    {
        do
        {
            let data = try url.bookmarkData(options: NSURL.BookmarkCreationOptions.withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
            bookmarks[url] = data
        }
        catch
        {
            print("Error storing bookmarks")
        }
        
    }
    
    func restoreBookmark(_ bookmark: (key: URL, value: Data))
    {
        var restoredUrl: URL?
        var isStale = false
        
        print("Restoring \(bookmark.key)")
        do
        {
            restoredUrl = try URL.init(resolvingBookmarkData: bookmark.value, options: NSURL.BookmarkResolutionOptions.withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
            
            do {
                let resourceKeys : [URLResourceKey] = [.creationDateKey, .isDirectoryKey]
                let enumerator = FileManager.default.enumerator(at: bookmark.key,
                                                                includingPropertiesForKeys: resourceKeys,
                                                                options: [.skipsHiddenFiles], errorHandler: { (url, error) -> Bool in
                                                                    print("Print: directoryEnumerator error at \(url): ", error)
                                                                    return true
                })!
                
                
                for case let fileURL as URL in enumerator {
                    let resourceValues = try fileURL.resourceValues(forKeys: Set(resourceKeys))
                    print(fileURL.path, resourceValues.creationDate!, resourceValues.isDirectory!)
                }
            } catch {
                print(error)
            }
            
            
        }
        catch
        {
            print("Error restoring bookmarks")
            restoredUrl = nil
        }
        
        if let url = restoredUrl
        {
            if isStale
            {
                print("URL is stale")
                
            }
            else
            {
                if !url.startAccessingSecurityScopedResource()
                {
                    print("Couldn't access: \(url.path)")
                }
            }
        }
        
    }
    
    func allowFolder() -> URL?
    {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = true
        openPanel.canChooseFiles = false
        openPanel.begin
            { (result) -> Void in
                if result == NSFileHandlingPanelOKButton
                {
                    let url = openPanel.url
                    self.storeBookmark(url: url!)
                }
        }
        return openPanel.url
}

    
    // the OPEN button
    @IBAction func openfolder(_ sender: Any) {
        let url = allowFolder()
        saveBookmarks()
    }
    
    // first run
    override func viewDidLoad() {
        super.viewDidLoad()
        loadBookmarks()
    }
}
