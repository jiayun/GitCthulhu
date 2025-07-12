//
// MemoryLeakTests.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-12.
//

import Foundation
@testable import GitCore
import Testing

// TODO: Re-enable when LibGit2Repository is available
/*
 @Suite("Memory Leak Tests")
 struct MemoryLeakTests {

     // Helper to track weak references
     class WeakBox<T: AnyObject> {
         weak var value: T?
         init(_ value: T) {
             self.value = value
         }
     }

     // Helper to create test repository
     func createTestRepository() throws -> URL {
         let tempDir = FileManager.default.temporaryDirectory
             .appendingPathComponent(UUID().uuidString)
         try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

         let process = Process()
         process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
         process.arguments = ["init"]
         process.currentDirectoryURL = tempDir

         let pipe = Pipe()
         process.standardOutput = pipe
         process.standardError = pipe

         try process.run()
         process.waitUntilExit()

         guard process.terminationStatus == 0 else {
             throw GitError.failedToInitializeRepository("Failed to create test repository")
         }

         return tempDir
     }

     func cleanupTestRepository(_ url: URL) {
         try? FileManager.default.removeItem(at: url)
     }

     @Test("LibGit2Repository memory leak test")
     @MainActor
     func testLibGit2RepositoryMemoryLeak() async throws {
         let tempDir = try createTestRepository()
         defer { cleanupTestRepository(tempDir) }

         var weakRefs: [WeakBox<LibGit2Repository>] = []

         // Create and release multiple repositories
         for _ in 0..<5 {
             autoreleasepool {
                 do {
                     let repo = try LibGit2Repository(url: tempDir)
                     weakRefs.append(WeakBox(repo))

                     // Perform some operations
                     Task { @MainActor in
                         _ = try? await repo.getBranches()
                         _ = try? await repo.getRepositoryStatus()
                         await repo.close()
                     }
                 } catch {
                     // Ignore errors in memory test
                 }
             }
         }

         // Wait for async operations to complete
         try await Task.sleep(for: .seconds(1))

         // Force garbage collection
         for _ in 0..<5 {
             autoreleasepool { }
         }

         // Check for leaks
         var leakedCount = 0
         for weakRef in weakRefs {
             if weakRef.value != nil {
                 leakedCount += 1
             }
         }

         #expect(leakedCount == 0, "Found \(leakedCount) leaked LibGit2Repository instances")
     }

     @Test("ResourceManager memory leak test")
     func testResourceManagerMemoryLeak() async throws {
         let manager = ResourceManager()
         let tempDir = try createTestRepository()
         defer { cleanupTestRepository(tempDir) }

         var weakRefs: [WeakBox<LibGit2Repository>] = []

         // Open and close repositories through ResourceManager
         for i in 0..<5 {
             let subDir = tempDir.appendingPathComponent("repo\(i)")
             try FileManager.default.createDirectory(at: subDir, withIntermediateDirectories: true)

             // Copy git directory
             let gitSource = tempDir.appendingPathComponent(".git")
             let gitDest = subDir.appendingPathComponent(".git")
             try FileManager.default.copyItem(at: gitSource, to: gitDest)

             autoreleasepool {
                 Task {
                     do {
                         let repo = try await manager.openRepository(at: subDir)
                         await MainActor.run {
                             weakRefs.append(WeakBox(repo))
                         }
                         await manager.closeRepository(at: subDir)
                     } catch {
                         // Ignore errors in memory test
                     }
                 }
             }
         }

         // Wait for async operations
         try await Task.sleep(for: .seconds(1))

         // Close all repositories
         await manager.closeAllRepositories()

         // Check open count
         let openCount = await manager.openRepositoryCount()
         #expect(openCount == 0, "ResourceManager still has \(openCount) open repositories")

         // Force garbage collection
         for _ in 0..<5 {
             autoreleasepool { }
         }

         // Check for leaks
         var leakedCount = 0
         for weakRef in weakRefs {
             if weakRef.value != nil {
                 leakedCount += 1
             }
         }

         #expect(leakedCount == 0, "Found \(leakedCount) leaked repositories through ResourceManager")
     }

     @Test("Circular reference test")
     @MainActor
     func testCircularReferences() async throws {
         let tempDir = try createTestRepository()
         defer { cleanupTestRepository(tempDir) }

         weak var weakRepo: LibGit2Repository?

         autoreleasepool {
             do {
                 let repo = try LibGit2Repository(url: tempDir)
                 weakRepo = repo

                 // Perform operations that might create retain cycles
                 _ = try await repo.getBranches()
                 _ = try await repo.getRepositoryStatus()

                 // Create a file and stage it
                 let testFile = tempDir.appendingPathComponent("test.txt")
                 try "Test content".write(to: testFile, atomically: true, encoding: .utf8)
                 try await repo.stageFile("test.txt")
                 _ = try await repo.commit(message: "Test commit")

                 await repo.close()
             } catch {
                 // Ignore errors in memory test
             }
         }

         // Force garbage collection
         for _ in 0..<5 {
             autoreleasepool { }
         }

         #expect(weakRepo == nil, "Repository instance was not deallocated - possible retain cycle")
     }

     @Test("ResourceManager cleanup timer test")
     func testResourceManagerCleanupTimer() async throws {
         let manager = ResourceManager()
         let tempDir = try createTestRepository()
         defer { cleanupTestRepository(tempDir) }

         // Open a repository
         _ = try await manager.openRepository(at: tempDir)

         // Verify it's open
         let initialCount = await manager.openRepositoryCount()
         #expect(initialCount == 1)

         // Get memory report
         let report = await manager.memoryReport()
         #expect(report.openRepositoryCount == 1)
         #expect(report.oldestRepository != nil)

         // Close all repositories
         await manager.closeAllRepositories()

         // Verify all closed
         let finalCount = await manager.openRepositoryCount()
         #expect(finalCount == 0)
     }
 }
 */
