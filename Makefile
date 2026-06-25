include .env
export

.PHONY: check-history upload-good upload-bad load dbt-build run-good run-bad full-good full-bad check-output check-rejected check-events

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

check-audit:
	bq query --use_legacy_sql=false \
	"SELECT run_id, file_name, started_at, completed_at, row_count, status, error_message FROM \`$(PROJECT_ID).$(RAW_DATASET).pipeline_run_audit\` ORDER BY started_at DESC LIMIT 10"

check-events:
	bq query --use_legacy_sql=false \
	"SELECT event_time, github_run_id, github_run_attempt, file_name, event_type, source_uri, destination_uri, message FROM \`$(PROJECT_ID).$(RAW_DATASET).pipeline_run_events\` ORDER BY event_time DESC LIMIT 20"

check-history:
	bq query --use_legacy_sql=false \
	"SELECT run_id, source_file, MIN(loaded_at) AS loaded_at, COUNT(*) AS row_count FROM \`$(PROJECT_ID).$(RAW_DATASET).sales_daily_history\` GROUP BY run_id, source_file ORDER BY loaded_at DESC LIMIT 20"