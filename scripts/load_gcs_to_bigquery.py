import os
from google.cloud import bigquery


PROJECT_ID = os.environ["PROJECT_ID"]
BUCKET_NAME = os.environ["BUCKET_NAME"]
RAW_DATASET = os.environ.get("RAW_DATASET", "sales_raw")
FILE_NAME = os.environ["FILE_NAME"]

TABLE_ID = f"{PROJECT_ID}.{RAW_DATASET}.sales_daily"
GCS_URI = f"gs://{BUCKET_NAME}/incoming/{FILE_NAME}"


def main():
    client = bigquery.Client(project=PROJECT_ID)

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
    print(f"Target table: {TABLE_ID}")

    load_job = client.load_table_from_uri(
        GCS_URI,
        TABLE_ID,
        job_config=job_config,
    )

    load_job.result()

    table = client.get_table(TABLE_ID)

    print("Load complete.")
    print(f"Rows loaded: {table.num_rows}")
    print(f"Table: {TABLE_ID}")


if __name__ == "__main__":
    main()
