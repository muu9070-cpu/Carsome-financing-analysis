

import streamlit as st
import pandas as pd
import plotly.express as px

from utils.data_loader import load_cancellation_data


# ============================================================
# 1. PAGE CONFIGURATION
# ============================================================

st.title("Cancellation Analysis & Recommendations")

st.markdown(
    """
    This dashboard identifies stores requiring cancellation
    investigation by comparing overall, financing and
    non-financing cancellation performance.

    The investigation priorities follow the SQL rules defined
    in `03_cancellation_analysis.sql`.
    """
)

st.divider()


# ============================================================
# 2. LOAD DATA FROM CENTRALIZED DATA LOADER
# ============================================================

def prepare_cancellation_data():

    df = load_cancellation_data()

    if df.empty:
        return df

    # Ensure numeric columns are numeric.
    # The centralized loader already performs this conversion.

    numeric_columns = [
        "total_orders",
        "cancelled_orders",
        "overall_cancellation_rate_pct",
        "financing_orders",
        "financing_cancelled_orders",
        "financing_cancellation_rate_pct",
        "non_financing_orders",
        "non_financing_cancelled_orders",
        "non_financing_cancellation_rate_pct",
        "cancellation_gap_pp"
    ]

    for col in numeric_columns:

        df[col] = pd.to_numeric(
            df[col],
            errors="coerce"
        )

    # Remove records without a usable store label.

    df = df.dropna(
        subset=["store"]
    ).copy()

    return df


# ============================================================
# 3. LOAD AND VALIDATE DATA
# ============================================================

try:

    df = prepare_cancellation_data()

except (FileNotFoundError, ValueError) as e:

    st.error(str(e))

    st.info(
        "Please verify that "
        "CARSOME_Cancellation_Recommendations.csv "
        "is available in data/processed/."
    )

    st.stop()

except Exception as e:

    st.error(
        f"Unable to load cancellation data: {e}"
    )

    st.stop()


if df.empty:

    st.warning(
        "No valid store records found."
    )

    st.stop()


st.caption(
    f"Data Source: CARSOME_Cancellation_Recommendations.csv | "
    f"{len(df):,} store records loaded"
)


# ============================================================
# 4. SIDEBAR FILTERS
# ============================================================

st.sidebar.header("Dashboard Filters")

all_priorities = sorted(
    df["investigation_priority"]
    .dropna()
    .unique()
    .tolist()
)

selected_priorities = st.sidebar.multiselect(
    "Investigation Priority",
    options=all_priorities,
    default=all_priorities,
    key="cancellation_priority_filter"
)

all_stores = sorted(
    df["store"]
    .dropna()
    .unique()
    .tolist()
)

selected_stores = st.sidebar.multiselect(
    "CARSOME Store",
    options=all_stores,
    default=all_stores,
    key="cancellation_store_filter"
)

filtered_df = df[
    df["investigation_priority"].isin(selected_priorities)
    & df["store"].isin(selected_stores)
].copy()


if filtered_df.empty:

    st.warning(
        "No records match the selected filters."
    )

    st.stop()


st.caption(
    f"Filtered Store Records: {len(filtered_df):,} / "
    f"{len(df):,}"
)

st.divider()


# ============================================================
# 5. CANCELLATION OVERVIEW
# ============================================================

st.header("1. Cancellation Overview")

total_orders = filtered_df[
    "total_orders"
].sum()

cancelled_orders = filtered_df[
    "cancelled_orders"
].sum()

overall_rate = (
    cancelled_orders / total_orders * 100
    if total_orders > 0 else 0
)

p1_count = (
    filtered_df["investigation_priority"]
    == "P1 - High Business Impact"
).sum()

p2_count = (
    filtered_df["investigation_priority"]
    == "P2 - Large Cancellation Gap"
).sum()

col1, col2, col3, col4 = st.columns(4)

col1.metric(
    "Total Orders",
    f"{total_orders:,.0f}"
)

col2.metric(
    "Cancelled Orders",
    f"{cancelled_orders:,.0f}"
)

col3.metric(
    "Overall Cancellation Rate",
    f"{overall_rate:.2f}%"
)

col4.metric(
    "P1 + P2 Stores",
    f"{p1_count + p2_count}"
)

st.caption(
    "Overview metrics reflect the currently selected "
    "stores and investigation priorities."
)


# ============================================================
# 6. STORE INVESTIGATION PRIORITY
# ============================================================

st.divider()

st.header("2. Store Investigation Priority")

priority_order = [
    "P1 - High Business Impact",
    "P2 - Large Cancellation Gap",
    "P3 - Regular Monitoring",
    "Low Group Volume - Monitor"
]

priority_counts = (
    filtered_df["investigation_priority"]
    .value_counts()
    .reindex(
        priority_order,
        fill_value=0
    )
    .reset_index()
)

