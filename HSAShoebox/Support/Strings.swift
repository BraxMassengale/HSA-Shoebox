import Foundation

enum Strings {
    enum App {
        static let title = "HSA Shoebox"
        static let receipts = "Receipts"
        static let settings = "Settings"
    }

    enum ReceiptList {
        static let scan = "Scan"
        static let createBundle = "Create Bundle"
        static let unreimbursedTotal = "Unreimbursed Total"
        static let searchPrompt = "Search merchant, notes, or category"
        static let all = "All"
        static let unreimbursed = "Unreimbursed"
        static let reimbursed = "Reimbursed"
        static let delete = "Delete"
        static let markReimbursed = "Mark Reimbursed"
        static let deleteConfirmationTitle = "Delete Receipt?"
        static let deleteConfirmationMessage = "This removes the receipt image, OCR text, and any reimbursement link."
        static let confirmDelete = "Delete Receipt"
        static let cancel = "Cancel"
        static let noReceiptsTitle = "Start Your Shoebox"
        static let noReceiptsMessage = "Scan your first receipt to build a future reimbursement archive."
        static let noUnreimbursedTitle = "Nothing Waiting"
        static let noUnreimbursedMessage = "Every saved receipt is already marked reimbursed."
        static let noSearchResultsTitle = "No Matches"
        static let noSearchResultsMessage = "Try a different merchant, note, or category."
    }

    enum Scan {
        static let processing = "Reading Receipt"
        static let processingMessage = "OCR runs in the background and pre-fills the details for review."
        static let unsupported = "Document scanning is not supported on this device."
        static let retry = "Scan Again"
        static let save = "Save Receipt"
        static let editTitle = "Edit Receipt"
        static let scanFailed = "Unable to process the scan."
    }

    enum ReceiptDetail {
        static let title = "Receipt"
        static let details = "Details"
        static let notes = "Notes"
        static let pages = "Pages"
        static let reimburse = "Mark Reimbursed"
        static let reimbursementBundle = "Reimbursement Bundle"
        static let save = "Save"
    }

    enum Bundle {
        static let composerTitle = "Create Bundle"
        static let bundleTitle = "Bundle"
        static let reimbursementDate = "Reimbursement Date"
        static let note = "Bundle Note"
        static let exportPDF = "Export PDF"
        static let save = "Create Bundle"
        static let total = "Bundle Total"
        static let receipts = "Included Receipts"
    }

    enum Settings {
        static let title = "Settings"
        static let syncStatus = "iCloud Sync"
        static let syncAvailable = "Connected to private iCloud sync"
        static let syncNoAccount = "Sign in to iCloud to sync receipts"
        static let syncRestricted = "iCloud access is restricted"
        static let syncTemporarilyUnavailable = "iCloud is temporarily unavailable"
        static let syncUnknown = "Unable to determine iCloud status"
        static let defaultCurrency = "Default Currency"
        static let defaultCategory = "Default Category"
        static let exportAllData = "Export All Data"
        static let about = "About"
        static let privacy = "All data is stored on your device and your private iCloud. No analytics, no network calls beyond iCloud sync."
        static let exportInProgress = "Preparing export..."
    }

    enum Form {
        static let merchant = "Merchant"
        static let dateOfService = "Date of Service"
        static let amount = "Amount"
        static let currency = "Currency"
        static let category = "Category"
        static let paymentMethod = "Payment Method"
        static let notes = "Notes"
    }
}
