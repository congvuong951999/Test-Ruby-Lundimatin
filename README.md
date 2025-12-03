# Lundimatin Contact Management Application

## Requirements

- **Ruby**: 3.3.0+
- **Rails**: 8.1.1
- **Bundler**: Latest version

## Installation & Run

```bash
cd /home/pc/Test-ruby-lundimatin
bundle install
rails server
```

## Access Application

Truy cập ứng dụng tại: **http://localhost:3000**

## Login Credentials

- **Username**: `test_api`
- **Password**: `api123456`

## Features

### 🔍 Search (Tìm kiếm)
- Tìm kiếm contact theo nhiều trường: tên, địa chỉ, thành phố, điện thoại, email, mã bưu điện
- Tìm kiếm real-time khi nhập từ khóa
- Hiển thị kết quả trong bảng với avatar, thông tin cơ bản

### 👁️ Show (Xem chi tiết)
- Xem đầy đủ thông tin contact: tên, điện thoại, email, địa chỉ, mã bưu điện, thành phố
- Giao diện hiển thị rõ ràng với layout 2 cột
- Nút "Editer" để chuyển sang chế độ chỉnh sửa

### ✏️ Edit (Chỉnh sửa)
- Chỉnh sửa thông tin contact
- Validation phía Frontend và Backend:
  - **Téléphone**: Chỉ được nhập số
  - **Code postal**: Chỉ được nhập số
  - **Email**: Phải có ký tự @
- Lưu thay đổi và quay lại trang chi tiết

### 🚪 Logout (Đăng xuất)
- Đăng xuất khỏi hệ thống
- Xóa session và token
- Chuyển hướng về trang login