priority_counts.columns = [
    "Investigation Priority",
    "Store Count"
]

fig_priority = px.bar(
    priority_counts,
    x="Investigation Priority",
    y="Store Count",
    text="Store Count",
    title="Number of Stores by Investigation Priority"
)

fig_priority.update_traces(
    textposition="outside"
)

fig_priority.update_layout(
    xaxis_title="Investigation Priority",
    yaxis_title="Number of Stores",
    showlegend=False
)

st.plotly_chart(
    fig_priority,
    use_container_width=True
)


st.subheader("Priority Classification Rules")

priority_rules = pd.DataFrame({

    "Priority": [
        "P1 - High Business Impact",
        "P2 - Large Cancellation Gap",
        "P3 - Regular Monitoring",
        "Low Group Volume - Monitor"
    ],

    "SQL Criteria": [
        (
            "At least 25 cancelled orders and overall "
            "cancellation rate > 34.91%, with both groups "
            "having at least 10 orders."
        ),

        (
            "Non-financing cancellation rate exceeds "
            "financing cancellation rate by at least "
            "20 percentage points, with both groups "
            "having at least 10 orders."
        ),

        (
            "Does not meet P1 or P2 conditions."
        ),

        (
            "Financing or non-financing group has "
            "fewer than 10 orders."
        )
    ]
})

st.dataframe(
    priority_rules,
    use_container_width=True,
    hide_index=True
)


# ============================================================
# 7. STORE CANCELLATION PERFORMANCE
# ============================================================

st.divider()

st.header("3. Store Cancellation Performance")

store_chart_df = filtered_df.sort_values(
    "overall_cancellation_rate_pct",
    ascending=False
)

fig_store = px.bar(
    store_chart_df,
    x="store",
    y="overall_cancellation_rate_pct",
    color="investigation_priority",
    hover_data=[
        "total_orders",
        "cancelled_orders"
    ],
    title="Overall Cancellation Rate by Store"
)

fig_store.update_layout(
    xaxis_title="CARSOME Store",
    yaxis_title="Cancellation Rate (%)",
    xaxis_tickangle=-45
)

st.plotly_chart(
    fig_store,
    use_container_width=True
)


fig_volume = px.bar(
    store_chart_df.sort_values(
        "cancelled_orders",
        ascending=False
    ),
    x="store",
    y="cancelled_orders",
    color="investigation_priority",
    title="Cancelled Order Volume by Store"
)

fig_volume.update_layout(
    xaxis_title="CARSOME Store",
    yaxis_title="Cancelled Orders",
    xaxis_tickangle=-45
)

st.plotly_chart(
    fig_volume,
    use_container_width=True
)


# ============================================================
# 8. FINANCING VS NON-FINANCING COMPARISON
# ============================================================

st.divider()

st.header("4. Financing vs Non-financing Comparison")

comparison_df = filtered_df[
    [
        "store",
        "financing_cancellation_rate_pct",
        "non_financing_cancellation_rate_pct"
    ]
].melt(
    id_vars="store",
    var_name="Financing Type",
    value_name="Cancellation Rate"
)

comparison_df["Financing Type"] = (
    comparison_df["Financing Type"].replace({

        "financing_cancellation_rate_pct": "Financing",

        "non_financing_cancellation_rate_pct":
            "Non-financing"

    })
)

fig_comparison = px.bar(
    comparison_df,
    x="store",
    y="Cancellation Rate",
    color="Financing Type",
    barmode="group",
    title="Cancellation Rate: Financing vs Non-financing"
)

fig_comparison.update_layout(
    xaxis_title="CARSOME Store",
    yaxis_title="Cancellation Rate (%)",
    xaxis_tickangle=-45
)

st.plotly_chart(
    fig_comparison,
    use_container_width=True
)


# ============================================================
# 9. CANCELLATION GAP ANALYSIS
# ============================================================

st.divider()

st.header("5. Cancellation Gap Analysis")

st.markdown(
    """
    Cancellation Gap = Non-financing Cancellation Rate
    - Financing Cancellation Rate.

    A positive gap indicates a higher cancellation rate in
    non-financing orders. A negative gap indicates a higher
    cancellation rate in financing orders.
    """
)

gap_df = filtered_df.sort_values(
    "cancellation_gap_pp",
    ascending=False
)

fig_gap = px.bar(
    gap_df,
    x="store",
    y="cancellation_gap_pp",
    color="investigation_priority",
    title="Cancellation Rate Gap by Store"
)

fig_gap.add_hline(
    y=20,
    line_dash="dash",
    annotation_text="P2 threshold: +20 percentage points"
)

fig_gap.add_hline(
    y=0,
    line_dash="solid"
)

fig_gap.update_layout(
    xaxis_title="CARSOME Store",
    yaxis_title="Cancellation Gap (Percentage Points)",
    xaxis_tickangle=-45
)

st.plotly_chart(
    fig_gap,
    use_container_width=True
)


