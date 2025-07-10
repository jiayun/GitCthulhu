import Foundation

public extension FileManager {
    func isDirectory(at url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        return fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue
    }

    func isGitRepository(at url: URL) -> Bool {
        let gitDirectory = url.appendingPathComponent(".git")
        return isDirectory(at: gitDirectory)
    }

    func findGitRepository(from url: URL) -> URL? {
        var currentURL = url

        while currentURL.path != "/" {
            if isGitRepository(at: currentURL) {
                return currentURL
            }
            currentURL = currentURL.deletingLastPathComponent()
        }

        return nil
    }
}
