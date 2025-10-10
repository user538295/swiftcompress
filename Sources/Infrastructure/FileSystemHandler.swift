import Foundation

/// File system operations handler
/// Wraps FileManager for testability and error translation
final class FileSystemHandler: FileHandlerProtocol {

    // MARK: - Properties

    private let fileManager: FileManager

    // MARK: - Initialization

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    // MARK: - File Existence and Permissions

    func fileExists(at path: String) -> Bool {
        return fileManager.fileExists(atPath: path)
    }

    func isReadable(at path: String) -> Bool {
        return fileManager.isReadableFile(atPath: path)
    }

    func isWritable(at path: String) -> Bool {
        return fileManager.isWritableFile(atPath: path)
    }

    // MARK: - File Information

    func fileSize(at path: String) throws -> Int64 {
        do {
            let attributes = try fileManager.attributesOfItem(atPath: path)
            guard let size = attributes[.size] as? Int64 else {
                throw InfrastructureError.readFailed(
                    path: path,
                    underlyingError: NSError(domain: "FileSystemHandler", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not determine file size"])
                )
            }
            return size
        } catch let error as InfrastructureError {
            throw error
        } catch {
            if (error as NSError).code == NSFileReadNoSuchFileError ||
               (error as NSError).domain == NSCocoaErrorDomain && (error as NSError).code == 260 {
                throw InfrastructureError.fileNotFound(path: path)
            }
            throw InfrastructureError.readFailed(path: path, underlyingError: error)
        }
    }

    // MARK: - Stream Creation

    func inputStream(at path: String) throws -> InputStream {
        guard let stream = InputStream(fileAtPath: path) else {
            throw InfrastructureError.streamCreationFailed(path: path)
        }
        return stream
    }

    func outputStream(at path: String) throws -> OutputStream {
        guard let stream = OutputStream(toFileAtPath: path, append: false) else {
            throw InfrastructureError.streamCreationFailed(path: path)
        }
        return stream
    }

    // MARK: - File Operations

    func deleteFile(at path: String) throws {
        do {
            try fileManager.removeItem(atPath: path)
        } catch {
            if (error as NSError).code == NSFileNoSuchFileError ||
               (error as NSError).domain == NSCocoaErrorDomain && (error as NSError).code == 4 {
                throw InfrastructureError.fileNotFound(path: path)
            }
            throw InfrastructureError.writeFailed(path: path, underlyingError: error)
        }
    }

    func createDirectory(at path: String) throws {
        do {
            try fileManager.createDirectory(
                atPath: path,
                withIntermediateDirectories: true,
                attributes: nil
            )
        } catch {
            throw InfrastructureError.directoryNotWritable(path: path)
        }
    }

    // MARK: - stdin/stdout Stream Creation

    func inputStream(from source: InputSource) throws -> InputStream {
        switch source {
        case .file(let path):
            // Use existing file-based method
            return try inputStream(at: path)

        case .stdin:
            // Create stream from stdin using /dev/stdin
            // This is the standard POSIX path for stdin on macOS and Linux
            guard let stream = InputStream(fileAtPath: "/dev/stdin") else {
                throw InfrastructureError.streamCreationFailed(path: "<stdin>")
            }
            return stream
        }
    }

    func outputStream(to destination: OutputDestination) throws -> OutputStream {
        switch destination {
        case .file(let path):
            // Use existing file-based method
            return try outputStream(at: path)

        case .stdout:
            // Create stream to stdout using /dev/stdout
            // This is the standard POSIX path for stdout on macOS and Linux
            guard let stream = OutputStream(toFileAtPath: "/dev/stdout", append: false) else {
                throw InfrastructureError.streamCreationFailed(path: "<stdout>")
            }
            return stream
        }
    }
}
