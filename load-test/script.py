import os
import re
import time
import subprocess
import sys
import asyncio
import signal
import time
import requests
import json
import fitz
import shutil
from tqdm import tqdm
from pathlib import Path
from bs4 import BeautifulSoup
from dotenv import load_dotenv
from playwright.async_api import async_playwright
from urllib.parse import urlparse, parse_qsl, urlencode, urlunparse

load_dotenv(dotenv_path=str(Path(__file__).parent / ".env"),override=True)

# Access credentials using os.getenv()
HYPERSWITCH_HOST_URL = os.getenv("HYPERSWITCH_HOST_URL")
GRAFANA_PERMISSION = os.getenv("GRAFANA_PERMISSION")
GRAFANA_HOST = os.getenv("GRAFANA_HOST")
GRAFANA_SERVICE_ACCOUNT_TOKEN = os.getenv("GRAFANA_SERVICE_ACCOUNT_TOKEN")
GRAFANA_USERNAME = os.getenv("GRAFANA_USERNAME")
GRAFANA_PASSWORD = os.getenv("GRAFANA_PASSWORD")
STORAGE_PERMISSION = os.getenv("STORAGE_PERMISSION")
POSTGRES_USERNAME = os.getenv("POSTGRES_USERNAME")
POSTGRES_PASSWORD = os.getenv("POSTGRES_PASSWORD")
POSTGRES_DBNAME = os.getenv("POSTGRES_DBNAME")
POSTGRES_HOST = os.getenv("POSTGRES_HOST")
POSTGRES_PORT = os.getenv("POSTGRES_PORT")

# Colors for terminal output
YELLOW="\033[1;33m"
CYAN="\033[1;36m"
RESET="\033[0m"

# Global Variables
IDEAL_VALUES = {"Response Time":"1000 - 1300 ms", "Storage per Transaction":"< 18 Kb"}
NORMAL_RPS = 0
SPIKE_RPS = 0
TPS_TO_RPS_FACTOR = 7
RPS_CAPACITY_PER_POD = 35
POD_CPU_ALLOCATION = 400
POD_MEMORY_ALLOCATION = 1000
IDEAL_STORAGE_PER_TRANSACTION = 14
PSQL_QUERY = """
        SELECT SUM(pg_total_relation_size(quote_ident(tablename))) AS total_size
        FROM pg_tables
        WHERE schemaname = 'public';
        """

#Machine Specifications Variables
MACHINE_SPECS = {
    "Machine": "Apple MacBook Pro",
    "Processor": "Apple M4 Pro",
    "RAM": "24 GB",
    "Operating System": "macOS 15.3.2 (24D81)",
    "Container Runtime": "OrbStack",
    "Cluster Type": "Kubernetes",
    "Pod CPU Allocation": f"{POD_CPU_ALLOCATION}m ({POD_CPU_ALLOCATION/1000:.1f} vCPU)",
    "Pod Memory Allocation": f"{POD_MEMORY_ALLOCATION}Mi (1 GB RAM)"
}

