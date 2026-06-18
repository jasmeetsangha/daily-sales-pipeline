# Daily Sales Pipeline

This project is a beginner data engineering pipeline using:

- Google Cloud Storage
- BigQuery
- Python
- dbt
- GitHub Actions
- uv

## Pipeline Flow

CSV file
→ GCS bucket
→ BigQuery raw table
→ dbt staging model
→ valid records table
→ rejected records table
→ final daily sales fact table

## GCP Resources

Project:

daily-sales-learning

Bucket:

daily-sales-learning-sales-demo-bucket-965488630989

BigQuery datasets:

- sales_raw
- sales_analytics

## Main Tables / Views

Raw table:

- sales_raw.sales_daily

dbt models:

- sales_analytics.stg_sales
- sales_analytics.valid_sales_records
- sales_analytics.rejected_sales_records
- sales_analytics.fct_daily_sales

## Local Commands

Run good file:

make full-good

Run bad file:

make full-bad

Check final sales output:

make check-output

Check rejected records:

make check-rejected

## GitHub Actions

The workflow is:

.github/workflows/daily-sales-pipeline.yml

It can be run manually from:

Actions → Daily Sales Pipeline → Run workflow

Use this file for success test:

sales_2026_06_10.csv

Use this file for bad-data test:

sales_2026_06_11.csv

## Expected Behavior

Good file:

- Pipeline succeeds
- dbt tests pass
- Final sales summary is created

Bad file:

- Bad rows are loaded into rejected_sales_records
- dbt tests may fail
- Failure is expected because the file contains data quality issues

## Learning Points

This project teaches:

- File-based ingestion
- Cloud Storage landing zones
- BigQuery raw and analytics datasets
- dbt sources, models, refs, and tests
- Data quality validation
- Rejected records handling
- GitHub Actions automation
