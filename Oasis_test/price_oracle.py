import json

def get_latest_price():
    # 模擬從中心化交易所獲取價格
    return 130000  # 比特幣價格

def main():
    price = get_latest_price()
    print(json.dumps({"price": price}))

if __name__ == "__main__":
    main()