# Function to calculate performance requirements and recommendations
def calculator(regular_transactions, spike_transactions, scaling_factor):
    results = []

    # Normal Traffic
    tps = regular_transactions / (365 * 12 * 60 * 60)
    rps = tps * TPS_TO_RPS_FACTOR * scaling_factor
    global NORMAL_RPS, SPIKE_RPS
    NORMAL_RPS = round(rps,2)
    pods_required = int(rps / RPS_CAPACITY_PER_POD) + (1 if rps % RPS_CAPACITY_PER_POD != 0 else 0)  # Round up
    storage_needed_gb = (regular_transactions * IDEAL_STORAGE_PER_TRANSACTION) / (1024 * 1024)  # Convert KB to GB
    results.append([
        "Regular Traffic",
        round(tps, 2),
        round(rps/scaling_factor, 2),
        round(rps, 2),
        pods_required,
        ])

    # Spike Traffic
    tps = spike_transactions
    rps = tps * TPS_TO_RPS_FACTOR * scaling_factor
    SPIKE_RPS = round(rps,2)
    pods_required = int(rps / RPS_CAPACITY_PER_POD) + (1 if rps % RPS_CAPACITY_PER_POD != 0 else 0)  # Round up
    results.append([
        "Spike Traffic",
        round(tps, 2),
        round(rps/scaling_factor, 2),
        round(rps, 2),
        pods_required,
        ])

    # Convert results to separate HTML tables
    keys = ["Traffic", "TPS", "RPS", f"Recommended RPS [x{scaling_factor}]","Pods Required"]
    requirements_table = f"<h2 class='subheading'>Performance Requirements & Recommendations</h2><table><tr>"
    # Add headers
    requirements_table += "".join(f"<th>{key}</th>" for key in keys) + "</tr>"
    # Add row
    requirements_table += "<tr>" + "".join(f"<td>{value}</td>" for value in results[0]) + "</tr>"
    requirements_table += "<tr>" + "".join(f"<td>{value}</td>" for value in results[1]) + "</tr>"
    requirements_table += "</table>"
    html_content = f"""
        <h1>Report Overview</h1>
        <p>This report provides an analysis of the load test results, including key performance metrics such as <strong>Transactions Per Second (TPS)</strong>, <strong>Requests Per Second (RPS)</strong>, <strong>Response Time</strong>, and <strong>Storage Utilization</strong>. It also includes recommendations for infrastructure scaling based on observed performance.</p>
        <h2 class="subheading">Infrastructure Scaling Recommendations</h2>
        <ul>
            <li><strong>Estimated Annual Transactions:</strong> {regular_transactions}</li>
            <li><strong>Expected Peak Transaction Rate:</strong> {spike_transactions} per second</li>
            <li><strong>Estimated Storage Requirement:</strong> {round(storage_needed_gb, 2)} GB</li>
            <li><strong>Recommended Storage (4x Scaling Factor):</strong> {round(storage_needed_gb*4, 2)} GB</li>
        </ul>
        {requirements_table}
        <p>These recommendations and requirements were calculated based on the inputs and assumptions such as :</p>
        <ul>
            <li><strong>TPS Calculation :</strong><br>
                <div style="text-align: center; margin:5px"><code class="code-block-single">TPS = Total Transactions per Year / (365 × 12 × 60 × 60)</code></div>
                TPS is determined by dividing the total expected transactions per year by the total number of seconds in a 12-hour daily window, assuming that the majority of transactions occur during peak business hours.
            </li>
            <li><strong>RPS Calculation :</strong><br>
                <div style="text-align: center;margin:5px"><code class="code-block-single">1 TPS = {TPS_TO_RPS_FACTOR} RPS</code></div>
                Assuming 1 transaction would trigger an average of {TPS_TO_RPS_FACTOR} requests.
                We also recommend a <strong>10x</strong> scaling factor to ensure efficient processing and responsiveness under varying loads.
            </li>
            <li><strong>Pod Calculation :</strong><br>
                <div style="text-align: center;margin:5px"><code class="code-block-single">No. of pods required = Total RPS / RPS that each pod can handle</code></div>
                Here, the recommended RPS is considered for total RPS, and the RPS that each pod can handle is determined during load testing.
                <div style="text-align: center;margin:5px"><code class="code-block-single">RPS that each pod can handle = {RPS_CAPACITY_PER_POD} *</code></div>
                <h5>* Please refer to the <strong>References Section</strong> at the end of the report to know more </h5>
            </li>
        </ul>
    """
    return html_content

# Function to get storage usage through manual input
def get_storage_usage_manual(input_string):
    return float(input(f"\n{YELLOW}You can run this psql query to get the storage used in bytes!{RESET}\n{CYAN}{PSQL_QUERY}{RESET}{input_string}"))

# Function to get storage usage through psql CLI
def get_storage_usage(input_string):
    """Fetch storage usage by calling the psql CLI."""
    if STORAGE_PERMISSION == "true":
        try:
            # Build connection URI
            conn_str = f"postgresql://{POSTGRES_USERNAME}:{POSTGRES_PASSWORD}@{POSTGRES_HOST}:{POSTGRES_PORT}/{POSTGRES_DBNAME}"
            cmd = [
                "psql",
                conn_str,
                "--tuples-only",  # tuples only (no headers)
                "--command", PSQL_QUERY
            ]
            output = subprocess.check_output(cmd, text=True)

            # Parse and return the total size as an integer
            total_size = float(output.strip())
            return total_size

        except (subprocess.CalledProcessError, Exception, ValueError) as e:
            print(f"psql command failed: {e}\nResorting to manual input !")
            return get_storage_usage_manual(input_string)

    else:
        return get_storage_usage_manual(input_string)

