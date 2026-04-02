# MacToDo

A full-featured task manager for iOS and macOS, built with SwiftUI. Data syncs to Azure Blob Storage.

## Architecture

```
MacTodoCore/     Shared Swift package (Models, Storage, ViewModels)
MacTodoiOS/      iOS app shell (TabView navigation)
MacTodoMac/      macOS app shell (NavigationSplitView)
Scripts/         Build-time credential generation
```

**Zero external dependencies.** Uses Foundation, CryptoKit, and SwiftUI only.

## Setup

### 1. Azure Blob Storage

Create an Azure Storage account and a blob container (e.g., `mactodo`).

### 2. Credentials

Copy the env example and fill in your values:

```bash
cp Scripts/.env.example .env
# Edit .env with your Azure credentials
```

Set environment variables before building:

```bash
export AZURE_STORAGE_ACCOUNT=your_account_name
export AZURE_STORAGE_KEY=your_base64_key
export AZURE_CONTAINER_NAME=mactodo
```

The `Scripts/generate-config.sh` build phase reads these and generates `GeneratedConfig.swift` (gitignored).

### 3. Build the shared package

```bash
cd MacTodoCore
swift build
swift test
```

### 4. Open in Xcode

Open `MacTodoiOS/` or `MacTodoMac/` in Xcode. Each project depends on `MacTodoCore` via a local SPM reference. Add the Run Script build phase pointing to `Scripts/generate-config.sh` and set your Azure env vars in the Xcode scheme.

## Features

- Projects with colors and SF Symbol icons
- Priority levels (none/low/medium/high/urgent)
- Recurring tasks (daily/weekly/monthly/yearly)
- Reminders (absolute or relative to due date)
- Subtasks
- Tags and filtering
- Search
- Collaborators
- Azure Blob Storage sync with offline-first local cache
- Last-writer-wins conflict resolution

## Platforms

- iOS 17+
- macOS 14+
- Swift 6.0+
