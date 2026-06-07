//
//  AppLanguage.swift
//  EzTrash
//

import Foundation

enum AppLanguage: String, CaseIterable {
    case english = "en"
    case vietnamese = "vi"
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .vietnamese: return "Tiếng Việt"
        }
    }
    
    var shortName: String {
        switch self {
        case .english: return "EN"
        case .vietnamese: return "VI"
        }
    }
    
    func localize(_ key: String, arg: String = "") -> String {
        switch self {
        case .english:
            switch key {
            case "search_prompt": return "Search apps..."
            case "scanning": return "Scanning Applications folder..."
            case "no_apps": return "No applications found"
            case "apps_found": return "apps found"
            case "refresh_help": return "Refresh list of applications"
            case "sidebar_title": return "Applications"
            case "empty_title": return "No Application Selected"
            case "empty_desc": return "Select one or more applications from the sidebar to scan for associated files and uninstall."
            case "apps_selected": return "\(arg) Applications Selected"
            case "app_bundle": return "Application Bundle"
            case "associated_files": return "Associated Files & Folders (\(arg))"
            case "no_associated": return "No associated files found"
            case "total_selected": return "Total selected to delete:"
            case "move_to_trash_single": return "Move to Trash"
            case "move_to_trash_multi": return "Move \(arg) Apps to Trash"
            case "auth_failed": return "Authentication Failed"
            case "confirm_title": return "Confirm Uninstallation"
            case "confirm_desc": return "Are you sure you want to move the selected applications and their associated files to the Trash?"
            case "cancel": return "Cancel"
            case "auth_delete": return "Delete"
            case "init_uninstall": return "Initializing uninstallation..."
            case "trashing": return "Trashing: \(arg)"
            case "moved_to_trash": return "Moved to Trash"
            case "moved_to_trash_desc": return "Successfully cleaned and moved selected applications and their associated files to the Trash."
            case "done": return "Done"
            case "auth_reason": return "Confirm trashing of \(arg) and associated files."
            case "system_app_warning": return "System/App Store apps cannot be deleted"
            case "user_apps_section": return "User Applications"
            case "system_apps_section": return "System / App Store"
            case "support_me_help": return "Buy me a coffee"
            case "share_help": return "Share this app"
            case "share_title": return "Share EzTrash"
            case "share_desc": return "Copy the link below to share with your friends!"
            case "copy": return "Copy"
            case "copied": return "Copied!"
            case "last_opened": return "Last opened"
            case "sort_by_name": return "Name"
            case "sort_by_last_opened": return "Last Opened"
            case "sort_help": return "Sort Options"
            case "sort_label": return "Sort by"
            default: return key
            }
        case .vietnamese:
            switch key {
            case "search_prompt": return "Tìm ứng dụng..."
            case "scanning": return "Đang quét thư mục Ứng dụng..."
            case "no_apps": return "Không tìm thấy ứng dụng"
            case "apps_found": return "ứng dụng được tìm thấy"
            case "refresh_help": return "Làm mới danh sách ứng dụng"
            case "sidebar_title": return "Ứng dụng"
            case "empty_title": return "Chưa chọn ứng dụng"
            case "empty_desc": return "Chọn một hoặc nhiều ứng dụng từ thanh bên để quét các tệp liên quan và gỡ cài đặt."
            case "apps_selected": return "Đã chọn \(arg) ứng dụng"
            case "app_bundle": return "Bộ cài ứng dụng"
            case "associated_files": return "Tệp & Thư mục liên quan (\(arg))"
            case "no_associated": return "Không tìm thấy tệp liên quan"
            case "total_selected": return "Tổng dung lượng cần xoá:"
            case "move_to_trash_single": return "Di chuyển vào Thùng rác"
            case "move_to_trash_multi": return "Di chuyển \(arg) ứng dụng vào Thùng rác"
            case "auth_failed": return "Xác thực thất bại"
            case "confirm_title": return "Xác nhận gỡ cài đặt"
            case "confirm_desc": return "Bạn có chắc chắn muốn di chuyển các ứng dụng đã chọn và tệp liên quan vào Thùng rác?"
            case "cancel": return "Huỷ"
            case "auth_delete": return "Xoá"
            case "init_uninstall": return "Bắt đầu gỡ cài đặt..."
            case "trashing": return "Đang xoá: \(arg)"
            case "moved_to_trash": return "Đã di chuyển vào Thùng rác"
            case "moved_to_trash_desc": return "Đã dọn dẹp và di chuyển các ứng dụng cùng file liên quan vào Thùng rác thành công."
            case "done": return "Hoàn tất"
            case "auth_reason": return "Xác nhận di chuyển \(arg) và các tệp liên quan vào Thùng rác."
            case "system_app_warning": return "Không thể gỡ ứng dụng hệ thống / App Store"
            case "user_apps_section": return "Ứng dụng Người dùng"
            case "system_apps_section": return "Hệ thống / App Store"
            case "support_me_help": return "Ủng hộ tôi (Buy me a coffee)"
            case "share_help": return "Chia sẻ ứng dụng"
            case "share_title": return "Chia sẻ EzTrash"
            case "share_desc": return "Sao chép liên kết dưới đây để chia sẻ với bạn bè!"
            case "copy": return "Sao chép"
            case "copied": return "Đã sao chép!"
            case "last_opened": return "Lần mở cuối"
            case "sort_by_name": return "Theo tên"
            case "sort_by_last_opened": return "Lần mở cuối"
            case "sort_help": return "Tuỳ chọn sắp xếp"
            case "sort_label": return "Sắp xếp theo"
            default: return key
            }
        }
    }
}
