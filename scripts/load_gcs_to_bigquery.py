import os
import uuid
from datetime import datetime, timezone

from google.cloud import bigquery


PROJECT_ID = os.environ["PROJECT_ID"]
BUCKET_NAME = os.environ["BUCKET_NAME"]
RAW_DATASET = os.environ.get("RAW_DATASET", "sales_raw")
FILE_NAME = os.environ["FILE_NAME"]

LANDING_TABLE_ID = f"{PROJECT_ID}.{RAW_DATASET}.sales_daily"
HISTORY_TABLE_ID = f"{PROJECT_ID}.{RAW_DATASET}.sales_daily_history"
AUDIT_TABLE_ID = f"{PROJECT_ID}.{RAW_DATASET}.pipeline_run_audit"

INCOMING_PREFIX = os.environ.get("INCOMING_PREFIX", "incoming").strip("/")
GCS_URI = f"gs://{BUCKET_NAME}/{INCOMING_PREFIX}/{FILE_NAME}"


def utc_now():
    return datetime.now(timezone.utc)


def insert_audit_row(
    client,
    run_id,
    file_name,
    started_at,
    completed_at,
    row_count,
    status,
    error_message=None,
):
    row = {
        "run_id": run_id,
        "file_name": file_name,
        "started_at": started_at.isoformat(),
        "completed_at": completed_at.isoformat(),
        "row_count": row_count,
        "status": status,
        "error_message": error_message,
    }

    errors = client.insert_rows_json(AUDIT_TABLE_ID, [row])

    if errors:
        print("Failed to insert audit row:")
        print(errors)
    else:
        print(f"Audit row inserted into {AUDIT_TABLE_ID}")


def load_file_to_landing(client):
    job_config = bigquery.LoadJobConfig(
        source_format=bigquery.SourceFormat.CSV,
        skip_leading_rows=1,
        write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,
        schema=[
            bigquery.SchemaField("order_id", "STRING"),
            bigquery.SchemaField("order_date", "STRING"),
            bigquery.SchemaField("store_id", "STRING"),
            bigquery.SchemaField("customer_id", "STRING"),
            bigquery.SchemaField("product_id", "STRING"),
            bigquery.SchemaField("quantity", "STRING"),
            bigquery.SchemaField("unit_price", "STRING"),
            bigquery.SchemaField("discount_amount", "STRING"),
            bigquery.SchemaField("payment_method", "STRING"),
            bigquery.SchemaField("created_at", "STRING"),
            bigquery.SchemaField("source_file", "STRING"),
        ],
    )

    print(f"Loading file: {GCS_URI}")
    print(f"Landing table: {LANDING_TABLE_ID}")

    load_job = client.load_table_from_uri(
        GCS_URI,
        LANDING_TABLE_ID,
        job_config=job_config,
    )

    load_job.result()

    table = client.get_table(LANDING_TABLE_ID)

    print("Landing load complete.")
    print(f"Rows loaded to landing: {table.num_rows}")

    return table.num_rows


def append_landing_to_history(client, run_id):
    print(f"Appending landing table to history table: {HISTORY_TABLE_ID}")

    query = f"""
    INSERT INTO `{HISTORY_TABLE_ID}` (
      run_id,
      loaded_at,
      order_id,
      order_date,
      store_id,
      customer_id,
      product_id,
      quantity,
      unit_price,
      discount_amount,
      payment_method,
      created_at,
      source_file
    )
    SELECT
      @run_id AS run_id,
      CURRENT_TIMESTAMP() AS loaded_at,
      order_id,
      order_date,
      store_id,
      customer_id,
      product_id,
      quantity,
      unit_price,
      discount_amount,
      payment_method,
      created_at,
      source_file
    FROM `{LANDING_TABLE_ID}`
    """

    job_config = bigquery.QueryJobConfig(
        query_parameters=[
            bigquery.ScalarQueryParameter("run_id", "STRING", run_id),
        ]
    )

    query_job = client.query(query, job_config=job_config)
    query_job.result()

    print("Append to history complete.")


def main():
    run_id = str(uuid.uuid4())
    started_at = utc_now()
    row_count = 0
    status = "STARTED"
    error_message = None

    client = bigquery.Client(project=PROJECT_ID)

    print(f"Run ID: {run_id}")
    print(f"Source URI: {GCS_URI}")
    print(f"Landing table: {LANDING_TABLE_ID}")
    print(f"History table: {HISTORY_TABLE_ID}")

    try:
        row_count = load_file_to_landing(client)
        append_landing_to_history(client, run_id)

        status = "SUCCESS"
        print("Ingestion complete.")
        print(f"Rows loaded and appended: {row_count}")

    except Exception as exc:
        status = "FAILED"
        error_message = str(exc)
        print("Ingestion failed.")
        print(error_message)
        raise

    finally:
        completed_at = utc_now()

        insert_audit_row(
            client=client,
            run_id=run_id,
            file_name=FILE_NAME,
            started_at=started_at,
            completed_at=completed_at,
            row_count=row_count,
            status=status,
            error_message=error_message,
        )


if __name__ == "__main__":
    main()
