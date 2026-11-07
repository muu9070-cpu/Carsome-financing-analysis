

import streamlit as st
import pandas as pd
import plotly.express as px

from utils.data_loader import (
    load_dashboard_data,
    load_financing_kpis
)


# ============================================================
# 1. PAGE CONFIGURATION
# ============================================================

st.set_page_config(
    page_title="Executive Overview",
    page_icon="📊",
    layout="wide"
)


# ============================================================
# 2. LOAD DATA THROUGH CENTRALIZED DATA LOADER
# ============================================================

try:

    df = load_dashboard_data()
    kpi_df = load_financing_kpis()

except Exception as e:

    st.error(
        f"Unable to load Executive Overview data: {e}"
    )

    st.info(
        "Please check that CARSOME_Financing_Dashboard.csv "
        "is located in data/processed/ or the project root."
    )

    st.stop()


if df.empty or kpi_df.empty:

    st.warning("No dashboard data available.")

    st.stop()


# ============================================================
# 3. PAGE TITLE AND DATA PERIOD
# ============================================================

st.title("Executive Overview")

st.caption(
    "CARSOME Financing Performance | September 2026"
)

st.divider()


# Determine actual dataset date range

if "created_time" in df.columns:

    valid_dates = pd.to_datetime(
        df["created_time"],
        errors="coerce"
    ).dropna()

    if not valid_dates.empty:

        start_date = valid_dates.min().strftime(
            "%d %b %Y"
        )

        end_date = valid_dates.max().strftime(
            "%d %b %Y"
        )

        st.info(
            f"Dataset Period: {start_date} – {end_date} | "
            f"Total Records: {len(df):,}"
        )


# ============================================================
# 4. KEY PERFORMANCE INDICATORS
# ============================================================

st.header("1. Key Performance Indicators")

kpi = kpi_df.iloc[0]

col1, col2, col3, col4 = st.columns(4)

col1.metric(
    "Total Orders",
    f"{int(kpi['total_orders']):,}"
)

col2.metric(
    "Financing Cases",
    f"{int(kpi['financing_cases']):,}"
)

col3.metric(
    "Approved Cases",
    f"{int(kpi['approved_cases']):,}"
)

col4.metric(
    "Accepted Cases",
    f"{int(kpi['accepted_cases']):,}"
)


col5, col6, col7 = st.columns(3)

col5.metric(
    "Disbursement Submitted",
    f"{int(kpi['submitted_cases']):,}"
)

col6.metric(
    "Disbursement Received",
    f"{int(kpi['received_cases']):,}"
)

col7.metric(
    "Completed Orders",
    f"{int(kpi['completed_cases']):,}"
)


st.caption(
    "KPI values are calculated by load_financing_kpis() "
    "from the same order-level dataset."
)

st.divider()


# ============================================================
# 5. FINANCING FUNNEL
# ============================================================

st.header("2. Financing Funnel")

funnel_data = pd.DataFrame({

    "Stage": [
        "Financing Cases",
        "Approved",
        "Accepted",
        "Disbursement Submitted",
        "Disbursement Received",
        "Completed Orders"
    ],

    "Cases": [
        kpi["financing_cases"],
        kpi["approved_cases"],
        kpi["accepted_cases"],
        kpi["submitted_cases"],
        kpi["received_cases"],
        kpi["completed_cases"]
    ]

})

funnel_data["Cases"] = pd.to_numeric(
    funnel_data["Cases"],
    errors="coerce"
).fillna(0)

total_financing = kpi["financing_cases"]

funnel_data["Rate vs Financing Cases"] = (
    funnel_data["Cases"] / total_financing * 100
    if total_financing > 0
    else 0
)


# KPI stage cards

cols = st.columns(3)

for i, row in funnel_data.iterrows():

    with cols[i % 3]:

        st.metric(
            label=row["Stage"],
            value=f"{int(row['Cases']):,}"
        )

        st.caption(
            f"{row['Rate vs Financing Cases']:.1f}% "
            "of financing cases"
        )


# Funnel visualization

fig_funnel = px.funnel(
    funnel_data.iloc[:5],
    x="Cases",
    y="Stage",
    title="Financing Cases by Process Stage",
    color="Stage"
)

fig_funnel.update_layout(
    showlegend=False,
    height=500
)

