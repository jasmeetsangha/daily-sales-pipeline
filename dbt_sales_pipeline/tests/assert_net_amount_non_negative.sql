select *
from {{ ref('stg_sales') }}
where net_amount is not null
  and net_amount < 0
