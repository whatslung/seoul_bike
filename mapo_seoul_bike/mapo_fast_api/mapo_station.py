from fastapi import FastAPI
from pydantic import BaseModel
import joblib
import numpy as np
import os
from datetime import datetime
from fastapi.middleware.cors import CORSMiddleware


from weather import get_weather_data

# 모델 경로 설정 및 로드
base_path = os.path.dirname(os.path.abspath(__file__))
model_path = os.path.join(base_path, "flaml_model_mapo2024.pkl")
model = joblib.load(model_path)

app = FastAPI()

# ✅ CORS 설정
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Flutter 웹 or 모바일일 경우 와일드카드 우선
    allow_credentials=True,
    allow_methods=["*"],  # 모든 HTTP 메서드 허용 (POST, OPTIONS 등)
    allow_headers=["*"],
)

# ✅ 시간별 가중치 사전 추가
hour_weights = {
    0: 1.19, 1: 1.17, 2: 1.17, 3: 1.14, 4: 1.04,
    5: 1.07, 6: 1.19, 7: 1.16, 8: 1.20, 9: 1.14,
    10: 1.16, 11: 1.12, 12: 1.09, 13: 1.08, 14: 1.08,
    15: 1.08, 16: 1.08, 17: 1.12, 18: 1.18, 19: 1.18,
    20: 1.15, 21: 1.16, 22: 1.09, 23: 1.18
}

class InputData(BaseModel):
    hour: int
    rack_count: int
    discomfort: float

@app.get("/weather")
def get_weather():
    try:
        data = get_weather_data()
        return {"status": "success", "data": data}
    except Exception as e:
        return {"status": "error", "message": str(e)}

@app.post("/predict")
def predict(data: InputData):
    now = datetime.now()

    # 휴일 여부
    is_holiday = 1 if now.weekday() >= 5 else 0

    # 시간대
    hour = data.hour
    if 7 <= hour <= 9:
        time_slot = 2
    elif 18 <= hour <= 21:
        time_slot = 3
    elif hour >= 22 or hour < 5:
        time_slot = 0
    else:
        time_slot = 1

    # 계절
    month = now.month
    if month in [12, 1, 2]:
        season = 0
    elif month in [3, 4, 5]:
        season = 1
    elif month in [6, 7, 8]:
        season = 2
    else:
        season = 3

    # 입력 벡터
    features = [data.rack_count, data.discomfort, is_holiday, time_slot, season]
    X = np.array(features).reshape(1, -1)

    # 예측값 계산
    y_pred = model.predict(X)[0]

    # ✅ 시간별 가중치 적용
    weight = hour_weights.get(data.hour, 1.0)
    adjusted_pred = max(y_pred * weight, 0)

    return {"prediction": adjusted_pred}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8000)