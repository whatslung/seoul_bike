# from fastapi import FastAPI
# from fastapi.staticfiles import StaticFiles
# # from mapo_station import router as mapo_station_router
# from weather import router as weather_router



# app = FastAPI()
# # API 라우터 등록
# # app.include_router(mapo_station_router, prefix='/mapo_station', tags=['mapo_station'])
# # app.include_router(weather_router, prefix='/weather', tags=['weather'])

# # Flutter Web 빌드 결과 정적파일 서비스
# # app.mount("/", StaticFiles(directory="build/web", html=True), name="web")



# if __name__ == "__main__":
#     import uvicorn
#     uvicorn.run(app, host="127.0.0.1", port=8000)