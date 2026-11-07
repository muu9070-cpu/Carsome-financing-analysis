


import streamlit as st
import pandas as pd
import plotly.express as px

from utils.data_loader import load_financier_performance_data


# ============================================================
# 1. PAGE CONFIGURATION
# ============================================================

st.title("Financier Performance")

st.caption(
    "Financing Volume | Stage Progress | "
    "Store Performance | Disbursement Conversion | "
    "Financier Assignment Audit"
)


# ============================================================
# 2. LOAD DATA FROM CENTRALIZED DATA LOADER
# ============================================================

def load_dashboard_data():

    data = load_financier_performance_data()

    required_columns = {
        "overall": [
            "financier",
            "total_orders",
            "financing_cases",
            "approved_cases",
            "accepted_cases",
            "submitted_cases",
            "received_cases",
            "completed_cases",
            "financing_to_approval_pct",
            "approval_to_acceptance_pct",
            "submission_to_received_pct"
        ],

        "store": [
            "financier",
            "carsome_store",
            "total_orders",
            "financing_cases",
            "approved_cases",
            "accepted_cases",
            "submitted_cases",
            "received_cases",
            "submission_to_received_pct"
        ],

        "stage": [
            "financier",
            "financing_cases",
            "approved_cases",
            "accepted_cases",
            "submitted_cases",
            "received_cases",
            "financing_to_approval_pct",
            "approval_to_acceptance_pct",
            "acceptance_to_submission_pct",
            "submission_to_received_pct"
        ],

        "assignment": [
            "order_status",
            "financier_field_status",
            "total_orders",
            "financing_cases",
            "approved_cases",
            "accepted_cases",
            "submitted_cases",
            "received_cases",
            "completed_cases",
            "missing_financier_orders"
        ],

        "disbursement": [
            "financier",
            "submitted_cases",
            "received_cases",
            "submitted_not_received_cases",
            "received_conversion_rate_pct",
            "not_received_rate_pct"
        ]
    }

    errors = []

    for dataset_name, columns in required_columns.items():

        if dataset_name not in data:
            errors.append(
                f"Missing dataset: {dataset_name}"
            )
            continue

        missing = [
            col for col in columns
            if col not in data[dataset_name].columns
        ]

        if missing:
            errors.append(
                f"{dataset_name}: {missing}"
            )

    if errors:
        raise ValueError(
            "Dashboard 3 data validation failed:\n"
            + "\n".join(errors)
        )

    return data


# ============================================================
# 3. HELPER FUNCTIONS
# ============================================================

def number_format(value):

    if pd.isna(value):
        return "N/A"

    return f"{value:,.0f}"


def percent_format(value):

    if pd.isna(value):
        return "N/A"

    return f"{value:.2f}%"


def safe_sum(df, column):

    if column not in df.columns:
        return 0

    return pd.to_numeric(
        df[column],
        errors="coerce"
    ).sum()


def exclude_missing_financier(df):

    if "financier" not in df.columns:
        return df.copy()

    return df[
        df["financier"].notna()
        & (
            df["financier"].astype(str).str.strip()
            != "Missing / Blank"
        )
        & (
            df["financier"].astype(str).str.strip()
            != ""
        )
    ].copy()


def clean_numeric_data(data):

    numeric_columns = [
        "total_orders",
        "financing_cases",
        "approved_cases",
        "accepted_cases",
        "submitted_cases",
        "received_cases",
        "completed_cases",
        "missing_financier_orders",
        "financing_to_approval_pct",
        "approval_to_acceptance_pct",
        "acceptance_to_submission_pct",
        "submission_to_received_pct",
        "received_conversion_rate_pct",
        "not_received_rate_pct"
    ]

    cleaned = {}

    for name, df in data.items():

        df = df.copy()

        df.columns = (
            df.columns
            .astype(str)
            .str.strip()
        )

        for col in numeric_columns:

            if col in df.columns:

                df[col] = pd.to_numeric(
                    df[col],
                    errors="coerce"
                )

        for col in df.select_dtypes(
            include=["object", "string"]
        ).columns:

            df[col] = (
                df[col]
                .astype("string")
                .str.strip()
            )

        cleaned[name] = df

    return cleaned


