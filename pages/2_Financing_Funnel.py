


import streamlit as st
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go

from utils.data_loader import load_dashboard_data


# ============================================================
# 1. PAGE CONFIGURATION
# ============================================================

st.set_page_config(
    page_title="Financing Funnel | CARSOME",
    page_icon="📊",
    layout="wide"
)

st.title("Financing Funnel Analysis")

st.caption(
    "CARSOME Malaysia | September 2026 | "
    "Financing Process Performance"
)

st.divider()


# ============================================================
# 2. LOAD DATA
# ============================================================

@st.cache_data(ttl=300)
def get_data():

    df = load_dashboard_data()

    required_flags = [
        "financing_case_flag",
        "approved_flag",
        "accepted_flag",
        "disbursement_submitted_flag",
        "disbursement_received_flag",
        "completed_flag"
    ]

    for col in required_flags:
        df[col] = pd.to_numeric(
            df[col], errors="coerce"
        ).fillna(0).astype(int)

    return df


try:
    df = get_data()

except Exception as e:
    st.error(f"Unable to load Financing Funnel data: {e}")
    st.stop()


# ============================================================
# 3. DATA VALIDATION
# ============================================================

TOTAL_ORDERS = len(df)

FINANCING = int(df["financing_case_flag"].sum())
APPROVED = int(df["approved_flag"].sum())
ACCEPTED = int(df["accepted_flag"].sum())
SUBMITTED = int(df["disbursement_submitted_flag"].sum())
RECEIVED = int(df["disbursement_received_flag"].sum())
COMPLETED = int(df["completed_flag"].sum())

SUBMITTED_NOT_RECEIVED = int(
    (
        (df["disbursement_submitted_flag"] == 1) &
        (df["disbursement_received_flag"] == 0)
    ).sum()
)

COMPLETED_NOT_RECEIVED = int(
    (
        (df["completed_flag"] == 1) &
        (df["disbursement_received_flag"] == 0)
    ).sum()
)

RECEIVED_NOT_COMPLETED = int(
    (
        (df["disbursement_received_flag"] == 1) &
        (df["completed_flag"] == 0)
    ).sum()
)


# ============================================================
# 4. HELPER FUNCTIONS
# ============================================================

def conversion_rate(current, previous):

    if previous == 0:
        return 0.0

    return current / previous * 100


def format_number(value):

    return f"{int(value):,}"


def format_pct(value):

    return f"{value:.2f}%"


# ============================================================
# 5. EXECUTIVE KPI OVERVIEW
# ============================================================

st.header("1. Financing Funnel Overview")

# Row 1: Overall Performance
kpi1, kpi2, kpi3 = st.columns(3)

kpi1.metric(
    "Total Orders",
    format_number(TOTAL_ORDERS)
)

kpi2.metric(
    "Financing Cases",
    format_number(FINANCING)
)

kpi3.metric(
    "Financing Rate",
    format_pct(conversion_rate(FINANCING, TOTAL_ORDERS))
)

# Row 2: Key Financing Stages
kpi4, kpi5, kpi6 = st.columns(3)

kpi4.metric(
    "Approved Cases",
    format_number(APPROVED)
)

kpi5.metric(
    "Disbursement Received",
    format_number(RECEIVED)
)

kpi6.metric(
    "Completed Orders",
    format_number(COMPLETED)
)

# Row 3: Conversion Performance
st.subheader("Key Conversion Rates")

r1, r2, r3 = st.columns(3)

r1.metric(
    "Financing to Approval",
    format_pct(conversion_rate(APPROVED, FINANCING))
)

r2.metric(
    "Approval to Acceptance",
    format_pct(conversion_rate(ACCEPTED, APPROVED))
)

r3.metric(
    "Submission to Received",
    format_pct(conversion_rate(RECEIVED, SUBMITTED))
)

st.divider()


# ============================================================
# 6. MAIN FINANCING FUNNEL
# ============================================================

st.header("2. Main Financing Funnel")

st.markdown(
    "Track the progression of financing cases "
    "from initial financing to disbursement received."
)

stage_names = [
    "Financing Case",
    "Approved",
    "Accepted",
    "Disbursement Submitted",
    "Disbursement Received"
]

stage_values = [
    FINANCING,
    APPROVED,
    ACCEPTED,
    SUBMITTED,
    RECEIVED
]

funnel_df = pd.DataFrame({
    "Stage": stage_names,
    "Cases": stage_values
})

fig_funnel = go.Figure(
    go.Funnel(
        y=funnel_df["Stage"],
        x=funnel_df["Cases"],
        textinfo="value+percent previous",
        marker={
            "color": [
                "#0D47A1",
                "#1565C0",
                "#1976D2",
                "#42A5F5",
                "#81C784"
            ]
        },
        connector={
            "line": {
                "color": "#BDBDBD",
                "width": 1
            }
        }
    )
)

fig_funnel.update_layout(
    title="Financing Stage Progression",
    height=480,
    margin=dict(l=30, r=30, t=70, b=30),
    showlegend=False
)

