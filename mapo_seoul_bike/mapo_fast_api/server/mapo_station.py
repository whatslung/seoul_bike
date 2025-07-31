from fastapi.staticfiles import StaticFiles
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import os
import pandas as pd
from motor.motor_asyncio import AsyncIOMotorClient
import joblib
import math
from datetime import datetime
import holidays

kr_holidays = holidays.KR()

def is_holiday(date_obj: datetime) -> bool:
    return date_obj in kr_holidays
app = FastAPI()

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MODEL_PATH = os.path.join(BASE_DIR, '../h5/클러스터3모델.h5')
DATA1_PATH = os.path.join(BASE_DIR, '../Data/마포버스정류장.csv')
DATA2_PATH = os.path.join(BASE_DIR, '../Data/지하철서울.csv')
DATA3_PATH = os.path.join(BASE_DIR, '../Data/학교서울.csv')
클러스터3 = joblib.load(MODEL_PATH)
bus_station = pd.read_csv(DATA1_PATH)
subway_station = pd.read_csv(DATA2_PATH)
seoul_school = pd.read_csv(DATA3_PATH)

# Flutter에서 빌드된 파일 제공
# app.mount('/', StaticFiles(directory='build/web', html=True), name='web')

MONGO_URI = "mongodb://localhost:27017"
client = AsyncIOMotorClient(MONGO_URI)
db = client.Data
station = db.station


class bikeFeature(BaseModel):
    날짜: datetime   
    기온: float
    강수량: float
    위도: float
    경도: float

class staion_info(BaseModel):
    역사명 : str
    호선 : str
    lat: float
    lng : float

# class PrediectInput(BaseModel):
#     #
def calculate_discomfort_index(temp_celsius, humidity_percent):
    return 0.81 * temp_celsius + 0.01 * humidity_percent * (0.99 * temp_celsius - 14.3) + 46.3

def haversine(lat1, lon1, lat2, lon2):
    R = 6371000  # 지구 반지름(m)
    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    delta_phi = math.radians(lat2 - lat1)
    delta_lambda = math.radians(lon2 - lon1)
    
    a = math.sin(delta_phi / 2)**2 + \
        math.cos(phi1) * math.cos(phi2) * math.sin(delta_lambda / 2)**2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return R * c

def find_nearest_station1(lat, lng, df):
    min_distance1 = float('inf')

    for _, st in df.iterrows():
        st_lat = st['위도']
        st_lng = st['경도']
        if pd.isna(st_lat) or pd.isna(st_lng):
            continue

        dist = haversine(lat, lng, st_lat, st_lng)

        if dist < min_distance1:
            min_distance1 = dist

    return min_distance1

@app.get("/stations")
async def get_stations():
    results = []
    cursor = station.find({})
    async for doc in cursor:
        # _id 제거 + 문자열 숫자 처리
        doc.pop("_id", None)
        results.append(staion_info(**{
            "역사명": doc.get("역사명"),
            "호선": doc.get("호선"),
            "lat": doc.get("위도", 0.0),
            "lng": doc.get("경도", 0.0),
        }))
    return results

@app.post("/sang_predict")
def predict(data: bikeFeature):
    try:
        dt = data.날짜
        요일 = dt.weekday()  # 0:월요일 ~ 6:일요일
        공휴일 = is_holiday(dt)  # True/False
        요일구분 = 요일 >= 5 or 공휴일  # 토/일/공휴일은 휴일로 간주
        # 거리 계산
        distance_to_bus = find_nearest_station1(data.위도, data.경도, bus_station)
        distance_to_subway = find_nearest_station1(data.위도, data.경도, subway_station)
        distance_to_school = find_nearest_station1(data.위도, data.경도, seoul_school)

        # 예측 입력값 생성 (예: 테스트용)
        input_df = pd.DataFrame([{
    '시간': dt.hour,
    '일': dt.day,
    '월': dt.month,
    '년도': dt.year,
    '지하철거리(m)': distance_to_subway,
    '버스정류소와의거리(m)': distance_to_bus,
    '학교와의거리(m)': distance_to_school,
    '공휴일': is_holiday(dt),
    '기온(°C)': data.기온,
    '강수량(mm)': data.강수량,
    '요일구분_bool': dt.weekday() >= 5 or is_holiday(dt)
}])

        prediction = 클러스터3.predict(input_df)

        value = round(float(prediction[0]))
        return {
            "predicted_자전거": max(0, value)  # 음수 방지
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))





if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8000)
