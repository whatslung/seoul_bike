# Module
from bs4 import BeautifulSoup
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.support import expected_conditions as EC
import pandas as pd
import time
import json
from datetime import datetime, timedelta

def get_weather_data():
    url = "https://www.weather.go.kr/w/weather/forecast/short-term.do#dong/1144066000/37.549656/126.92297/%EC%84%9C%EC%9A%B8%ED%8A%B9%EB%B3%84%EC%8B%9C%20%EB%A7%88%ED%8F%AC%EA%B5%AC%20%EC%84%9C%EA%B5%90%EB%8F%99/SEL/%EC%84%9C%EA%B5%90%EB%8F%99"

    # 시간 간격을 1시간 간격으로 설정하는 코드
    def setting():
        # 시 클릭, 서울특별시 클릭, 서울특별시 바로가기 클릭 도시형생활주택 off 클릭
        set_1hour = '//*[@id="digital-forecast"]/div[1]/div[3]/div[1]/div/div/a[2]'
        time.sleep(1.5)
        driver.find_element(By.XPATH, set_1hour).click()
        time.sleep(1)

    # 페이지 정보 갱신하는 코드
    def refresh():
        global soup
        html = driver.page_source
        soup = BeautifulSoup(html, 'html.parser')
        time.sleep(1)

    # 날씨 데이터 크롤링 코드
    def get_weather():
        global weather_data
        weather_data = []
        for a in [1, 2]:
            ul_list = soup.select(
                f'#digital-forecast > div.cmp-dfs-slider.hr1-fct.mode-default > div.dfs-tab-body > div.dfs-slider > div.slide-wrap > div:nth-child({a}) > div > div.item-wrap > ul')

            for ul in ul_list:
                data = {}
                data['date'] = ul.get('data-date')
                data['time'] = ul.get('data-time')

                li_tags = ul.find_all('li')
                for li in li_tags:
                    text = li.get_text(strip=True)
                    if "시각" in text:
                        data["시각"] = text.replace("시각:", "")[0:-1]
                    elif "기온(체감온도)" in text:
                        data["기온"] = li.find_all('span')[1].text.replace("℃", "").split('(')[0]
                    elif "습도" in text:
                        data["습도"] = li.find_all('span')[1].text.replace("%", "")
                    elif "강수량" in text:
                        data["강수량"] = li.find_all('span')[1].text.replace("%", "")
                weather_data.append(data)

        # 24시를 익일 00시로 바꾸기
        for item in weather_data:
            if item["time"] == "24:00":
                date_obj = datetime.strptime(item["date"], "%Y-%m-%d")
                next_day = date_obj + timedelta(days=1)
                item["date"] = next_day.strftime("%Y-%m-%d")
                item["time"] = "00:00"
                item["시각"] = "0시"
        for item in weather_data:
            if item['강수량'] == '-':
                item['강수량'] = '0'


        # JSON 저장
        return weather_data
        # with open("weather_data_ex.json", "w", encoding="utf-8") as f:
        #     json.dump(weather_data, f, ensure_ascii=False, indent=2)

    # ✅ 크롬 드라이버 설정 (headless 포함)
    options = Options()
    options.add_argument("--headless=new")  # 최신 방식
    options.add_argument("--disable-gpu")
    options.add_argument("--no-sandbox")
    options.add_argument("--window-size=1920,1080")
    options.add_argument("--disable-dev-shm-usage")

    # 웹 열기
    driver = webdriver.Chrome(options=options)
    driver.get(url)

    # 로딩 대기
    time.sleep(4)

    # 시간 간격 1시간으로 셋팅
    setting()

    # 화면 리소스 갱신
    refresh()

    # 날씨 정보 가져와서 저장하기
    get_weather()

    # 브라우저 종료
    driver.quit()

    return weather_data