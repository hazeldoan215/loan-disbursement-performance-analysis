-- 1. Grain Idenityfication

-- applications - grain: application_id

select
    count(*) as total_rows,
    count(distinct application_id) as unique_applications
from loan_application;

-- credit_assessment - grain: application_id
select 
	count(*) as row_count,
	count(distinct ca.application_id ) as unique_applications
from credit_assessment ca 
;

-- loan_disbursement - grain: application_id
select 
	count(*) as total_rows,
	count(distinct ld.application_id ) as unique_applications
from case1_finance.loan_disbursement ld
;

-- customer profile - grain: customer_id

select 
	count(*) as total_customers,
	count(distinct cp.customer_id  ) as unique_customers
from customer_profile cp 
;

-- marketing_performance - grain: date x channel x campaign
select 
	count(*) as total_rows,
	count(distinct mp."date") as dates,
	count(distinct mp.channel) as channels,
	count(distinct mp.campaign) as campaign
from marketing_performance mp 
;

select 
	mp.date::date as date,
	mp.channel,
	mp.campaign,
	count(*) as row_count
from marketing_performance mp 
group by mp.date::date, mp.channel , mp.campaign 
having count(*) > 1
;

-- dim_date - grain: date
select 
	count(*) as total_rows,
	count(distinct dd.date::date ) as unique_dates
from dim_date dd 
;

-- 2. Q1 vs Q2 Baseline
-- 2.1. loan_funnel base table

select
	la.*,
	
	ca.credit_score,
	ca.risk_band,
	ca.approval_status,
	ca.rejection_reason,
	ca.approved_limit,

	ld.disbursed_flag,
	ld.disbursed_amount,
	ld.disbursed_date,
	ld.non_disbursement_reason

from loan_application la 
left join credit_assessment ca 
on la.application_id = ca.application_id 

left join loan_disbursement ld 
on la.application_id = ld.application_id

/* select count(*) as rows,
count(distinct application_id) as uniqueapplication_id 
from loan_funnel 
;*/

-- 2.2. Total Applications
-- Q1 - 100000
select 
	count(*) as q1_total_applications
from loan_application la 
where la.quarter ='Q1'
;

-- Q2 - 135000

select 
	count(*) as q1_total_applications
from loan_application la 
where la.quarter ='Q2'
;

-- 2.3. Approval Rate
-- Q1 - 0.55

with loan_funnel as(
	select
		la.*,
	
		ca.credit_score,
		ca.risk_band,
		ca.approval_status,
		ca.rejection_reason,
		ca.approved_limit,

		ld.disbursed_flag,
		ld.disbursed_amount,
		ld.disbursed_date,
		ld.non_disbursement_reason

	from case1_finance.loan_application la 
	left join case1_finance.credit_assessment ca 
	on la.application_id = ca.application_id 

	left join case1_finance.loan_disbursement ld 
	on la.application_id = ld.application_id
)
select 
	(sum(case when approval_status = 'Approved' then 1 else 0 end) * 1.00) / count(*) as approval_rate
from loan_funnel 
where quarter = 'Q1'
;

-- Q2 - 0.441
with loan_funnel as(
	select
		la.*,
	
		ca.credit_score,
		ca.risk_band,
		ca.approval_status,
		ca.rejection_reason,
		ca.approved_limit,

		ld.disbursed_flag,
		ld.disbursed_amount,
		ld.disbursed_date,
		ld.non_disbursement_reason

	from case1_finance.loan_application la 
	left join case1_finance.credit_assessment ca 
	on la.application_id = ca.application_id 

	left join case1_finance.loan_disbursement ld 
	on la.application_id = ld.application_id
)
select 
	(sum(case when approval_status = 'Approved' then 1 else 0 end) * 1.00) / count(*) as approval_rate
from loan_funnel 
where quarter = 'Q2'
;

-- 2.4. Disbursement Rate 

-- Q1 
with loan_funnel as(
	select
		la.*,
	
		ca.credit_score,
		ca.risk_band,
		ca.approval_status,
		ca.rejection_reason,
		ca.approved_limit,

		ld.disbursed_flag,
		ld.disbursed_amount,
		ld.disbursed_date,
		ld.non_disbursement_reason

	from case1_finance.loan_application la 
	left join case1_finance.credit_assessment ca 
	on la.application_id = ca.application_id 

	left join case1_finance.loan_disbursement ld 
	on la.application_id = ld.application_id
)

select 
	
from loan_funnel
where quarter = 'Q1'
;


