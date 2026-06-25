with history as (

    select *
    from {{ source('sales_raw', 'sales_daily_history') }}

),

summary as (

    select
        run_id,
        source_file,
        min(loaded_at) as loaded_at,
        count(*) as raw_row_count,
        count(distinct order_id) as distinct_order_count

    from history
    group by run_id, source_file

)

select *
from summary