# Function to create merchant account for hyperswitch
def run_merchant_create(test_spec):
    """Runs the merchant_create.py script and waits for completion."""
    print(f"\n🔹 Creating Merchant for {test_spec} testing...")
    try:
        result = subprocess.run([sys.executable, "merchant_create.py"], capture_output=True, text=True, check=True)
        time.sleep(2)
        print("  ✅ Merchant created successfully.")
    except subprocess.CalledProcessError as e:
        print(f"Error running merchant_create.py: {e.stderr}")
        sys.exit(1)  # Exit the script if merchant_create.py fails

# Function to run Locust load test
async def run_locust(test_spec, users,run_time, file_name):
    """Runs the Locust load test."""
    subprocess.Popen([
        "locust", "--locustfile", "locustfile.py", "--headless",
        "--users", f"{users}", "--spawn-rate", f"{int(users/2)}", "--run-time", f"{run_time}s",
        "--html", f"output/temp/{file_name}.html", "--host", HYPERSWITCH_HOST_URL
    ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    print(f"    ⏳ Load test running for {test_spec}...")
    # Run the loading bar while the Locust test runs
    await loading_bar(run_time)
    time.sleep(5)

    output_file = Path(f'output/temp/{file_name}.pdf').resolve()
    input_file = Path(f'output/temp/{file_name}.html').resolve()
    try:

        async with async_playwright() as p:
            browser = await p.chromium.launch(headless=True)
            page = await browser.new_page()

            # Load the HTML file
            await page.goto(f"file://{input_file}", wait_until="load")
            rendered_html = await page.content()
            edited_html = rendered_html.replace('Locust Test Report', f'Locust Report for {test_spec}')
            with open(input_file, "w", encoding="utf-8") as f:
                f.write(edited_html)
            await browser.close()
            await html_to_pdf(input_file, output_file)

    except Exception as error:
        print(f"❌ Failed to save locust report as pdf: {error}")

# Function to generate the overview report
async def generate_med_report_table(requirement_content, total_bytes_list):
    file_names = ["test_normal", "test_spike"]
    rps_list = [NORMAL_RPS, SPIKE_RPS]
    results = []
    for idx, file_name in enumerate(file_names):
        with open(f"output/temp/{file_name}.html", "r", encoding="utf-8") as file:
            html_content = file.read()

        soup = BeautifulSoup(html_content, "html.parser")
        first_table = soup.find("tbody")
        if first_table:
            last_row = first_table.find_all("tr")[-1]  # Last row
            columns = last_row.find_all("td")
            num_requests = columns[2].text.strip()  # # Requests column
            rps = columns[8].text.strip()           # RPS column
        else:
            num_requests, rps = "N/A", "N/A"

        second_table = soup.find_all("tbody")[1]  # Second table
        if second_table:
            last_row_95 = second_table.find_all("tr")[-1]  # Last row
            columns_95 = last_row_95.find_all("td")
            response_time = columns_95[7].text.strip()  # 95th percentile response time column
        else:
            response_time = "N/A"

        total_storage = int(total_bytes_list[idx]) if total_bytes_list[idx] else 0
        num_requests = int(num_requests) if num_requests.isdigit() else 1  # Avoid division by zero
        storage_per_transaction = round(total_storage / (num_requests * 1024) if num_requests else 0, 2)
        results.append(f"""<tbody>
                <tr><td>RPS(Requests per second)</td><td>{rps}</td><td>> {rps_list[idx]}</td></tr>
                <tr><td>Response Time</td><td>{response_time}</td><td>{IDEAL_VALUES['Response Time']}</td></tr>
                <tr><td>Storage Used(per transaction)</td><td>{storage_per_transaction}Kb</td><td>{IDEAL_VALUES['Storage per Transaction']}</td></tr>
            </tbody>""")

    # Create HTML segment with extracted values
    new_html_segment = f"""
    <html>
    <head>
        <style>
            .metric-section{{
                page-break-inside: avoid;
            }}
        </style>
    </head>
    <body>
    <div style="display: flex;justify-content: center;align-items: center;height: 100vh; text-align: center;font-size: 3rem;font-weight: bold;">
        <h1 style="text-align:center;">Load Test Report</h1>
    </div>
    <div style="padding:0 24px; page-break-after: always; ">
        {requirement_content}
        <h2 class="subheading" style="page-break-before:always">Report Summary</h2>
        <h3 class="subheading bottom-spaceless">Regular Traffic Load Test</h3>
        <table>
            <thead>
                <tr>
                    <th>Parameter</th>
                    <th>Output</th>
                    <th>Reference</th>
                </tr>
            </thead>
            {results[0]}
        </table>
        <h5>* Please refer to the <strong>References Section</strong> at the end of the report to know more </h5>

        <h3 class="subheading bottom-spaceless">Spike Traffic Load Test</h3>
        <table>
            <thead>
                <tr>
                    <th>Parameter</th>
                    <th>Output</th>
                    <th>Reference</th>
                </tr>
            </thead>
            {results[1]}
        </table>
        <h5>* Please refer to the <strong>References Section</strong> at the end of the report to know more </h5>
        <p>This summary is based on observed values from the load test, as well as reference data from tests conducted in an ideal production environment using machines with the specified capacity:</p>
        <ul>
            <li><strong>RPS:</strong><br>The maximum number of requests per second (RPS) achieved by your server during the load test.</li>
            <li><strong>Response Time:</strong><br>The total time taken for each API call, including external connector calls. These external calls significantly contribute to latency, which can vary depending on the connector, region, and other factors.</li>
            <li><strong>Storage Used:</strong><br>The estimated storage consumption per transaction, indicating how much space each transaction occupies in your storage system. It is calculated as:
                <div style="text-align:center;margin:5px"><code class="code-block-single">Storage used per transaction = Total storage used / Number of transactions</code></div>
            </li>
         </ul>

        <h2>Conclusion</h2>
        <p>The load test results offer valuable insights into system performance. By following these scaling recommendations, the infrastructure can efficiently scale while maintaining optimal performance. Feel free to share this report with us at <a href="mailto:hyperswitch@support.in">hyperswitch@support.in</a> for validation and feedback.</p>
        <p>For detailed insights into the specifications and APIs used in the load test, please refer to the <strong>References</strong> section at the end of the document.</p>

    </div>
    </body>
    </html>
    """

    # Write the modified HTML back to the file
    html_file = Path("output/temp/overview_report.html").resolve()
    pdf_file = Path('output/temp/overview_report.pdf').resolve()
    with open(html_file, "w", encoding="utf-8") as file:
        file.write(new_html_segment)

    await html_to_pdf(html_file, pdf_file)

# Function to download Grafana dashboard snapshots
async def download_dashboard_pdf(json_data, idx, duration):
    url = f"{GRAFANA_HOST}/api/snapshots"
    headers = {
        "Accept": "application/json",
        "Content-Type": "application/json",
        "Authorization": f"Bearer {GRAFANA_SERVICE_ACCOUNT_TOKEN}"
    }
    response = requests.post(url, json=json_data, headers=headers)
    dashboard_url = response.json().get("url")
    parsed = urlparse(dashboard_url)
    params = dict(parse_qsl(parsed.query))
    params.update({'from': f'now-{duration+5}m', 'to': 'now'})
    dashboard_url = urlunparse(parsed._replace(query=urlencode(params)))
    output_file = f"output/snapshots/snap-{idx+1}.png"
    session = requests.Session()
    response = session.post(
        f"{GRAFANA_HOST}/login",
        json={"user": GRAFANA_USERNAME, "password": GRAFANA_PASSWORD},
        headers={
            "Accept-Language": "en-US,en;q=0.9",
            "Origin": f"{GRAFANA_HOST}",
            "Referer": f"{GRAFANA_HOST}/login",
            "Accept": "application/json, text/plain, */*",
            "Content-Type": "application/json",
        }
    )

    if response.status_code == 200:
        for cookie in session.cookies:
            if cookie.name == "grafana_session":
                session_cookie = cookie.value
    else:
        print("❌ Login failed! Check credentials or Grafana status.")
        return
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        page = await browser.new_page()
        parsed_url = urlparse(GRAFANA_HOST)
        cookie_domain = parsed_url.hostname
        await page.context.add_cookies([
            {
                "name": "grafana_session",
                "value": session_cookie,
                "domain": cookie_domain,
                "path": "/"
            }
        ])
        await page.goto(dashboard_url, wait_until="networkidle")
        await asyncio.sleep(5)

        element = await page.query_selector(".scrollbar-view")
        if element:
            # Get the full height of the element
            full_height = await page.evaluate("el => el.scrollHeight", element)

            # Resize viewport to capture entire scrollbar-view
            await page.set_viewport_size({"width": 1920, "height": full_height+100})
            await asyncio.sleep(2)  # Ensure rendering is complete

            # Capture the screenshot
            await element.screenshot(path=str(output_file))
            print(f"📷 Snapshot captured and saved: {output_file}")
        else:
            print("❌ Error saving snapshot!")

        await browser.close()

# Function to append Grafana snapshots to the PDF
async def append_snap_to_pdf():
    html_file = Path("output/temp/metric_report.html").resolve()
    pdf_file = Path('output/temp/metric_report.pdf').resolve()
    image_paths = [
        Path("output/snapshots/snap-1.png").resolve(),
        Path("output/snapshots/snap-2.png").resolve(),
        Path("output/snapshots/snap-3.png").resolve(),
    ]

    # Generate HTML Content
    html_content = f"""
    <html>
        <head>
        </head>
        <body>
            <div style="padding:0 24px">
                <h1 style="page-break-before: always;">Grafana Snapshots</h1>
                <div style="page-break-inside: avoid; margin-bottom: 20px;">
                    <h2 style="margin-bottom: 20px;">Pod CPU and Memory Usage :</h2>
                    <img src="{image_paths[1]}" style="max-width: 100%; max-height: 95vh; display: block; margin: 0 auto;" />
                </div>
                <div style="page-break-inside: avoid; margin-bottom: 20px;">
                    <h2 style="margin-bottom: 20px;">Business Metrics :</h2>
                    <img src="{image_paths[0]}" style="max-width: 100%; max-height: 95vh; display: block; margin: 0 auto;" />
                </div>
                <div style="page-break-inside: avoid; margin-bottom: 20px;">
                    <h2 style="margin-bottom: 20px;">Server CPU and Memory Usage :</h2>
                    <img src="{image_paths[2]}" style="max-width: 100%; max-height: 95vh; display: block;  margin: 0 auto;" />
                </div>
            </div>
        </body>
    </html>

    """

    # Save the HTML file
    with open(html_file, "w", encoding="utf-8") as f:
        f.write(html_content)
    await html_to_pdf(html_file,pdf_file)

# Function to create the references section
async def create_reference_section():
    html_content =f"""<div style="padding:0 24px;">
    <h1>References</h1>

    <h3>System Specifications</h3>
    <p>The reference values used in this load test were derived from running it on a machine with the following specifications and resource allocations:</p>
    <ul>
        {''.join(f'<li><strong>{key}:</strong> {value}</li>' for key, value in MACHINE_SPECS.items())}
    </ul>
    <p><strong>Note:</strong> The load test was conducted in a Kubernetes cluster running on OrbStack, which provides a lightweight and efficient container runtime environment for macOS. This setup allows for better resource isolation and more accurate performance measurements compared to running directly on the host machine.</p>

    <h3>API Details</h3>
    <p>The load test utilized the following API request to simulate payment transactions:</p>

    <div style="font-size:18px;"><strong>Payment Create API</strong></div>
    <pre style="font-family: 'Courier New', monospace; padding: 12px; background-color: #F5F5F5; border-radius: 8px; font-size: 14px; line-height: 3;">
        <code>curl -X POST https://your-api-endpoint.com/payments
        -H "Content-Type: application/json"
        -H "Accept: application/json"
        -H "api-key: YOUR_API_KEY"
        -d '{{
            "amount": 6540,
            "currency": "USD",
            "confirm": False,
            "capture_method": "automatic",
            "capture_on": "2022-09-10T10:11:12Z",
            "amount_to_capture": 6540,
            "customer_id": "DummyCustomer",
            "email": "guest@example.com",
            "name": "John Doe",
            "phone": "999999999",
            "phone_country_code": "+65",
            "description": "Its my first payment request",
            "authentication_type": "no_three_ds",
            "return_url": "https://hyperswitch.io/",
            "billing": {{
                "address": {{
                    "line1": "1467",
                    "line2": "Harrison Street",
                    "line3": "Harrison Street",
                    "city": "San Fransico",
                    "state": "California",
                    "zip": "94122",
                    "country": "US",
                    "first_name": "PiX",
                    "last_name": "Pix"
                }}
            }},
            "shipping": {{
                "address": {{
                    "line1": "1467",
                    "line2": "Harrison Street",
                    "line3": "Harrison Street",
                    "city": "San Fransico",
                    "state": "California",
                    "zip": "94122",
                    "country": "US",
                    "first_name": "PiX"
                }}
            }},
            "statement_descriptor_name": "joseph",
            "statement_descriptor_suffix": "JS"
        }}'</code></pre>

    <div style="font-size:18px;"><strong>Payment Confirm API</strong></div>
    <pre style="font-family: 'Courier New', monospace; padding: 12px; background-color: #F5F5F5; border-radius: 8px; font-size: 14px; line-height: 3;">
        <code>curl -X POST https://your-api-endpoint.com//payments/payment_id/confirm
        -H "Content-Type: application/json"
        -H "Accept: application/json"
        -H "api-key: YOUR_API_KEY"
        -d '{{
            "payment_method": "card",
            "payment_method_type": "credit",
            "payment_method_data": {{
                "card": {{
                    "card_number": "4242424242424242",
                    "card_exp_month": "10",
                    "card_exp_year": "25",
                    "card_holder_name": "joseph Doe",
                    "card_cvc": "123"
                }}
            }}
        }}'</code></pre>

    <p>Feel free to try out our Payment Create API to test out a payment. For a comprehensive list of APIs to create and manage payments, visit our official API documentation at <a href="https://api-reference.hyperswitch.io/" target="_blank">Hyperswitch-API-Docs</a>.</p>
    </div>
    """
    html_file = Path("output/temp/references.html").resolve()
    pdf_file = Path('output/temp/references.pdf').resolve()
    with open(html_file, "w", encoding="utf-8") as file:
        file.write(html_content)

    await html_to_pdf(html_file, pdf_file)

# Function to convert HTML to PDF using Playwright
async def html_to_pdf(html_file,output_file):
    try:
        async with async_playwright() as p:
            browser = await p.chromium.launch(headless=True)
            page = await browser.new_page()
            await page.goto(f"file://{html_file}", wait_until="load")
            await page.add_style_tag(content=f"""
                @page {{
                    size: A4;
                    margin:20px;
                    border: 1px solid black;
                    padding:24px 0;
                }}
                * {{
                    font-family: Arial, sans-serif !important;
                }}
                h1 {{
                    font-family: Roboto, Helvetica, Arial, sans-serif;
                    font-size: 44px;
                    line-height: 1.167;
                    letter-spacing: 0em;
                    font-weight: 700;
                    margin-block-start: 0 !important;
                }}
                h2 {{
                    font-weight: 600 !important;
                    font-size: 28px;
                    line-height: 1.235;
                    letter-spacing: 0.00735em;
                }}
                h3, h4 {{
                    font-size:24px;
                }}
                h5{{
                    font-size:16px;
                    margin-block-start: 0.5em !important;
                }}
                p, li {{
                    text-align: justify;
                    font-size:20px;
                    line-height: 1.5;
                }}
                .code-block-single {{
                    font-size: 16px;
                    font-family: 'Courier New', monospace;
                    padding: 10px;
                    background-color: #F5F5F5;
                    border-radius: 8px;
                    line-height: 3;
                }}
                .bottom-spaceless {{
                    margin-block-end: -0.2em !important;
                }}
                div[_echarts_instance_] {{
                    break-inside: avoid;
                    page-break-inside: avoid;
                    display: block;
                }}
                table {{
                    width: 100%;
                    border-collapse:
                    collapse;
                    margin-top: 20px;
                }}
                th, td {{
                    border: 1px solid black;
                    padding: 8px;
                    text-align: left;
                }}
                th {{
                    background-color: #f2f2f2;
                }}
                .grafana-snapshot-page {{
                    page-break-before: always;
                }}
                .MuiStack-root:has(button svg[data-testid="ViewColumnIcon"]) {{
                display: none !important;
                }}
            """)

            await asyncio.sleep(2)
            # Generate PDF
            await page.pdf(
                path=str(output_file),
                format="A4",
                print_background=True,
                scale=0.8
            )
            await browser.close()

    except Exception as error:
        print(f"❌ Failed to convert HTML to PDF: {error}")

# Function to merge multiple PDFs into one
def merge_pdfs():
    output_file = Path("output/report.pdf").resolve()
    pdf_list = ["overview_report", "test_normal", "test_spike", "references"]
    if GRAFANA_PERMISSION == "true":
        pdf_list.insert(3, "metric_report")

    merged_pdf = fitz.open()
    for pdf in pdf_list:
        with fitz.open(f"output/temp/{pdf}.pdf") as doc:
            merged_pdf.insert_pdf(doc)
    merged_pdf.save(output_file)
    print(f"✅ PDF successfully created: {output_file}")

# Function to display a loading bar
async def loading_bar(duration):
    for _ in tqdm(range(100), desc="Running Locust",ncols=150, ascii=True):
        await asyncio.sleep(duration / 100)

# Function to clean up environment variables
def cleanup():
    for var in [
        'HYPERSWITCH_HOST_URL',
        'GRAFANA_HOST',
        'GRAFANA_SERVICE_ACCOUNT_TOKEN',
        'GRAFANA_USERNAME',
        'GRAFANA_PASSWORD',
        'STORAGE_PERMISSION',
        'POSTGRES_USERNAME',
        'POSTGRES_PASSWORD',
        'POSTGRES_DBNAME',
        'POSTGRES_HOST',
        'POSTGRES_PORT',
    ]:
        os.environ.pop(var, None)

    # clear temporary files/folders created during load-test
    temp_dir = Path("output/temp").resolve()
    if temp_dir.exists():
        shutil.rmtree(temp_dir)

    # delete .secrets.env file if it exists
    secrets_file = Path(".secrets.env").resolve()
    if secrets_file.exists():
        secrets_file.unlink()

# Function to handle keyboard interrupts
def handle_interrupt(sig, frame):
    print("\n❌ Keyboard interrupt detected.")
    cleanup()
    exit(1)

# Register signal handlers for graceful shutdown
signal.signal(signal.SIGINT, handle_interrupt)
signal.signal(signal.SIGTERM, handle_interrupt)

async def main():
    # Create output directories
    Path("output").mkdir(parents=True, exist_ok=True)
    Path("output/snapshots").mkdir(parents=True, exist_ok=True)
    Path("output/temp").mkdir(parents=True, exist_ok=True)

    # Get all the required inputs
    regular_transactions = int(input("Enter the no. of transactions per year during usual traffic : "))
    spike_transactions = int(input("Enter the no. of transactions per second [TPS] during spike : "))
    test_duration_normal = 60 * int(input("Enter the duration for the Load Test under regular traffic [in mins] : "))
    test_duration_spike = 60 * int(input("Enter the duration for the Load Test under spike traffic [in mins] : "))
    scaling_factor = int(input("Enter your preferred scaling factor for the server [default is 10x] : ") or 10)
    requirements_content = calculator(regular_transactions,spike_transactions, scaling_factor)

    print("\n🚀 Starting load test...")
    # Check initial storage usage
    initial_storage = float(get_storage_usage("\nEnter the initial disk storage size before load-test [in bytes] : "))

    # Run Locust load test for regular traffic
    run_merchant_create("Regular")
    await run_locust("Regular Traffic", int(NORMAL_RPS)+5, test_duration_normal, "test_normal")

    # Check final storage usage
    final_storage = float(get_storage_usage("\nEnter the final disk storage size after load-test [in bytes] : "))
    total_bytes_regular = final_storage - initial_storage

    print("\n🚀 Initializing spike load test...")

    # Check initial storage usage
    initial_storage = float(get_storage_usage("\nEnter the initial disk storage size before spike-test [in bytes] : "))

    # Run Locust load test for spike
    run_merchant_create("Spike")
    await run_locust("Spike", int(SPIKE_RPS)+5, test_duration_spike, "test_spike")

    # Check final storage usage
    final_storage = float(get_storage_usage("\nEnter the final disk storage size after spike-test [in bytes] : "))
    total_bytes_spike = final_storage - initial_storage

    print("\n✅ Load test completed.")

    print("\n⚙️  Generating Report...")

    total_bytes_list = [total_bytes_regular,total_bytes_spike]

    await generate_med_report_table(requirements_content,total_bytes_list)

    if GRAFANA_PERMISSION == "true":
        with open("dashboards.json", "r") as file:
            data = json.load(file)
        for idx, val in enumerate(data):
            await download_dashboard_pdf(val,idx,int((test_duration_normal+test_duration_spike)/60))

        await append_snap_to_pdf()

    await create_reference_section()
    merge_pdfs()

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except Exception as e:
        print(f"Error occurred: {e}")
    finally:
        cleanup()
