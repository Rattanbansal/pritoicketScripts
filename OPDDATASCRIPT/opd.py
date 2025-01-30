import mysql.connector
import requests
import json

# MySQL Configuration
MYSQL_CONFIG = {
    "host": "production-secondary-db-node.cluster-ck6w2al7sgpk.eu-west-1.rds.amazonaws.com",
    "database": "priopassdb",
    "user": "pipeuser",
    "password": "d4fb46eccNRAL",
}
TABLE_NAME = "order_payment_details"

# API Configuration
API_HOST = "https://distributor-api.prioticket.com/v3.7/distributor/orders/"
AUTH_TOKEN = "eyJhbGciOiJSUzI1NiIsImtpZCI6IjgxYjUyMjFlN2E1ZGUwZTVhZjQ5N2UzNzVhNzRiMDZkODJiYTc4OGIiLCJ0eXAiOiJKV1QifQ.eyJuYW1lIjoiUmF0dGFuIEJhbnNhbCIsInBpY3R1cmUiOiJodHRwczovL2xoMy5nb29nbGV1c2VyY29udGVudC5jb20vYS9BQ2c4b2NKODNJbVVacjdDX3AtaktmdGJacGFDa0hJNFRiLTNjRmNkX0thN0FBcnF4THM9czk2LWMiLCJjYXNoaWVyVHlwZSI6NCwiY2FzaGllcklkIjoiMTQzNDkxNSIsImRpc3RyaWJ1dG9ySWQiOjAsIm93blN1cHBsaWVySWQiOjAsInBvc1R5cGUiOjAsInJlZ2lvbmFsX3NldHRpbmdzIjoiZXlKa1lYUmxYMlp2Y20xaGRDSTZJbVJjTDIxY0wxa2lMQ0owYVcxbFgyWnZjbTFoZENJNklrZzZhU0lzSW1OMWNuSmxibU41WDNCdmMybDBhVzl1SWpvaWJHVm1kRjkzYVhSb1gzTndZV05sSWl3aWRHaHZkWE5oYm1SZmMyVndZWEpoZEc5eUlqb2lMQ0lzSW1SbFkybHRZV3hmYzJWd1lYSmhkRzl5SWpvaUxpSXNJbTV2WDI5bVgyUmxZMmx0WVd4eklqb2lNaUlzSW14aGJtZDFZV2RsSWpvaVJXNW5iR2x6YUNoRlRpa2lMQ0owYVcxbGVtOXVaU0k2SWtGemFXRmNMMHR2Ykd0aGRHRWlmUT09IiwiaXNzIjoiaHR0cHM6Ly9zZWN1cmV0b2tlbi5nb29nbGUuY29tL3ByaW90aWNrZXQtOTNlZjMiLCJhdWQiOiJwcmlvdGlja2V0LTkzZWYzIiwiYXV0aF90aW1lIjoxNzM4MjIwOTgwLCJ1c2VyX2lkIjoiTUY5eUxtSmhibk5oYkVCd2NtbHZkR2xqYTJWMExtTnZiUT09Iiwic3ViIjoiTUY5eUxtSmhibk5oYkVCd2NtbHZkR2xqYTJWMExtTnZiUT09IiwiaWF0IjoxNzM4MjIwOTgwLCJleHAiOjE3MzgyMjQ1ODAsImVtYWlsIjoici5iYW5zYWxAcHJpb3RpY2tldC5jb20iLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwiZmlyZWJhc2UiOnsiaWRlbnRpdGllcyI6eyJnb29nbGUuY29tIjpbIjExNTg0NTI1MTg3NDMyMTE2NzczOCJdLCJlbWFpbCI6WyJyLmJhbnNhbEBwcmlvdGlja2V0LmNvbSJdfSwic2lnbl9pbl9wcm92aWRlciI6Imdvb2dsZS5jb20ifX0.ijv3QR3gtpsKzgsuxUIVDGHfA0nZ4fZOvLqz8_gw2lTYi-VaeUZWjKDcO8VvF7YAYclyva1yUDKp_G4ZYZOntnCr_vkfaicuxcqSEuYSSvVo6iczfJi-omnszgfgAIfGnKQioeN7wnAszzbrf_O4EtByMxWe3MfRDkBty-IesJf6jhv3Nf4mxtVc4QyAE6-2azMow9ql97M9qpyv9o5IfqyteoPCWFn8uAbA_xZzcSK2wvHJgLwavdp5IAJD8GHGjmhfIoNLXFEFs9xKXzvbnJoGPaEoEBfh_94LimvGkQNw_faFF78DAPpdWRSZTJq_328cEn1bnpQWaXfQ8O99Wg"

