# 1. Tính năng Sharing Bills (Chia tiền / Bù trừ công nợ)
## 1.1. Khảo sát thị trường (Splitwise)
- **Cách hoạt động:** Cho phép tạo nhóm, thêm chi phí với các tùy chọn chia đều (split equally), chia theo phần trăm, chia theo số tiền cụ thể hoặc số phần (shares).
- **Tính năng tham khảo:** Thuật toán Simplify Debts. Ví dụ: A nợ B $100, B nợ C $100 -> App sẽ tính toán để A trả thẳng cho C $100. UX nhập liệu rất mượt và hỗ trợ đa tiền tệ.
## 1.2. Triển khai thực tế trong project
- **File thực thi chính:** `lib/services/expense_calculator.dart`.
- **Thuật toán Simplify Debts (Rút gọn công nợ bằng Đồ thị có hướng - Directed Graph):**
  - App đã áp dụng thuật toán **Tham lam (Greedy Algorithm)** để tính toán lại toàn bộ dòng tiền của các thành viên.
  - **Cách hoạt động:** 
    1. Đầu tiên, tính Net Balance (Số dư ròng) cho từng người (Lấy tổng tiền đã trả hộ trừ đi tổng tiền bản thân đã tiêu). Ai có số dư dương (>0) là chủ nợ (Creditor), ai âm (<0) là con nợ (Debtor).
    2. Sau đó, thuật toán phân loại thành 2 danh sách và sắp xếp ưu tiên từ số tiền lớn nhất đến nhỏ nhất.
    3. Thực hiện vòng lặp bù trừ (Matching): Lấy người nợ nhiều nhất trả trực tiếp cho người chủ nợ lớn nhất cho đến khi tất cả số dư về 0.
  - **Kết quả:** Thay vì hiển thị A nợ B, B nợ C phức tạp, hệ thống rút gọn thành các giao dịch thanh toán đơn giản nhất (ví dụ "A nợ C"), hiển thị trực quan tại tab Split.
# 3. User Workflow (Hành trình trải nghiệm của người dùng)

Để giúp mọi người (kể cả những người không hiểu về kỹ thuật) dễ hình dung, dưới đây là luồng sử dụng thực tế của một người dùng tên là **"Minh"** khi sử dụng ứng dụng Trip Planner để lên kế hoạch đi chơi cùng nhóm bạn:

## Bước 1: Tạo chuyến đi (Khởi tạo)
- Minh mở app và bấm tạo một chuyến đi mới: **"Hành trình khám phá Nhật Bản 5 ngày 4 đêm"**.
- App sẽ tạo ra một không gian làm việc (Dashboard) riêng cho chuyến đi này.

## Bước 2: Chuẩn bị trước chuyến đi (Pre-trip Preparation)
- **Checklist & Giấy tờ:** Minh sử dụng tính năng **Note & Checklist** để tạo danh sách các việc cần làm (xin Visa, mua sim 4G). Minh tải ảnh Visa và vé máy bay lên app để có thể **xem offline** (không cần mạng) khi đến sân bay.
- **Lưu trữ thông tin cốt lõi:** Minh nhập thông tin Chuyến bay (Flights) và Khách sạn (Accommodations).

## Bước 3: Lên lịch trình từng ngày (Itinerary Planning & Map)
- Minh bắt đầu thêm các địa điểm vui chơi vào từng ngày (Ngày 1 đi đâu, Ngày 2 đi đâu).
- Thay vì phải tự mò mẫm xem đi điểm nào trước, điểm nào sau cho đỡ ngược đường, Minh chỉ cần bấm nút trên tab **Map (Bản đồ)**. App sẽ **tự động sắp xếp lại thứ tự các địa điểm** (Route Optimization) để Minh có một lộ trình di chuyển tối ưu nhất và nối thành một đường đi rõ ràng trên bản đồ.

