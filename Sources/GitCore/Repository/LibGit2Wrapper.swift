//
// LibGit2Wrapper.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-12.
//

import Foundation

// TODO: Re-enable when SwiftGit2 SPM support is stable
// import SwiftGit2
import Utilities

// TODO: Re-enable when SwiftGit2 SPM support is stable
/*
 /// Low-level wrapper for libgit2 operations
 /// This class provides thread-safe operations for Git repositories
 public class LibGit2Wrapper {
     private let logger = Logger(category: "LibGit2Wrapper")

     public init() {}

     // MARK: - Staging Operations

     /// Stages a file to the index
     public func stageFile(in repository: Repository, path: String) throws {
         let index = try repository.index()
         try index.add(path: path)
         try index.write()
     }

     /// Stages all files to the index
     public func stageAllFiles(in repository: Repository) throws {
         let index = try repository.index()
         let status = try repository.status()

         for entry in status {
             if entry.status.contains(.workTreeNew) ||
                entry.status.contains(.workTreeModified) ||
                entry.status.contains(.workTreeDeleted) {
                 if entry.status.contains(.workTreeDeleted) {
                     try index.remove(path: entry.path)
                 } else {
                     try index.add(path: entry.path)
                 }
             }
         }

         try index.write()
     }

     /// Unstages a file from the index
     public func unstageFile(in repository: Repository, path: String) throws {
         guard let head = try? repository.HEAD().commit() else {
             // No HEAD commit, just remove from index
             let index = try repository.index()
             try index.remove(path: path)
             try index.write()
             return
         }

         // Reset the file to HEAD state
         try repository.reset(head, paths: [path])
     }

     /// Unstages all files from the index
     public func unstageAllFiles(in repository: Repository) throws {
         guard let head = try? repository.HEAD().commit() else {
             // No HEAD commit, clear the index
             let index = try repository.index()
             try index.removeAll()
             try index.write()
             return
         }

         // Reset index to HEAD
         try repository.reset(head, mode: .mixed)
     }

     // MARK: - Commit Operations

     /// Creates a commit with the current index
     public func createCommit(in repository: Repository, message: String, author: String?) throws -> OID {
         let index = try repository.index()
         let treeOid = try index.writeTree()
         let tree = try repository.tree(treeOid)

         // Get signature
         let signature: Signature
         if let authorString = author {
             // Parse author string format: "Name <email>"
             let components = authorString.split(separator: "<")
             if components.count == 2 {
                 let name = components[0].trimmingCharacters(in: .whitespaces)
                 let email = components[1]
                     .trimmingCharacters(in: .whitespaces)
                     .replacingOccurrences(of: ">", with: "")
                 signature = try Signature(name: name, email: email)
             } else {
                 signature = try repository.defaultSignature()
             }
         } else {
             signature = try repository.defaultSignature()
         }

         // Get parent commits
         var parents: [Commit] = []
         if let head = try? repository.HEAD().commit() {
             parents.append(head)
         }

         // Create commit
         let commitOid = try repository.createCommit(
             tree: tree,
             parents: parents,
             message: message,
             signature: signature
         )

         // Update HEAD
         try repository.setHEAD(commitOid)

         return commitOid
     }

     /// Amends the last commit
     public func amendCommit(in repository: Repository, message: String?) throws -> OID {
         guard let headCommit = try? repository.HEAD().commit() else {
             throw GitError.libgit2Error("No HEAD commit to amend")
         }

         // Get current index tree
         let index = try repository.index()
         let treeOid = try index.writeTree()
         let tree = try repository.tree(treeOid)

         // Use existing message if not provided
         let commitMessage = message ?? headCommit.message

         // Get signature
         let signature = try repository.defaultSignature()

         // Get parent commits of HEAD
         let parents = headCommit.parents

         // Create amended commit
         let commitOid = try repository.createCommit(
             tree: tree,
             parents: Array(parents),
             message: commitMessage,
             signature: signature
         )

         // Update HEAD
         try repository.setHEAD(commitOid)

         return commitOid
     }

     /// Gets commit history
     public func getCommitHistory(in repository: Repository, limit: Int, branch: String?) throws -> [Commit] {
         let revwalk = try repository.createRevisionWalker()

         // Set starting point
         if let branchName = branch {
             let branches = try repository.localBranches()
             guard let branch = branches.first(where: { $0.shortName == branchName }) else {
                 throw GitError.libgit2Error("Branch '\(branchName)' not found")
             }
             try revwalk.push(branch.oid)
         } else {
             // Start from HEAD
             if let head = try? repository.HEAD() {
                 try revwalk.push(head.oid)
             }
         }

         // Collect commits
         var commits: [Commit] = []
         var count = 0

         for oid in revwalk {
             if count >= limit { break }
             if let commit = try? repository.commit(oid) {
                 commits.append(commit)
                 count += 1
             }
         }

         return commits
     }

     // MARK: - Diff Operations

     /// Gets diff for a file or the entire repository
     public func getDiff(in repository: Repository, filePath: String?, staged: Bool) throws -> String {
         let diff: Diff

         if staged {
             // Diff between HEAD and index
             if let head = try? repository.HEAD().commit() {
                 let headTree = try head.tree()
                 diff = try repository.diff(tree: headTree, toIndex: true)
             } else {
                 // No HEAD, diff against empty tree
                 diff = try repository.diff(tree: nil, toIndex: true)
             }
         } else {
             // Diff between index and working directory
             diff = try repository.diff(index: true, toWorkdir: true)
         }

         // Filter by file path if specified
         if let path = filePath {
             let patches = try diff.patches()
             guard let patch = patches.first(where: { $0.delta.newFile.path == path }) else {
                 return ""
             }
             return try patch.text()
         }

         // Return full diff
         return try diff.patches().map { try $0.text() }.joined(separator: "\n")
     }

     // MARK: - Remote Operations

     /// Fetches from a remote
     public func fetch(in repository: Repository, remote remoteName: String) throws {
         guard let remote = try repository.remote(named: remoteName) else {
             throw GitError.libgit2Error("Remote '\(remoteName)' not found")
         }

         try remote.fetch()
     }

     /// Pulls changes from a remote
     public func pull(in repository: Repository, remote remoteName: String, branch: String?) throws {
         // First fetch
         try fetch(in: repository, remote: remoteName)

         // Get current branch
         let head = try repository.HEAD()
         guard let currentBranch = head.shortName else {
             throw GitError.libgit2Error("Not on a branch")
         }

         // Determine remote branch
         let remoteBranch = branch ?? currentBranch
         let remoteRef = "\(remoteName)/\(remoteBranch)"

         // Find remote branch
         let remoteBranches = try repository.remoteBranches()
         guard let remote = remoteBranches.first(where: { $0.name == "refs/remotes/\(remoteRef)" }) else {
             throw GitError.libgit2Error("Remote branch '\(remoteRef)' not found")
         }

         // Merge remote branch
         let remoteCommit = try remote.commit()
         let headCommit = try head.commit()

         // Check if fast-forward is possible
         if try repository.isDescendant(of: headCommit.oid, ancestor: remoteCommit.oid) {
             // Fast-forward
             try repository.setHEAD(remoteCommit.oid)
             try repository.checkout(strategy: .force)
         } else {
             // Need to merge
             let index = try repository.merge(remoteCommit, into: headCommit)

             if index.hasConflicts() {
                 throw GitError.libgit2Error("Merge conflicts detected")
             }

             // Write merged tree
             let treeOid = try index.writeTree()
             let tree = try repository.tree(treeOid)

             // Create merge commit
             let signature = try repository.defaultSignature()
             let message = "Merge branch '\(remoteRef)' into \(currentBranch)"

             let commitOid = try repository.createCommit(
                 tree: tree,
                 parents: [headCommit, remoteCommit],
                 message: message,
                 signature: signature
             )

             try repository.setHEAD(commitOid)
             try repository.checkout(strategy: .force)
         }
     }

     /// Pushes to a remote
     public func push(in repository: Repository, remote remoteName: String, branch: String?, setUpstream: Bool) throws {
         guard let remote = try repository.remote(named: remoteName) else {
             throw GitError.libgit2Error("Remote '\(remoteName)' not found")
         }

         // Determine branch to push
         let branchToPush: String
         if let branch = branch {
             branchToPush = branch
         } else {
             let head = try repository.HEAD()
             guard let currentBranch = head.shortName else {
                 throw GitError.libgit2Error("Not on a branch")
             }
             branchToPush = currentBranch
         }

         // Push
         let refspec = "refs/heads/\(branchToPush):refs/heads/\(branchToPush)"
         try remote.push([refspec])

         // Set upstream if requested
         if setUpstream {
             let branches = try repository.localBranches()
             if let branch = branches.first(where: { $0.shortName == branchToPush }) {
                 try branch.setUpstream(remote: remoteName, remoteBranch: branchToPush)
             }
         }
     }
 }
 */