# ============================================================
# 10. INVESTIGATION RECOMMENDATIONS
# ============================================================

st.divider()

st.header("6. Investigation Recommendations")

st.markdown(
    """
    Recommendations below are based on the SQL priority
    classification. They are investigation suggestions,
    not confirmed causal findings.
    """
)

for _, row in filtered_df.sort_values(
    [
        "cancelled_orders",
        "overall_cancellation_rate_pct"
    ],
    ascending=False
).iterrows():

    priority = row["investigation_priority"]

    with st.expander(
        f"{row['store']} | {priority}"
    ):

        st.write(
            f"**Total Orders:** "
            f"{row['total_orders']:,.0f}"
        )

        st.write(
            f"**Cancelled Orders:** "
            f"{row['cancelled_orders']:,.0f}"
        )

        st.write(
            f"**Overall Cancellation Rate:** "
            f"{row['overall_cancellation_rate_pct']:.2f}%"
        )

        st.write(
            f"**Financing Cancellation Rate:** "
            f"{row['financing_cancellation_rate_pct']:.2f}%"
        )

        st.write(
            f"**Non-financing Cancellation Rate:** "
            f"{row['non_financing_cancellation_rate_pct']:.2f}%"
        )

        st.write(
            f"**Cancellation Gap:** "
            f"{row['cancellation_gap_pp']:.2f} "
            "percentage points"
        )

        if priority == "P1 - High Business Impact":

            st.warning(
                """
                **Recommended action: High-priority investigation**

                - Review the store's cancellation cases.
                - Compare financing and non-financing cancellation patterns.
                - Examine cancellation remarks and financing-stage records.
                - Identify operational issues that may require follow-up.
                """
            )

        elif priority == "P2 - Large Cancellation Gap":

            st.info(
                """
                **Recommended action: Investigate the cancellation gap**

                - Examine why the non-financing cancellation rate is higher.
                - Review customer and order-process records.
                - Compare the cancellation patterns across both groups.
                """
            )

        elif priority == "Low Group Volume - Monitor":

            st.info(
                """
                **Recommended action: Monitor the store**

                - Group volume is below the SQL minimum threshold.
                - Avoid making strong conclusions from a small sample.
                - Reassess when more orders become available.
                """
            )

        else:

            st.success(
                """
                **Recommended action: Regular monitoring**

                - Continue monitoring cancellation volume and rate.
                - Review the store again during the next reporting period.
                """
            )


# ============================================================
# 11. STORE PERFORMANCE SUMMARY
# ============================================================

st.divider()

st.header("7. Store Performance Summary")

summary_columns = [
    "store",
    "total_orders",
    "cancelled_orders",
    "overall_cancellation_rate_pct",
    "financing_orders",
    "financing_cancelled_orders",
    "financing_cancellation_rate_pct",
    "non_financing_orders",
    "non_financing_cancelled_orders",
    "non_financing_cancellation_rate_pct",
    "cancellation_gap_pp",
    "investigation_priority"
]

summary_df = filtered_df[
    summary_columns
].copy()

summary_df = summary_df.rename(
    columns={
        "store": "CARSOME Store",
        "total_orders": "Total Orders",
        "cancelled_orders": "Cancelled Orders",
        "overall_cancellation_rate_pct":
            "Overall Cancellation Rate (%)",
        "financing_orders": "Financing Orders",
        "financing_cancelled_orders":
            "Financing Cancelled Orders",
        "financing_cancellation_rate_pct":
            "Financing Cancellation Rate (%)",
        "non_financing_orders": "Non-financing Orders",
        "non_financing_cancelled_orders":
            "Non-financing Cancelled Orders",
        "non_financing_cancellation_rate_pct":
            "Non-financing Cancellation Rate (%)",
        "cancellation_gap_pp":
            "Cancellation Gap (pp)",
        "investigation_priority":
            "Investigation Priority"
    }
)

st.dataframe(
    summary_df.sort_values(
        "Cancelled Orders",
        ascending=False
    ).round(2),
    use_container_width=True,
    hide_index=True
)


# ============================================================
# 12. EXPORT RESULTS
# ============================================================

st.divider()

st.header("8. Export Results")

csv_data = filtered_df.to_csv(
    index=False
).encode("utf-8-sig")

st.download_button(
    label="Download Cancellation Analysis CSV",
    data=csv_data,
    file_name="CARSOME_Cancellation_Recommendations_Filtered.csv",
    mime="text/csv"
)


# ============================================================
# 13. FOOTER
# ============================================================

st.divider()

st.caption(
    """
    Data Source: MySQL - carsome_orders_analysis.stg_orders

    SQL Reference: 03_cancellation_analysis.sql

    Investigation priorities follow the SQL classification rules.

    Cancellation patterns should not be interpreted as confirmed
    causes without further case-level evidence.
    """
)