st.plotly_chart(
    fig_funnel,
    use_container_width=True
)


st.caption(
    "The funnel shows financing cases, approval, acceptance, "
    "disbursement submission and receipt. Completed Orders are "
    "displayed separately because order completion and "
    "disbursement receipt are not equivalent statuses."
)


# Completed orders comparison

st.subheader("Completed Orders")

completed_value = int(
    kpi["completed_cases"]
)

received_value = int(
    kpi["received_cases"]
)

col1, col2 = st.columns(2)

col1.metric(
    "Disbursement Received",
    f"{received_value:,}"
)

col2.metric(
    "Completed Orders",
    f"{completed_value:,}"
)

st.divider()


# ============================================================
# 6. ORDER STATUS DISTRIBUTION
# ============================================================

st.header("3. Order Status Distribution")

status_data = (
    df["order_status"]
    .fillna("Missing / Blank")
    .astype(str)
    .str.strip()
    .replace("", "Missing / Blank")
    .value_counts()
    .reset_index()
)

status_data.columns = [
    "Order Status",
    "Order Count"
]


col1, col2 = st.columns([2, 1])


with col1:

    fig_status = px.bar(
        status_data.sort_values(
            "Order Count",
            ascending=True
        ),
        x="Order Count",
        y="Order Status",
        orientation="h",
        text="Order Count",
        title="Order Count by Status",
        color="Order Count",
        color_continuous_scale="Blues"
    )

    fig_status.update_traces(
        textposition="outside"
    )

    fig_status.update_layout(
        height=500,
        showlegend=False,
        coloraxis_showscale=False,
        xaxis_title="Number of Orders",
        yaxis_title=""
    )

    st.plotly_chart(
        fig_status,
        use_container_width=True
    )


with col2:

    st.subheader("Status Summary")

    st.dataframe(
        status_data.sort_values(
            "Order Count",
            ascending=False
        ),
        use_container_width=True,
        hide_index=True
    )


st.divider()


# ============================================================
# 7. FINANCING FLAG SUMMARY
# ============================================================

st.header("4. Financing Flag Summary")

flag_mapping = {

    "Financing Cases": "financing_case_flag",

    "Approved Cases": "approved_flag",

    "Accepted Cases": "accepted_flag",

    "Disbursement Submitted":
        "disbursement_submitted_flag",

    "Disbursement Received":
        "disbursement_received_flag",

    "Completed Orders": "completed_flag"

}

flag_summary = []

for label, column in flag_mapping.items():

    count = int(
        pd.to_numeric(
            df[column],
            errors="coerce"
        ).fillna(0).sum()
    )

    flag_summary.append({

        "Financing Stage": label,

        "Case Count": count,

        "Percentage of Total Orders": (
            count / len(df) * 100
            if len(df) > 0 else 0
        )

    })


flag_summary_df = pd.DataFrame(
    flag_summary
)

st.dataframe(
    flag_summary_df.round(2),
    use_container_width=True,
    hide_index=True
)


st.divider()


# ============================================================
# 8. DATA PREVIEW
# ============================================================

st.header("5. Order-Level Data Preview")

st.caption(
    "The following records are loaded from "
    "CARSOME_Financing_Dashboard.csv through data_loader.py."
)

preview_columns = [

    "order_id",

    "created_time",

    "order_status",

    "financing_case_flag",

    "approved_flag",

    "accepted_flag",

    "disbursement_submitted_flag",

    "disbursement_received_flag",

    "completed_flag",

    "final_financier"

]

st.dataframe(
    df[preview_columns].head(20),
    use_container_width=True,
    hide_index=True
)


# ============================================================
# 9. EXPORT DATA
# ============================================================

st.header("6. Export Data")

csv_data = df.to_csv(
    index=False
).encode("utf-8-sig")

st.download_button(
    label="Download Financing Dashboard Data",
    data=csv_data,
    file_name="CARSOME_Financing_Dashboard_Export.csv",
    mime="text/csv"
)


# ============================================================
# 10. FOOTER
# ============================================================

st.divider()

st.caption(
    """
    Data Source: CARSOME Financing Dataset

    Source File: CARSOME_Financing_Dashboard.csv

    Data Processing: utils/data_loader.py

    Business Calculations: SQL / Centralized KPI Loader
    """
)
