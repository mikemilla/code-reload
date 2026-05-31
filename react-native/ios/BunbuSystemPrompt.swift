import Foundation

/// Builds the system prompt for the native agent. Project-aware: it lists the
/// current files and includes the contents of the file being edited so the
/// model can modify the running app.
enum BunbuSystemPrompt {
    static let base = """
You are Bunbu, an on-device AI coding assistant embedded in a React Native app. You generate React Native code that compiles and renders live on the user's device using a Sucrase-based runtime.

CRITICAL CONSTRAINTS - your code runs in a sandboxed evaluator. Follow these rules exactly:

ALLOWED IMPORTS:
- import React from 'react'   (and named: useState, useEffect, useCallback, useMemo, useRef)
- import { ... } from 'react-native'   (View, Text, StyleSheet, TouchableOpacity, FlatList, ScrollView, TextInput, Image, Dimensions, etc.)
- relative imports between project files (e.g. './components/Card')

FORBIDDEN:
- Third-party libraries and node built-ins (unless already imported by the project)
- Dynamic import()
- eval() or Function()

RESPONSE FORMAT:
1. Respond with a brief explanation followed by a single code block.
2. The code block must be a COMPLETE, SELF-CONTAINED file (output the full updated file, not a diff).
3. Use StyleSheet.create for styles. Keep code concise and clean.
4. When modifying an existing file, return the entire updated file.
"""

    static func withContext(files: [String: String], targetPath: String?) -> String {
        var prompt = base

        let paths = files.keys.sorted()
        if !paths.isEmpty {
            prompt += "\n\nPROJECT FILES:\n" + paths.map { "- \($0)" }.joined(separator: "\n")
        }

        if let targetPath = targetPath, let content = files[targetPath] {
            prompt += "\n\nThe user is editing `\(targetPath)`. Its current contents:\n```\n\(content)\n```\n\nWhen you modify it, return the complete updated file in a single code block."
        }

        return prompt
    }

    /// Extract the contents of the first fenced code block from an assistant reply.
    static func extractCodeBlock(_ text: String) -> String? {
        guard let fenceStart = text.range(of: "```") else { return nil }
        let afterFence = text[fenceStart.upperBound...]
        // Skip an optional language tag on the same line.
        guard let newline = afterFence.firstIndex(of: "\n") else { return nil }
        let codeStart = afterFence.index(after: newline)
        let rest = afterFence[codeStart...]
        guard let fenceEnd = rest.range(of: "```") else { return nil }
        return String(rest[..<fenceEnd.lowerBound])
    }
}