# Visitor Group Numbers
VISITOR_GROUPS = [172424388652190, 171239128693000, 169946088980166, 171309627556902, 170533246837622, 170118238959462, 170627778020131, 171163532233281, 171345615906813, 170896277663380, 169668109051294, 172225343176036, 172527712030818, 172606430505834, 172622557836434, 171801165998777, 171949633479786, 171870758045596, 169037075294929, 172899306283712, 170852746294769, 170074679344450, 171053083607824, 173023384129377, 172296074113914, 171714632915423, 168552856699484, 169685936949064, 168821370449792, 170506231045665, 172475334635984, 172405688304183, 171318645195023, 171075639029990, 171759139847204, 170923290485621, 172778714000544, 171258759371046, 172354930993526, 169001522280637, 171223345042642, 171214401741404, 169772387243370, 170013268116558, 171752075465538, 172648763848824, 172924341168602, 170808495057492, 170612958904859, 170609063023581, 171775030409381, 171317395981644, 170722787918161, 170135472910575, 169762095124539, 167058571297473, 172967679222557, 168750087710703, 172597791007587, 173261913516402, 171414935324182, 171024858866169, 170186754067621, 169762119593182, 172829725214747, 171559921173306, 169928380412535, 170549456546565, 172001165640557, 172615086758840]

# Output SQL File
SQL_FILE = "sql_queries.txt"


def fetch_mysql_data(visitor_group_no):
    """Fetches MySQL data based on visitor_group_no."""
    try:
        conn = mysql.connector.connect(**MYSQL_CONFIG)
        cursor = conn.cursor(dictionary=True)

        query = f"SELECT id, status, ticket_booking_id FROM {TABLE_NAME} WHERE visitor_group_no = %s"
        cursor.execute(query, (visitor_group_no,))
        rows = cursor.fetchall()

        cursor.close()
        conn.close()

        if not rows:
            print(f"No MySQL data found for visitor_group_no: {visitor_group_no}")
        return rows

    except mysql.connector.Error as err:
        print(f"MySQL Error: {err}")
        return []


def fetch_order_details(visitor_group_no):
    """Fetches order details from the API."""
    try:
        url = f"{API_HOST}{visitor_group_no}"
        headers = {
            "Authorization": f"Bearer {AUTH_TOKEN}",
            "Accept": "application/json",
        }
        response = requests.get(url, headers=headers)

        if response.status_code != 200:
            print(f"API Error {response.status_code}: {response.text}")
            return None

        # Try parsing JSON response
        try:
            data = response.json()
            return data
        except json.JSONDecodeError:
            print(f"Error: API returned invalid JSON for visitor_group_no {visitor_group_no}")
            return None

    except requests.RequestException as e:
        print(f"Request failed: {e}")
        return None


def process_visitor_groups():
    """Processes visitor groups and generates SQL queries."""
    with open(SQL_FILE, "w") as sql_file:
        for visitor_group_no in VISITOR_GROUPS:
            print(f"Processing visitor group: {visitor_group_no}")

            # Fetch MySQL data
            mysql_data = fetch_mysql_data(visitor_group_no)
            if not mysql_data:
                continue  # Skip if no data found

            # Fetch API data
            api_response = fetch_order_details(visitor_group_no)
            if not api_response:
                continue  # Skip if API failed

            # Extract bookings
            bookings = api_response.get("data", {}).get("order", {}).get("order_bookings", [])
            if not bookings:
                print(f"No API bookings found for visitor_group_no: {visitor_group_no}")
                continue

            # Process each MySQL row
            for row in mysql_data:
                row_id = row["id"]
                status = row["status"]
                ticket_booking_id = row["ticket_booking_id"]

                # Process each booking
                for booking in bookings:
                    booking_price = booking.get("booking_pricing", {}).get("price_total", "0.00")
                    booking_reference = booking.get("booking_reference", "")

                    query = ""
                    if status in [2, 3]:
                        query = f"""UPDATE {TABLE_NAME} SET amount = '{booking_price}', total = '0.00',order_amount = '{booking_price}', order_total = '0.00',booking_currency_amount = '{booking_price}', booking_amount = '{booking_price}' WHERE id = '{row_id}' AND ticket_booking_id = '{booking_reference}';"""
                    elif status == 1:
                        query = f"""UPDATE {TABLE_NAME} SET amount = '{booking_price}', total = '{booking_price}',order_amount = '{booking_price}', order_total = '{booking_price}',booking_currency_amount = '{booking_price}', booking_amount = '{booking_price}' WHERE id = '{row_id}' AND ticket_booking_id = '{booking_reference}';"""

                    # Save query to file
                    if query:
                        sql_file.write(query + "\n")
                        print(f"Query written for row_id: {row_id}")

            # Introduce a delay (simulating the 3-second delay from Bash)
            import time
            time.sleep(3)


# Execute processing
if __name__ == "__main__":
    process_visitor_groups()