st.plotly_chart(
    fig_funnel,
    use_container_width=True
)


# ============================================================
# 7. STAGE CONVERSION ANALYSIS
# ============================================================

st.subheader("Stage Conversion Analysis")

stage_data = []

for i in range(len(stage_names)):

    current = stage_values[i]

    if i == 0:
        previous = None
        conversion = None
        dropoff = None

    else:
        previous = stage_values[i - 1]

        conversion = conversion_rate(
            current, previous
        )

        dropoff = previous - current

    stage_data.append({
        "Stage": stage_names[i],
        "Stage Cases": current,
        "Previous Stage Cases": previous,
        "Conversion Rate (%)": conversion,
        "Stage Drop-off Cases": dropoff
    })


stage_table = pd.DataFrame(stage_data)

display_stage = stage_table.copy()

display_stage["Stage Cases"] = (
    display_stage["Stage Cases"].map(format_number)
)

display_stage["Previous Stage Cases"] = (
    display_stage["Previous Stage Cases"].apply(
        lambda x: "-" if pd.isna(x)
        else format_number(x)
    )
)

display_stage["Conversion Rate (%)"] = (
    display_stage["Conversion Rate (%)"].apply(
        lambda x: "-" if pd.isna(x)
        else format_pct(x)
    )
)

display_stage["Stage Drop-off Cases"] = (
    display_stage["Stage Drop-off Cases"].apply(
        lambda x: "-" if pd.isna(x)
        else format_number(x)
    )
)

st.dataframe(
    display_stage,
    use_container_width=True,
    hide_index=True
)


# Conversion chart

conversion_df = stage_table.iloc[1:].copy()

fig_conversion = px.bar(
    conversion_df,
    x="Stage",
    y="Conversion Rate (%)",
    text="Conversion Rate (%)",
    title="Stage-to-Stage Conversion Rate",
    color="Conversion Rate (%)",
    color_continuous_scale="Blues"
)

fig_conversion.update_traces(
    texttemplate="%{text:.2f}%",
    textposition="outside"
)

fig_conversion.update_layout(
    height=400,
    yaxis_title="Conversion Rate (%)",
    xaxis_title="Financing Stage",
    yaxis_range=[0, 110],
    coloraxis_showscale=False
)

st.plotly_chart(
    fig_conversion,
    use_container_width=True
)


# ============================================================
# 8. COMPLETION RECONCILIATION
# ============================================================

st.divider()

st.header("3. Completion Reconciliation")

st.markdown(
    """
    Compare disbursement received status with order completion status.

    Order Completed and Disbursement Received represent
    different business events and should not be treated
    as interchangeable.
    """
)

reconciliation = pd.crosstab(
    df["disbursement_received_flag"],
    df["completed_flag"]
)

reconciliation = reconciliation.reindex(
    index=[0, 1],
    columns=[0, 1],
    fill_value=0
)

reconciliation.index = [
    "Not Received",
    "Received"
]

reconciliation.columns = [
    "Not Completed",
    "Completed"
]

reconciliation.index.name = "Disbursement Status"

st.subheader("Received vs Completed")

st.dataframe(
    reconciliation,
    use_container_width=True
)

r1, r2, r3 = st.columns(3)

r1.metric(
    "Completed but Not Received",
    format_number(COMPLETED_NOT_RECEIVED)
)

r2.metric(
    "Received but Not Completed",
    format_number(RECEIVED_NOT_COMPLETED)
)

r3.metric(
    "Both Received and Completed",
    format_number(
        int(
            (
                (df["disbursement_received_flag"] == 1) &
                (df["completed_flag"] == 1)
            ).sum()
        )
    )
)


# Reconciliation chart

recon_chart = pd.DataFrame({
    "Category": [
        "Not Received",
        "Received"
    ],
    "Not Completed": [
        int(reconciliation.loc["Not Received", "Not Completed"]),
        int(reconciliation.loc["Received", "Not Completed"])
    ],
    "Completed": [
        int(reconciliation.loc["Not Received", "Completed"]),
        int(reconciliation.loc["Received", "Completed"])
    ]
})

fig_recon = px.bar(
    recon_chart,
    x="Category",
    y=["Not Completed", "Completed"],
    barmode="stack",
    title="Order Completion Status by Disbursement Status",
    text_auto=True,
    color_discrete_sequence=[
        "#90CAF9",
        "#1565C0"
    ]
)

fig_recon.update_layout(
    height=400,
    xaxis_title="Disbursement Status",
    yaxis_title="Number of Orders",
    legend_title="Order Status"
)

st.plotly_chart(
    fig_recon,
    use_container_width=True
)


# ============================================================
# 9. FLAG CONSISTENCY AUDIT
# ============================================================

st.divider()

st.header("4. Financing Flag Consistency Audit")

st.markdown(
    """
    Check whether financing stage flags follow the expected
    sequential progression.
    """
)

flag_sequence = [
    ("Financing", "financing_case_flag"),
    ("Approved", "approved_flag"),
    ("Accepted", "accepted_flag"),
    ("Submitted", "disbursement_submitted_flag"),
    ("Received", "disbursement_received_flag")
]

