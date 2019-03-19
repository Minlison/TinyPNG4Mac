//
//  DragContainer.swift
//  tinypng
//
//  Created by kyle on 16/6/30.
//  Copyright © 2016年 kyleduo. All rights reserved.
//

import Cocoa

protocol DragContainerDelegate {
	func draggingEntered();
	func draggingExit();
	func draggingFileAccept(_ files:Array<URL>);
}

class DragContainer: NSView {
	var delegate : DragContainerDelegate?
	
	let acceptTypes = ["png", "jpg", "jpeg"]
    let NSFilenamesPboardType = NSPasteboard.PasteboardType("NSFilenamesPboardType")
	
    let normalAlpha: CGFloat = 0
    let highlightAlpha: CGFloat = 0.2
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
        self.registerForDraggedTypes([
            NSPasteboard.PasteboardType.backwardsCompatibleFileURL,
            NSPasteboard.PasteboardType(rawValue: kUTTypeItem as String)
            ]);
	}
	
	override func draw(_ dirtyRect: NSRect) {
		
	}
	
	override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        self.layer?.backgroundColor = NSColor(white: 1, alpha: highlightAlpha).cgColor;
		let res = checkExtension(sender)
		if let delegate = self.delegate {
			delegate.draggingEntered();
		}
		if res {
			return NSDragOperation.generic
		}
		return NSDragOperation()
	}
	
	override func draggingExited(_ sender: NSDraggingInfo?) {
        self.layer?.backgroundColor = NSColor(white: 1, alpha: normalAlpha).cgColor;
		if let delegate = self.delegate {
			delegate.draggingExit();
		}
	}
	
	override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        self.layer?.backgroundColor = NSColor(white: 1, alpha: normalAlpha).cgColor;
		return true
	}
	
	override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
		var files = Array<URL>()
		if let board = sender.draggingPasteboard().propertyList(forType: NSFilenamesPboardType) as? NSArray {
			for path in board {
                var isDir : ObjCBool = false
                if FileManager.default.fileExists(atPath: path as! String, isDirectory: &isDir) && isDir.boolValue {
                    files.append(contentsOf: findAllTypeFiles(path as? String))
                    continue
                }
				let url = URL(fileURLWithPath: path as! String)
				let fileExtension = url.pathExtension.lowercased()
				if acceptTypes.contains(fileExtension) {
					files.append(url)
				}
			}
		}
		
		if self.delegate != nil {
			self.delegate?.draggingFileAccept(files);
		}
		
		return true
	}
	
	func checkExtension(_ draggingInfo: NSDraggingInfo) -> Bool {
        if let board = draggingInfo.draggingPasteboard().propertyList(forType: NSFilenamesPboardType) as? NSArray {
			for path in board {
                var isDir : ObjCBool = false
                if FileManager.default.fileExists(atPath: path as! String, isDirectory: &isDir) && isDir.boolValue {
                    return true
                }
				return checkPathExtension(path as! String)
			}
		}
		return false
	}
    func checkPathExtension(_ path: String) -> Bool {
        let url = URL(fileURLWithPath: path)
        let fileExtension = url.pathExtension.lowercased()
        if acceptTypes.contains(fileExtension) {
            return true
        }
        return false
    }
    func findAllTypeFiles(_ dir : String?) -> [URL] {
        guard let dir = dir else { return [URL]()}
        var isDirectory: ObjCBool = false
        // 文件夹
        var allFiles = [URL]()
        if dir.hasSuffix(".imageset") || ( FileManager.default.fileExists(atPath: dir, isDirectory: &isDirectory) && isDirectory.boolValue ) {
            let enumerator = FileManager.default.enumerator(atPath: dir)
            var isDir: ObjCBool = false
            while let file = enumerator?.nextObject() {
                let filePath: String = "\(dir)/\(file)"
                if FileManager.default.fileExists(atPath: filePath, isDirectory: &isDir) && isDir.boolValue {
                    allFiles.append(contentsOf: findAllTypeFiles(filePath))
                } else if filePath.hasSuffix(".imageset") {
                    allFiles.append(contentsOf: findAllTypeFiles(filePath))
                } else if checkPathExtension(filePath) {
                    allFiles.append(URL(fileURLWithPath: filePath))
                }
            }
            return allFiles
        }
        if checkPathExtension(dir) {
            allFiles.append(URL(fileURLWithPath: dir))
        }
        return allFiles
    }
}