## Bước 4: Trong chuyến đi (In-trip Quản lý chi tiêu)
- Nhóm bạn bắt đầu đi chơi. Xuyên suốt chuyến đi, cứ mỗi khi ai đó trả tiền, Minh lại ghi vào tab **Expenses (Chi phí)**.
- Ví dụ: "Minh trả tiền ăn trưa $50 cho cả nhóm", "Hương trả tiền vé tàu $20", "Lan tự trả tiền mua sắm riêng $30".
- Minh nhập rất nhanh với các tùy chọn ai là người trả (`paid_by`) và chia cho những ai (`split_between`).

## Bước 5: Kết thúc chuyến đi (Chia tiền & Chia sẻ)
- **Rút gọn công nợ (Simplify Debts):** Cuối chuyến đi, thay vì ngồi tính xem "Minh nợ Hương bao nhiêu, Hương nợ Lan bao nhiêu", Minh mở tab **Split**. App lập tức tính toán bù trừ chéo và hiển thị kết quả cực kỳ đơn giản: *"Hương chỉ cần chuyển cho Minh $10 là xong"*.
- **Lan tỏa cộng đồng (Share as Template):** Minh cảm thấy lịch trình này quá hoàn hảo nên quyết định bấm **Share Trip**. App tạo ra một đường link. Bất kỳ ai nhận được link này đều có thể bấm **"Clone"** để copy toàn bộ lịch trình, checklist, địa điểm của Minh về máy họ để làm mẫu cho chuyến đi của chính họ.
---
# 2. Tính năng Route Optimization & Group Location (Tối ưu lộ trình & Bản đồ)
## 2.1. Khảo sát thị trường (Wanderlog)
- **Đặc trưng:** Tính năng này yêu cầu sự trực quan cao trên bản đồ và thuật toán sắp xếp các điểm đến (bài toán Người chào hàng - TSP).
- **Cách hoạt động:** Nhập các địa điểm muốn đi, app tự động hiển thị chúng trên bản đồ.
- **Tính năng tham khảo (Route Optimization):** Nút "Optimize Route". Wanderlog sẽ tính toán khoảng cách thực tế giữa các điểm và tự động sắp xếp lại thứ tự trong ngày để có quãng đường đi ngắn nhất, kèm theo thời gian di chuyển.
## 2.2. Triển khai thực tế trong project
- **File thực thi chính:** `lib/services/route_optimizer.dart` và `lib/services/mapbox_service.dart`.
- **Thuật toán tham lam "Láng giềng gần nhất" (Nearest-Neighbor Heuristic) cho bài toán TSP:**
  - **Cách hoạt động:** Thay vì quét toàn bộ các cấu hình đường đi (tốn rất nhiều tài nguyên), hệ thống ưu tiên chọn điểm bắt đầu dựa trên thời gian (earliest `startTime`). Sau đó liên tục quét các điểm còn lại để tìm điểm gần nhất và nối vào lộ trình.
- **Công thức tính khoảng cách Haversine:**
  - Hệ thống tự tính toán khoảng cách "đường chim bay" trực tiếp trên máy (Offline) thông qua công thức lượng giác Haversine (tính độ cong bề mặt trái đất), giúp tìm ra các điểm gần nhất cực nhanh mà không cần gọi API.
- **Thuật toán Gom cụm (Clustering - Key Stops):**
  - Tự động tính toán khoảng cách trung vị (median) của toàn bộ điểm đến để tạo ra một bán kính gom nhóm (`autoRadiusKm`). Các địa điểm quá gần nhau sẽ được gom thành một cụm quanh điểm chính (Key stop) để bản đồ không bị rối mắt.
- **Vẽ đường thực tế (Mapbox Directions API):**
  - Sau khi sắp xếp được lộ trình chuẩn, ứng dụng dùng Mapbox API để tạo ra đường dẫn thực tế (polyline road). App cũng xử lý chia nhỏ các mảng dữ liệu (chunking) do giới hạn 25 waypoints trên mỗi request của Mapbox.