audit_rows = []

for i in range(len(flag_sequence) - 1):

    previous_name, previous_col = flag_sequence[i]

    current_name, current_col = flag_sequence[i + 1]

    violations = int(
        (
            (df[previous_col] == 0) &
            (df[current_col] == 1)
        ).sum()
    )

    audit_rows.append({
        "Previous Stage": previous_name,
        "Next Stage": current_name,
        "Inconsistent Cases": violations,
        "Audit Result": (
            "Pass" if violations == 0 else "Review Required"
        )
    })

audit_df = pd.DataFrame(audit_rows)

total_violations = int(
    audit_df["Inconsistent Cases"].sum()
)

a1, a2 = st.columns(2)

a1.metric(
    "Total Sequential Flag Violations",
    format_number(total_violations)
)

a2.metric(
    "Audit Checks Passed",
    f"{int((audit_df['Inconsistent Cases'] == 0).sum())}/4"
)

st.dataframe(
    audit_df,
    use_container_width=True,
    hide_index=True
)

if total_violations == 0:

    st.success(
        "All four sequential financing stage checks passed."
    )

else:

    st.warning(
        "Some financing stage flags require further investigation."
    )

st.info(
    "Note: Completed is excluded from the sequential flag audit "
    "because completion and disbursement received are not "
    "strictly interchangeable business stages."
)


# ============================================================
# 10. SUBMITTED BUT NOT RECEIVED
# ============================================================

st.divider()

st.header("5. Submitted but Not Received")

st.markdown(
    """
    Identify financing cases where disbursement has been submitted
    but the received flag has not yet been recorded.
    """
)

waiting_df = df[
    (df["disbursement_submitted_flag"] == 1) &
    (df["disbursement_received_flag"] == 0)
].copy()

w1, w2 = st.columns(2)

w1.metric(
    "Submitted but Not Received",
    format_number(len(waiting_df))
)

w2.metric(
    "Not Received Rate",
    format_pct(
        conversion_rate(
            len(waiting_df), SUBMITTED
        )
    )
)


# Breakdown by financier

waiting_df["Financier"] = (
    waiting_df["final_financier"]
    .fillna("Missing / Blank")
    .astype(str)
    .str.strip()
    .replace("", "Missing / Blank")
)

waiting_by_financier = (
    waiting_df
    .groupby("Financier")
    .agg(
        Not_Received_Cases=("order_id", "count")
    )
    .reset_index()
    .sort_values(
        "Not_Received_Cases",
        ascending=False
    )
)

fig_waiting = px.bar(
    waiting_by_financier,
    x="Financier",
    y="Not_Received_Cases",
    text="Not_Received_Cases",
    title="Submitted but Not Received by Financier",
    color="Not_Received_Cases",
    color_continuous_scale="Oranges"
)

fig_waiting.update_traces(
    textposition="outside"
)

fig_waiting.update_layout(
    height=450,
    xaxis_title="Financier",
    yaxis_title="Number of Cases",
    coloraxis_showscale=False
)

st.plotly_chart(
    fig_waiting,
    use_container_width=True
)


# ============================================================
# 11. ORDER-LEVEL DETAIL
# ============================================================

st.subheader("Submitted but Not Received - Order Details")

detail_columns = [
    "order_id",
    "created_time",
    "order_status",
    "final_financier",
    "final_loan_status",
    "final_loan_type",
    "disbursement_submit_date",
    "disbursement_receive_date"
]

available_columns = [
    col for col in detail_columns
    if col in waiting_df.columns
]

waiting_display = waiting_df[available_columns].copy()

st.dataframe(
    waiting_display,
    use_container_width=True,
    hide_index=True
)

csv_export = waiting_display.to_csv(
    index=False
).encode("utf-8-sig")

st.download_button(
    label="Download Submitted but Not Received Cases",
    data=csv_export,
    file_name="submitted_not_received_cases.csv",
    mime="text/csv"
)


# ============================================================
# 12. FINAL DATA SUMMARY
# ============================================================

st.divider()

st.header("6. Dataset Summary")

summary_df = pd.DataFrame({
    "Metric": [
        "Total Orders",
        "Financing Cases",
        "Approved Cases",
        "Accepted Cases",
        "Disbursement Submitted",
        "Disbursement Received",
        "Completed Orders",
        "Submitted but Not Received"
    ],
    "Cases": [
        TOTAL_ORDERS,
        FINANCING,
        APPROVED,
        ACCEPTED,
        SUBMITTED,
        RECEIVED,
        COMPLETED,
        SUBMITTED_NOT_RECEIVED
    ]
})

st.dataframe(
    summary_df,
    use_container_width=True,
    hide_index=True
)

st.caption(
    "Data Source: CARSOME Financing Dashboard CSV | "
    "Cohort: 1 September 2026 – 30 September 2026"
)

st.caption(
    "Business calculations are based on SQL-exported "
    "order-level flags."
)
