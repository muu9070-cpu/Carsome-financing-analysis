

import streamlit as st
import pandas as pd
import plotly.express as px

from utils.data_loader import load_waiting_time_data


# ============================================================
# 1. PAGE CONFIGURATION
# ============================================================

st.title("Waiting Time Analysis")


# ============================================================
# 2. HELPER FUNCTIONS
# ============================================================

def number_format(value):

    if pd.isna(value):
        return "N/A"

    return f"{value:,.0f}"


def decimal_format(value):

    if pd.isna(value):
        return "N/A"

    return f"{value:.2f}"


# ============================================================
# 3. WAITING TIME ANALYSIS PAGE
# ============================================================

def show_waiting_time_analysis():

    st.title("Waiting Time Analysis")

    st.caption(
        "Analysis of disbursement cases that have been submitted "
        "but whose funds have not yet been received."
    )

    # --------------------------------------------------------
    # 1. Load Data from Centralized Data Loader
    # --------------------------------------------------------

    try:

        waiting_df = load_waiting_time_data()

    except (FileNotFoundError, ValueError) as e:

        st.error(str(e))

        st.info(
            "Please verify that "
            "CARSOME_Waiting_Time_Analysis.csv "
            "is available in data/processed/."
        )

        return

    except Exception as e:

        st.error(
            f"Unable to load waiting time data: {e}"
        )

        return

    if waiting_df.empty:

        st.warning(
            "No waiting time records available."
        )

        return

    # Ensure numeric columns are properly formatted.
    # The centralized loader already performs this conversion.
    numeric_columns = [
        "submitted_not_received_cases",
        "cases_with_submission_date",
        "cases_missing_submission_date",
        "avg_wait_days",
        "max_wait_days",
        "wait_0_to_7_days",
        "wait_8_to_14_days",
        "wait_15_to_30_days",
        "wait_over_30_days"
    ]

    for col in numeric_columns:

        waiting_df[col] = pd.to_numeric(
            waiting_df[col],
            errors="coerce"
        )

    # Fixed snapshot date from original SQL
    snapshot_date = "13 October 2026"

    st.caption(
        f"Snapshot Date: {snapshot_date} | "
        "Source: CARSOME Financing Dataset"
    )

    st.divider()

    # --------------------------------------------------------
    # 2. Overall Waiting Time Overview
    # --------------------------------------------------------

    st.header("1. Overall Waiting Time Overview")

    total_pending = int(
        waiting_df["submitted_not_received_cases"]
        .fillna(0)
        .sum()
    )

    total_with_date = int(
        waiting_df["cases_with_submission_date"]
        .fillna(0)
        .sum()
    )

    total_missing_date = int(
        waiting_df["cases_missing_submission_date"]
        .fillna(0)
        .sum()
    )

    total_0_7 = int(
        waiting_df["wait_0_to_7_days"]
        .fillna(0)
        .sum()
    )

    total_8_14 = int(
        waiting_df["wait_8_to_14_days"]
        .fillna(0)
        .sum()
    )

    total_15_30 = int(
        waiting_df["wait_15_to_30_days"]
        .fillna(0)
        .sum()
    )

    total_over_30 = int(
        waiting_df["wait_over_30_days"]
        .fillna(0)
        .sum()
    )

    col1, col2, col3 = st.columns(3)

    col1.metric(
        "Submitted but Not Received",
        number_format(total_pending)
    )

    col2.metric(
        "Cases with Submission Date",
        number_format(total_with_date)
    )

    col3.metric(
        "Cases Missing Submission Date",
        number_format(total_missing_date)
    )

    col4, col5, col6, col7 = st.columns(4)

    col4.metric(
        "0–7 Days",
        number_format(total_0_7)
    )

    col5.metric(
        "8–14 Days",
        number_format(total_8_14)
    )

    col6.metric(
        "15–30 Days",
        number_format(total_15_30)
    )

    col7.metric(
        "Over 30 Days",
        number_format(total_over_30)
    )

    st.caption(
        "Waiting time is calculated only for submitted cases "
        "that have not yet received disbursement. "
        "Missing submission dates are excluded from waiting-day "
        "calculations."
    )

    st.divider()

    # --------------------------------------------------------
    # 3. Waiting Time Distribution
    # --------------------------------------------------------

    st.header("2. Waiting Time Distribution")

    waiting_distribution = pd.DataFrame({

        "Waiting Period": [
            "0–7 Days",
            "8–14 Days",
            "15–30 Days",
            "Over 30 Days"
        ],

        "Cases": [
            total_0_7,
            total_8_14,
            total_15_30,
            total_over_30
        ]
    })

    fig_distribution = px.bar(
        waiting_distribution,
        x="Waiting Period",
        y="Cases",
        text="Cases",
        title="Distribution of Outstanding Disbursement Cases",
        labels={
            "Waiting Period": "Waiting Period",
            "Cases": "Number of Cases"
        },
        color="Waiting Period",
        color_discrete_sequence=[
            "#83C9F4",
            "#4A9FE5",
            "#0866C6",
            "#D9534F"
        ]
    )

    fig_distribution.update_traces(
        textposition="outside"
    )

    fig_distribution.update_layout(
        height=450,
        showlegend=False,
        yaxis_title="Number of Cases",
        xaxis_title=""
    )

    st.plotly_chart(
        fig_distribution,
        use_container_width=True
    )

    st.divider()

    # --------------------------------------------------------
    # 4. Waiting Time by Financier
    # --------------------------------------------------------

    st.header("3. Waiting Time by Financier")

    financier_waiting = waiting_df.sort_values(
        "avg_wait_days",
        ascending=True,
        na_position="first"
    )

    fig_avg_wait = px.bar(
        financier_waiting,
        x="avg_wait_days",
        y="financier",
        orientation="h",
        text="avg_wait_days",
        title="Average Waiting Days by Financier",
        labels={
            "financier": "Financier",
            "avg_wait_days": "Average Waiting Days"
        }
    )

    fig_avg_wait.update_traces(
        texttemplate="%{x:.1f} days",
        textposition="outside",
        marker_color="#0866C6"
    )

    fig_avg_wait.update_layout(
        height=500,
        xaxis_title="Average Waiting Days",
        yaxis_title=""
    )

    st.plotly_chart(
        fig_avg_wait,
        use_container_width=True
    )

    # --------------------------------------------------------
    # 5. Maximum Waiting Time by Financier
    # --------------------------------------------------------

    st.subheader(
        "Maximum Waiting Days by Financier"
    )

    financier_max_wait = waiting_df.sort_values(
        "max_wait_days",
        ascending=True,
        na_position="first"
    )

    fig_max_wait = px.bar(
        financier_max_wait,
        x="max_wait_days",
        y="financier",
        orientation="h",
        text="max_wait_days",
        title="Maximum Outstanding Waiting Days by Financier",
        labels={
            "financier": "Financier",
            "max_wait_days": "Maximum Waiting Days"
        }
    )

    fig_max_wait.update_traces(
        texttemplate="%{x:.0f} days",
        textposition="outside",
        marker_color="#D9534F"
    )

    fig_max_wait.update_layout(
        height=500,
        xaxis_title="Maximum Waiting Days",
        yaxis_title=""
    )

    st.plotly_chart(
        fig_max_wait,
        use_container_width=True
    )

    st.divider()

    # --------------------------------------------------------
    # 6. Waiting Time Breakdown by Financier
    # --------------------------------------------------------

    st.header("4. Waiting Time Breakdown by Financier")

    bucket_columns = [
        "wait_0_to_7_days",
        "wait_8_to_14_days",
        "wait_15_to_30_days",
        "wait_over_30_days"
    ]

    bucket_labels = {
        "wait_0_to_7_days": "0–7 Days",
        "wait_8_to_14_days": "8–14 Days",
        "wait_15_to_30_days": "15–30 Days",
        "wait_over_30_days": "Over 30 Days"
    }

    breakdown_df = waiting_df[
        ["financier"] + bucket_columns
    ].copy()

    breakdown_chart = breakdown_df.melt(
        id_vars="financier",
        value_vars=bucket_columns,
        var_name="Waiting Period",
        value_name="Cases"
    )

    breakdown_chart["Waiting Period"] = (
        breakdown_chart["Waiting Period"]
        .map(bucket_labels)
    )

    fig_breakdown = px.bar(
        breakdown_chart,
        x="financier",
        y="Cases",
        color="Waiting Period",
        barmode="stack",
        title=(
            "Outstanding Cases by Waiting Period "
            "and Financier"
        ),
        labels={
            "financier": "Financier",
            "Cases": "Number of Cases",
            "Waiting Period": "Waiting Period"
        },
        color_discrete_sequence=[
            "#83C9F4",
            "#4A9FE5",
            "#0866C6",
            "#D9534F"
        ]
    )

    fig_breakdown.update_layout(
        height=550,
        xaxis_tickangle=-35,
        xaxis_title="Financier",
        yaxis_title="Number of Cases"
    )

    st.plotly_chart(
        fig_breakdown,
        use_container_width=True
    )

    st.divider()

    # --------------------------------------------------------
    # 7. Financier Detail Explorer
    # --------------------------------------------------------

    st.header("5. Financier Detail Explorer")

    financier_list = sorted(
        waiting_df["financier"]
        .dropna()
        .unique()
        .tolist()
    )

    if financier_list:

        selected_financier = st.selectbox(
            "Select a financier",
            financier_list,
            key="waiting_time_financier_select"
        )

        selected_rows = waiting_df[
            waiting_df["financier"] == selected_financier
        ]

        if not selected_rows.empty:

            selected_data = selected_rows.iloc[0]

            st.subheader(
                f"{selected_financier} - Waiting Time Details"
            )

            detail_col1, detail_col2, detail_col3 = st.columns(3)

            detail_col1.metric(
                "Submitted but Not Received",
                number_format(
                    selected_data["submitted_not_received_cases"]
                )
            )

            detail_col2.metric(
                "Average Waiting Days",
                decimal_format(
                    selected_data["avg_wait_days"]
                )
            )

            detail_col3.metric(
                "Maximum Waiting Days",
                number_format(
                    selected_data["max_wait_days"]
                )
            )

            detail_col4, detail_col5, detail_col6 = st.columns(3)

            detail_col4.metric(
                "0–7 Days",
                number_format(
                    selected_data["wait_0_to_7_days"]
                )
            )

            detail_col5.metric(
                "8–14 Days",
                number_format(
                    selected_data["wait_8_to_14_days"]
                )
            )

            detail_col6.metric(
                "Over 30 Days",
                number_format(
                    selected_data["wait_over_30_days"]
                )
            )

            selected_distribution = pd.DataFrame({

                "Waiting Period": [
                    "0–7 Days",
                    "8–14 Days",
                    "15–30 Days",
                    "Over 30 Days"
                ],

                "Cases": [
                    selected_data["wait_0_to_7_days"],
                    selected_data["wait_8_to_14_days"],
                    selected_data["wait_15_to_30_days"],
                    selected_data["wait_over_30_days"]
                ]
            })

            fig_detail = px.bar(
                selected_distribution,
                x="Waiting Period",
                y="Cases",
                text="Cases",
                title=(
                    f"{selected_financier} - "
                    "Waiting Time Distribution"
                ),
                labels={
                    "Waiting Period": "Waiting Period",
                    "Cases": "Number of Cases"
                },
                color="Waiting Period",
                color_discrete_sequence=[
                    "#83C9F4",
                    "#4A9FE5",
                    "#0866C6",
                    "#D9534F"
                ]
            )

            fig_detail.update_traces(
                textposition="outside"
            )

            fig_detail.update_layout(
                height=400,
                showlegend=False
            )

            st.plotly_chart(
                fig_detail,
                use_container_width=True
            )

    else:

        st.warning(
            "No financier records available."
        )

    st.divider()

    # --------------------------------------------------------
    # 8. Waiting Time Data Summary
    # --------------------------------------------------------

    st.header("6. Waiting Time Data Summary")

    summary_columns = [
        "financier",
        "submitted_not_received_cases",
        "cases_with_submission_date",
        "cases_missing_submission_date",
        "avg_wait_days",
        "max_wait_days",
        "wait_0_to_7_days",
        "wait_8_to_14_days",
        "wait_15_to_30_days",
        "wait_over_30_days"
    ]

    summary_df = waiting_df[
        summary_columns
    ].copy()

    summary_df = summary_df.rename(
        columns={
            "financier": "Financier",
            "submitted_not_received_cases":
                "Submitted Not Received",
            "cases_with_submission_date":
                "Cases with Submission Date",
            "cases_missing_submission_date":
                "Missing Submission Date",
            "avg_wait_days": "Average Waiting Days",
            "max_wait_days": "Maximum Waiting Days",
            "wait_0_to_7_days": "0–7 Days",
            "wait_8_to_14_days": "8–14 Days",
            "wait_15_to_30_days": "15–30 Days",
            "wait_over_30_days": "Over 30 Days"
        }
    )

    st.dataframe(
        summary_df.sort_values(
            "Submitted Not Received",
            ascending=False
        ).round(2),
        use_container_width=True,
        hide_index=True
    )

    st.caption(
        "Data Source: CARSOME Financing Dataset | "
        f"{total_pending:,} submitted but not received cases. "
        f"Snapshot date: {snapshot_date}."
    )

    st.info(
        "Interpretation Note: Waiting time represents outstanding "
        "disbursement reconciliation status as of the fixed snapshot "
        "date. It should not be interpreted as a confirmed SLA breach "
        "or as the actual processing time of completed cases."
    )


# ============================================================
# 4. RUN PAGE
# ============================================================

show_waiting_time_analysis()
