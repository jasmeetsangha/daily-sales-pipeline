include .env
export

.PHONY: upload-good upload-bad load dbt-build run-good run-bad full-good full-bad check-output check-rejected

upload-good:
	gcloud storage cp daily_sales_pipeline_demo/incoming/sales_2026_06_10.csv gs://$(BUCKET_NAME)/incoming/sales_2026_06_10.csv

upload-bad:
	gcloud storage cp daily_sales_pipeline_demo/incoming/sales_2026_06_11.csv gs://$(BUCKET_NAME)/incoming/sales_2026_06_11.csv

load:
	uv run python scripts/load_gcs_to_bigquery.py

dbt-build:
	uv run dbt build --project-dir dbt_sales_pipeline

run-good:
	FILE_NAME=sales_2026_06_10.csv uv run python scripts/load_gcs_to_bigquery.py
	uv run dbt build --project-dir dbt_sales_pipeline

run-bad:
	FILE_NAME=sales_2026_06_11.csv uv run python scripts/load_gcs_to_bigquery.py
	uv run dbt build --project-dir dbt_sales_pipeline

full-good:
	gcloud storage cp daily_sales_pipeline_demo/incoming/sales_2026_06_10.csv gs://$(BUCKET_NAME)/incoming/sales_2026_06_10.csv
	FILE_NAME=sales_2026_06_10.csv uv run python scripts/load_gcs_to_bigquery.py
	uv run dbt build --project-dir dbt_sales_pipeline

full-bad:
	gcloud storage cp daily_sales_pipeline_demo/incoming/sales_2026_06_11.csv gs://$(BUCKET_NAME)/incoming/sales_2026_06_11.csv
	FILE_NAME=sales_2026_06_11.csv uv run python scripts/load_gcs_to_bigquery.py
	uv run dbt build --project-dir dbt_sales_pipeline

check-output:
	bq query --use_legacy_sql=false \
	"SELECT * FROM \`$(PROJECT_ID).$(ANALYTICS_DATASET).fct_daily_sales\` ORDER BY order_date, store_id"

check-rejected:
	bq query --use_legacy_sql=false \
	"SELECT order_id, order_date, store_id, customer_id, product_id, quantity, unit_price, discount_amount, net_amount, rejection_reason FROM \`$(PROJECT_ID).$(ANALYTICS_DATASET).rejected_sales_records\` ORDER BY rejection_reason, order_id"