# ============================================================
# 4. MAIN DASHBOARD
# ============================================================

def show_financier_performance(data):

    overall_df = data["overall"].copy()
    store_df = data["store"].copy()
    stage_df = data["stage"].copy()
    assignment_df = data["assignment"].copy()
    disbursement_df = data["disbursement"].copy()

    # Exclude missing financier from bank comparisons.
    # Keep missing financier records in overall and audit data.

    bank_overall_df = exclude_missing_financier(
        overall_df
    )

    bank_stage_df = exclude_missing_financier(
        stage_df
    )

    bank_disbursement_df = exclude_missing_financier(
        disbursement_df
    )

    bank_store_df = exclude_missing_financier(
        store_df
    )

    # ========================================================
    # 1. OVERALL FINANCING PERFORMANCE
    # ========================================================

    st.header("1. Overall Financing Performance")

    total_orders = safe_sum(
        overall_df,
        "total_orders"
    )

    total_financing = safe_sum(
        overall_df,
        "financing_cases"
    )

    total_approved = safe_sum(
        overall_df,
        "approved_cases"
    )

    total_accepted = safe_sum(
        overall_df,
        "accepted_cases"
    )

    total_submitted = safe_sum(
        overall_df,
        "submitted_cases"
    )

    total_received = safe_sum(
        overall_df,
        "received_cases"
    )

    total_completed = safe_sum(
        overall_df,
        "completed_cases"
    )

    missing_financier_cases = safe_sum(
        overall_df[
            overall_df["financier"].astype(str)
            == "Missing / Blank"
        ],
        "financing_cases"
    )

    col1, col2, col3, col4 = st.columns(4)

    col1.metric(
        "Total Orders",
        number_format(total_orders)
    )

    col2.metric(
        "Financing Cases",
        number_format(total_financing)
    )

    col3.metric(
        "Approved Cases",
        number_format(total_approved)
    )

    col4.metric(
        "Accepted Cases",
        number_format(total_accepted)
    )

    col5, col6, col7 = st.columns(3)

    col5.metric(
        "Disbursement Submitted",
        number_format(total_submitted)
    )

    col6.metric(
        "Disbursement Received",
        number_format(total_received)
    )

    col7.metric(
        "Completed Orders",
        number_format(total_completed)
    )

    st.info(
        f"Missing / Blank financier records: "
        f"{number_format(missing_financier_cases)}. "
        "Financier assignment is stage-dependent. "
        "Early-stage conversion rates by final financier "
        "should not be interpreted as independent bank "
        "approval performance."
    )

    st.divider()

    # ========================================================
    # 2. FINANCING VOLUME BY FINANCIER
    # ========================================================

    st.header("2. Financing Volume by Financier")

    volume_df = bank_overall_df.sort_values(
        "financing_cases",
        ascending=True
    )

    if not volume_df.empty:

        fig_volume = px.bar(
            volume_df,
            x="financing_cases",
            y="financier",
            orientation="h",
            text="financing_cases",
            title="Financing Cases by Financier"
        )

        fig_volume.update_traces(
            textposition="outside",
            marker_color="#0866C6"
        )

        fig_volume.update_layout(
            height=max(
                450,
                len(volume_df) * 35
            ),
            xaxis_title="Financing Cases",
            yaxis_title=""
        )

        st.plotly_chart(
            fig_volume,
            use_container_width=True
        )

    else:

        st.info("No financier volume data available.")

    st.caption(
        "Missing / Blank financier cases are excluded from "
        "bank comparisons and retained in the assignment audit."
    )

    st.divider()

    # ========================================================
    # 3. FINANCIER PERFORMANCE SUMMARY
    # ========================================================

    st.header("3. Financier Performance Summary")

    summary_columns = [
        "financier",
        "financing_cases",
        "approved_cases",
        "accepted_cases",
        "submitted_cases",
        "received_cases",
        "completed_cases",
        "submission_to_received_pct"
    ]

    st.dataframe(
        bank_overall_df[
            summary_columns
        ].sort_values(
            "financing_cases",
            ascending=False
        ).round(2),
        use_container_width=True,
        hide_index=True
    )

    st.caption(
        "The summary focuses on case volumes and the "
        "submitted-to-received conversion rate. "
        "Early-stage rates are not used as independent "
        "bank performance indicators."
    )

    st.divider()

    # ========================================================
    # 4. FINANCING STAGE PROGRESSION
    # ========================================================

    st.header("4. Financing Stage Progression")

    st.warning(
        "Financing-to-Approval and Approval-to-Acceptance "
        "rates are affected by final financier assignment. "
        "They are retained in the SQL data but are not used "
        "to rank banks."
    )

    stage_options = {
        "Acceptance to Submission": (
            "acceptance_to_submission_pct"
        ),

        "Submission to Received": (
            "submission_to_received_pct"
        )
    }

    selected_stage = st.selectbox(
        "Select Conversion Stage",
        list(stage_options.keys()),
        key="financier_stage_select"
    )

    selected_metric = stage_options[selected_stage]

    stage_chart_df = bank_stage_df[
        ["financier", selected_metric]
    ].dropna().copy()

    stage_chart_df = stage_chart_df.sort_values(
        selected_metric,
        ascending=True
    )

    if not stage_chart_df.empty:

        fig_stage = px.bar(
            stage_chart_df,
            x=selected_metric,
            y="financier",
            orientation="h",
            text=selected_metric,
            title=f"{selected_stage} by Financier"
        )

        fig_stage.update_traces(
            texttemplate="%{x:.2f}%",
            textposition="outside",
            marker_color="#0866C6"
        )

        fig_stage.update_layout(
            height=max(
                450,
                len(stage_chart_df) * 35
            ),
            xaxis_title="Conversion Rate (%)",
            yaxis_title="",
            xaxis_range=[0, 115]
        )

        st.plotly_chart(
            fig_stage,
            use_container_width=True
        )

    else:

        st.info(
            "No valid conversion rate data available."
        )

    st.subheader("Stage Conversion Data")

    stage_display_columns = [
        "financier",
        "financing_cases",
        "approved_cases",
        "accepted_cases",
        "submitted_cases",
        "received_cases",
        "acceptance_to_submission_pct",
        "submission_to_received_pct"
    ]

    st.dataframe(
        stage_df[
            stage_display_columns
        ].round(2),
        use_container_width=True,
        hide_index=True
    )

    st.caption(
        "The table retains all SQL stage results. "
        "The selected chart only displays the two later-stage "
        "conversion indicators."
    )

    st.divider()

    # ========================================================
    # 5. DISBURSEMENT CONVERSION
    # ========================================================

    st.header("5. Disbursement Submission vs Received")

    if not bank_disbursement_df.empty:

        col1, col2 = st.columns(2)

        with col1:

            received_chart_df = (
                bank_disbursement_df
                .sort_values(
                    "received_conversion_rate_pct",
                    ascending=True
                )
            )

            fig_received = px.bar(
                received_chart_df,
                x="received_conversion_rate_pct",
                y="financier",
                orientation="h",
                text="received_conversion_rate_pct",
                title="Submitted to Received Rate"
            )

            fig_received.update_traces(
                texttemplate="%{x:.2f}%",
                textposition="outside",
                marker_color="#0866C6"
            )

            fig_received.update_layout(
                height=500,
                xaxis_title="Received Conversion Rate (%)",
                yaxis_title="",
                xaxis_range=[0, 115]
            )

            st.plotly_chart(
                fig_received,
                use_container_width=True
            )

        with col2:

            not_received_chart_df = (
                bank_disbursement_df
                .sort_values(
                    "not_received_rate_pct",
                    ascending=True
                )
            )

            fig_not_received = px.bar(
                not_received_chart_df,
                x="not_received_rate_pct",
                y="financier",
                orientation="h",
                text="not_received_rate_pct",
                title="Submitted but Not Received Rate"
            )

            fig_not_received.update_traces(
                texttemplate="%{x:.2f}%",
                textposition="outside",
                marker_color="#E67E22"
            )

            fig_not_received.update_layout(
                height=500,
                xaxis_title="Not Received Rate (%)",
                yaxis_title="",
                xaxis_range=[0, 115]
            )

            st.plotly_chart(
                fig_not_received,
                use_container_width=True
            )

    else:

        st.info(
            "No disbursement conversion data available."
        )

    st.subheader("Disbursement Conversion Details")

    st.dataframe(
        disbursement_df.round(2),
        use_container_width=True,
        hide_index=True
    )

    st.caption(
        "Denominator: Disbursement Submitted Cases. "
        "Received Conversion Rate = Received Cases / "
        "Submitted Cases. This is not the overall bank "
        "approval rate."
    )

    st.divider()

    # ========================================================
    # 6. FINANCIER PERFORMANCE BY CARSOME STORE
    # ========================================================

    st.header("6. Financier Performance by CARSOME Store")

    available_financiers = sorted(
        bank_store_df["financier"]
        .dropna()
        .unique()
        .tolist()
    )

    if available_financiers:

        selected_store_financier = st.selectbox(
            "Select Financier",
            available_financiers,
            key="store_financier_select"
        )

        selected_store_df = bank_store_df[
            bank_store_df["financier"]
            == selected_store_financier
        ].copy()

        store_chart_df = selected_store_df.dropna(
            subset=["submission_to_received_pct"]
        )

        if not store_chart_df.empty:

            store_chart_df = store_chart_df.sort_values(
                "submission_to_received_pct",
                ascending=True
            )

            fig_store = px.bar(
                store_chart_df,
                x="submission_to_received_pct",
                y="carsome_store",
                orientation="h",
                text="submission_to_received_pct",
                title=(
                    f"{selected_store_financier} - "
                    "Submitted to Received Rate by Store"
                )
            )

            fig_store.update_traces(
                texttemplate="%{x:.2f}%",
                textposition="outside",
                marker_color="#0866C6"
            )

            fig_store.update_layout(
                height=max(
                    450,
                    len(store_chart_df) * 28
                ),
                xaxis_title="Conversion Rate (%)",
                yaxis_title="",
                xaxis_range=[0, 115]
            )

            st.plotly_chart(
                fig_store,
                use_container_width=True
            )

        else:

            st.info(
                "No valid store-level conversion rates available."
            )

        st.subheader("Store Performance Details")

        st.dataframe(
            selected_store_df.sort_values(
                "financing_cases",
                ascending=False
            ).round(2),
            use_container_width=True,
            hide_index=True
        )

    else:

        st.info(
            "No assigned financier store data available."
        )

    st.caption(
        "Store refers to the CARSOME sales store, "
        "not the bank's physical branch."
    )

    st.divider()

    # ========================================================
    # 7. FINANCIER ASSIGNMENT AUDIT
    # ========================================================

    st.header("7. Financier Assignment Audit")

    missing_assignment_total = safe_sum(
        assignment_df,
        "missing_financier_orders"
    )

    col1, col2 = st.columns(2)

    col1.metric(
        "Missing Financier Orders",
        number_format(missing_assignment_total)
    )

    col2.metric(
        "Assignment Audit Records",
        number_format(len(assignment_df))
    )

    assignment_pivot = assignment_df.pivot_table(
        index="order_status",
        columns="financier_field_status",
        values="total_orders",
        aggfunc="sum",
        fill_value=0
    ).reset_index()

    st.subheader(
        "Financier Assignment by Order Status"
    )

    st.dataframe(
        assignment_pivot,
        use_container_width=True,
        hide_index=True
    )

    fig_assignment = px.bar(
        assignment_df,
        x="order_status",
        y="total_orders",
        color="financier_field_status",
        barmode="stack",
        title="Financier Assignment Status by Order Status"
    )

    fig_assignment.update_layout(
        height=500,
        xaxis_tickangle=-35,
        xaxis_title="Order Status",
        yaxis_title="Number of Orders"
    )

    st.plotly_chart(
        fig_assignment,
        use_container_width=True
    )

    st.subheader("Assignment Audit Details")

    st.dataframe(
        assignment_df.sort_values(
            "total_orders",
            ascending=False
        ),
        use_container_width=True,
        hide_index=True
    )

    st.caption(
        "Missing / Blank does not necessarily mean a data error. "
        "The financier may not yet have been assigned at the "
        "current order stage."
    )

    st.divider()

    # ========================================================
    # 8. FINANCIER DETAIL EXPLORER
    # ========================================================

    st.header("8. Financier Detail Explorer")

    if available_financiers:

        selected_financier = st.selectbox(
            "Choose a Financier",
            available_financiers,
            key="detail_financier_select"
        )

        detail_overall = bank_overall_df[
            bank_overall_df["financier"]
            == selected_financier
        ]

        detail_stage = bank_stage_df[
            bank_stage_df["financier"]
            == selected_financier
        ]

        detail_disbursement = bank_disbursement_df[
            bank_disbursement_df["financier"]
            == selected_financier
        ]

        if not detail_overall.empty:

            row = detail_overall.iloc[0]

            st.subheader(
                f"{selected_financier} - Performance Overview"
            )

            c1, c2, c3 = st.columns(3)

            c1.metric(
                "Financing Cases",
                number_format(row["financing_cases"])
            )

            c2.metric(
                "Approved Cases",
                number_format(row["approved_cases"])
            )

            c3.metric(
                "Accepted Cases",
                number_format(row["accepted_cases"])
            )

            c4, c5, c6 = st.columns(3)

            c4.metric(
                "Submitted Cases",
                number_format(row["submitted_cases"])
            )

            c5.metric(
                "Received Cases",
                number_format(row["received_cases"])
            )

            c6.metric(
                "Completed Cases",
                number_format(row["completed_cases"])
            )

            st.metric(
                "Submitted to Received Rate",
                percent_format(
                    row["submission_to_received_pct"]
                )
            )

        if not detail_stage.empty:

            st.subheader("Stage Details")

            st.dataframe(
                detail_stage[
                    [
                        "financier",
                        "financing_cases",
                        "approved_cases",
                        "accepted_cases",
                        "submitted_cases",
                        "received_cases",
                        "acceptance_to_submission_pct",
                        "submission_to_received_pct"
                    ]
                ].round(2),
                use_container_width=True,
                hide_index=True
            )

        if not detail_disbursement.empty:

            st.subheader("Disbursement Details")

            st.dataframe(
                detail_disbursement.round(2),
                use_container_width=True,
                hide_index=True
            )

    else:

        st.info(
            "No financier records available for detail analysis."
        )

    st.divider()

    # ========================================================
    # 9. DATA SOURCE AND DOWNLOADS
    # ========================================================

    st.header("9. Data Source and Downloads")

    st.write(
        "All business metrics are prepared in MySQL SQL Views. "
        "The centralized data_loader.py loads the exported SQL "
        "datasets. Streamlit is responsible for visualization, "
        "filtering and presentation."
    )

    download_datasets = {
        "Overall Performance": overall_df,
        "Store Performance": store_df,
        "Stage Conversion": stage_df,
        "Assignment Audit": assignment_df,
        "Disbursement Conversion": disbursement_df
    }

    for label, dataframe in download_datasets.items():

        csv_data = dataframe.to_csv(
            index=False
        ).encode("utf-8-sig")

        st.download_button(
            label=f"Download {label} CSV",
            data=csv_data,
            file_name=(
                "CARSOME_"
                + label.replace(" ", "_")
                + ".csv"
            ),
            mime="text/csv",
            key=f"download_financier_{label}"
        )

    st.caption(
        "Data Source: MySQL Dashboard Views | "
        "Dashboard 3 - Financier Performance"
    )


# ============================================================
# 5. RUN DASHBOARD
# ============================================================

try:

    dashboard_data = load_dashboard_data()

    dashboard_data = clean_numeric_data(
        dashboard_data
    )

    show_financier_performance(
        dashboard_data
    )

except Exception as e:

    st.error(
        f"Unable to load Financier Performance Dashboard: {e}"
    )

    st.info(
        "Please check the five SQL-exported CSV files in "
        "data/processed/ and verify their column names."
    )
