from pymongo import MongoClient

# 인증 정보가 포함된 연결 URI (사용자명, 비밀번호, 인증 DB 지정)
# 예시: mongodb://admin:비밀번호@localhost:27017/?authSource=admin
#MONGO_URI 보안상 이유로 표시 제한


client = MongoClient(MONGO_URI)
db = client["dr_project_db"]
collection = db["app_logs"]

dummy_data = [
    {
        "_id": "doc_0010",
        "user_id": "user_1014",
        "action": "error_occurred",
        "status": "FAILED",
        "details": {"ip_address": "192.168.1.138", "latency_ms": 332, "browser": "Firefox"},
        "created_at": "2026-10-20T14:36:00+09:00"
    },
    {
        "_id": "doc_0020",
        "user_id": "user_1015",
        "action": "view_dashboard",
        "status": "FAILED",
        "details": {"ip_address": "192.168.1.136", "latency_ms": 281, "browser": "Edge"},
        "created_at": "2026-10-20T14:36:00+09:01"
    }
]

try:
    result = collection.insert_many(dummy_data, ordered=False)
    print(f"성공적으로 {len(result.inserted_ids)}개의 더미 데이터가 MongoDB에 삽입되었습니다.")
except Exception as e:
    print(f"삽입 결과 (중복 등 예외 무시 가능): {e}")
