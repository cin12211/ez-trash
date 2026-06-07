# Báo cáo Phân tích Lỗi: Ứng dụng tải từ App Store không thể xóa vĩnh viễn (Vẫn hiển thị sau khi Refresh)

## 1. Hiện tượng (Symptom)
Khi thực hiện gỡ cài đặt một số ứng dụng (đặc biệt là các ứng dụng được tải về từ Mac App Store như Xcode, Slack, Telegram, hoặc các app có Widget/Helper đi kèm):
* Tiến trình xóa trong EzTrash thông báo thành công và xóa app khỏi danh sách tạm thời.
* Tuy nhiên, khi người dùng nhấn nút **Refresh** (Làm mới), ứng dụng đó lại xuất hiện trở lại trong danh sách.
* Kiểm tra trong thư mục `/Applications`, tệp tin `.app` vẫn tồn tại và chưa bị di chuyển vào Thùng rác.

---

## 2. Nguyên nhân gốc rễ (Root Causes)

Sau khi kiểm tra cơ chế quét và xóa trong mã nguồn, có 3 nguyên nhân chính dẫn đến hiện tượng này:

### Nguyên nhân 1: Xử lý lỗi im lặng trong luồng xóa (Silent Failure)
Trong `ContentView.swift` (từ dòng 582 đến 589), khi thực hiện xóa (recycle) các tệp tin:
```swift
NSWorkspace.shared.recycle([url]) { (newURLs, error) in
    if let error = error {
        print("Recycle failed for \(url.path): \(error.localizedDescription)")
    }
    currentIndex += 1
    deleteNext()
}
```
* **Vấn đề**: Khi hàm `recycle` thất bại (ví dụ do phân quyền hoặc tệp bị khóa), ứng dụng chỉ in ra log lỗi trong Xcode Console (`print`) chứ **không chặn luồng xóa** hoặc thông báo cho người dùng biết. 
* Ứng dụng vẫn tiếp tục tăng `currentIndex` và chuyển sang trạng thái "Completed", đồng thời xóa ứng dụng đó khỏi bộ nhớ RAM (`scanner.apps.removeAll`). Vì vậy, người dùng tưởng rằng đã xóa thành công, nhưng thực tế file vẫn nằm nguyên trên ổ đĩa.

### Nguyên nhân 2: Khóa tiến trình bởi các ứng dụng con (Helper/Widget/Daemon Lock)
Mã nguồn hiện tại chỉ thực hiện tắt tiến trình chính của ứng dụng:
```swift
if runningApp.bundleIdentifier == app.bundleIdentifier || runningApp.bundleIdentifier == app.id.lastPathComponent
```
* **Vấn đề**: Nhiều ứng dụng App Store cài đặt thêm các tiến trình chạy ngầm như:
  * **Widget Extensions** (ví dụ: `com.company.app.widget`)
  * **Launch Agents / Helpers** (ví dụ: `com.company.app.helper`)
  * **Finder Extensions** (ví dụ: tích hợp menu chuột phải của Telegram/Dropbox)
* Khi các tiến trình con này đang hoạt động, macOS sẽ khóa cứng (lock) toàn bộ thư mục `.app`. Trình quản lý hệ thống sẽ từ chối yêu cầu di chuyển thư mục này vào Thùng rác từ hàm `NSWorkspace.shared.recycle` và trả về lỗi **"Device busy"** hoặc **"Permission denied"**.

### Nguyên nhân 3: Cơ chế bảo mật Sandbox & Quyền sở hữu (Permissions & Owner)
* Các ứng dụng từ Mac App Store được cài đặt bởi tài khoản hệ thống (`root` hoặc `_installer`) và được quản lý/ký số chặt chẽ bởi tiến trình daemon **`appstored`** của macOS.
* Quyền ghi/xóa đối với các thư mục này yêu cầu quyền quản trị viên cao hơn thông thường. Do EzTrash chạy dưới quyền người dùng hiện tại (User space), lệnh gọi `NSWorkspace.shared.recycle` trực tiếp qua API đôi khi sẽ bị chặn bởi cơ chế Sandbox/Quarantine của macOS nếu không thông qua tương tác Finder.

---

## 3. Các giải pháp đề xuất (Proposed Solutions)

Để khắc phục triệt để lỗi này trong tương lai, dưới đây là các phương án cải tiến kiến trúc mã nguồn (không can thiệp code trực tiếp lúc này):

### Giải pháp A: Kiểm tra và thông báo lỗi rõ ràng (Error Reporting)
* **Cách làm**: Sửa luồng xóa để tích lũy các lỗi xảy ra trong quá trình `recycle`. Nếu có bất kỳ tệp tin nào (đặc biệt là tệp `.app` chính) bị lỗi, không xóa ứng dụng đó ra khỏi RAM và hiển thị một hộp thoại cảnh báo (Alert) chi tiết lý do thất bại cho người dùng.

### Giải pháp B: Tắt toàn bộ các tiến trình liên quan (Subprocess Termination)
* **Cách làm**: Thay vì chỉ tìm kiếm tiến trình có chính xác `bundleIdentifier` của app chính, hãy quét và tắt tất cả các tiến trình chạy ngầm có chứa ID con hoặc có đường dẫn thực thi (Executable Path) nằm bên trong thư mục `.app` đó trước khi thực hiện xóa.
```swift
// Gợi ý logic tắt tiến trình con:
let appPath = app.id.path
let runningApps = NSWorkspace.shared.runningApplications
for runningApp in runningApps {
    if let execURL = runningApp.executableURL, execURL.path.hasPrefix(appPath) {
        runningApp.forceTerminate()
    }
}
```

### Giải pháp C: Sử dụng AppleScript để ủy quyền cho Finder xóa (Finder Delegation)
* **Cách làm**: Đối với các ứng dụng bị từ chối xóa bằng `NSWorkspace.shared.recycle`, ứng dụng có thể chuyển sang gọi một đoạn mã AppleScript chạy lệnh bảo mật thông qua **Finder**. 
* Cách này tận dụng cơ chế hệ thống của macOS: Finder sẽ tự động hiển thị hộp thoại yêu cầu người dùng nhập mật khẩu quản trị viên (hoặc Touch ID) để cấp quyền xóa file hệ thống/App Store một cách chính thống và an toàn.
```applescript
tell application "Finder"
    move POSIX file "/Applications/StubbornApp.app" to trash
end tell
```

---

## 4. Kiểm tra quyền sở hữu (Root Owner) và Phương pháp nâng quyền trên macOS

### A. Cách xác định ứng dụng thuộc quyền sở hữu của `root` (UID = 0)
Trong Swift, chúng ta có thể kiểm tra trực tiếp các thuộc tính POSIX của file ứng dụng trên ổ đĩa để biết app đó có phải do hệ thống/root cài đặt hay không.
```swift
func isAppOwnedByRoot(appURL: URL) -> Bool {
    let path = appURL.path
    guard let attributes = try? FileManager.default.attributesOfItem(atPath: path) else {
        return false
    }
    
    // 1. Kiểm tra qua UID (Root ID luôn luôn là 0)
    if let ownerID = attributes[.ownerAccountID] as? NSNumber {
        if ownerID.intValue == 0 {
            return true
        }
    }
    
    // 2. Kiểm tra qua tên tài khoản sở hữu (root)
    if let ownerName = attributes[.ownerAccountName] as? String {
        if ownerName == "root" {
            return true
        }
    }
    
    return false
}
```
* **Ứng dụng**: Khi người dùng chọn ứng dụng, ta chạy hàm kiểm tra này trước. Nếu trả về `true`, ta có thể chủ động thông báo cho người dùng biết ứng dụng này thuộc hệ thống/App Store và yêu cầu xác thực nâng quyền khi xóa.

### B. Các cơ chế nâng quyền cao hơn (Privilege Escalation) trên macOS

Để thực hiện xóa một ứng dụng có quyền sở hữu bởi `root`, ứng dụng cần nâng quyền thực thi lên quản trị viên (Administrator / Root privileges). Có 3 cách tiếp cận phổ biến:

| Phương pháp | Cách thức hoạt động | Ưu điểm | Nhược điểm |
| :--- | :--- | :--- | :--- |
| **1. AppleScript `with administrator privileges`** | Thực thi trực tiếp lệnh shell xóa (`rm -rf`) dưới quyền root thông qua AppleScript. | Dễ viết, hệ thống tự hiển thị popup yêu cầu mật khẩu bảo mật của macOS. | Mỗi lần gọi lệnh sẽ hiện popup nhập mật khẩu, và lệnh xóa này là vĩnh viễn (không qua Thùng rác). |
| **2. Finder Delegation (Khuyên dùng)** | Sử dụng AppleScript gửi thông điệp yêu cầu ứng dụng **Finder** di chuyển app vào Thùng rác. | An toàn tối đa, ứng dụng vẫn đi vào Thùng rác. Finder sẽ tự động đứng ra hiển thị Touch ID/Password để nâng quyền. | Phụ thuộc vào phản hồi từ Finder thông qua AppleScript. |
| **3. Privileged Helper Tool (Chuyên nghiệp)** | Đóng gói một công cụ con (Helper Daemon) và cài đặt nó vào `/Library/PrivilegedHelperTools` sử dụng API `SMJobBless`. Helper này sẽ chạy thường trực với quyền root. | Chuyên nghiệp nhất (như CleanMyMac), giao tiếp bảo mật qua XPC, quản lý luồng tốt. | Cực kỳ phức tạp để phát triển; bắt buộc phải ký số (Codesign) bằng tài khoản Apple Developer trả phí của doanh nghiệp mới chạy được. |

