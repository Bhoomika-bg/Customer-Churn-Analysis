from pathlib import Path

import altair as alt
import joblib
import pandas as pd
import streamlit as st


PROJECT_ROOT = Path(__file__).resolve().parents[1]
DATA_PATH = PROJECT_ROOT / "dataset" / "processed" / "cleaned_telco.csv"
MODEL_PATH = PROJECT_ROOT / "models" / "churn_model.joblib"
COMPARISON_PATH = PROJECT_ROOT / "models" / "model_comparison.csv"

MODEL_FEATURES = [
    "gender",
    "SeniorCitizen",
    "Partner",
    "Dependents",
    "tenure",
    "PhoneService",
    "MultipleLines",
    "InternetService",
    "OnlineSecurity",
    "OnlineBackup",
    "DeviceProtection",
    "TechSupport",
    "StreamingTV",
    "StreamingMovies",
    "Contract",
    "PaperlessBilling",
    "PaymentMethod",
    "MonthlyCharges",
    "TotalCharges",
]

st.set_page_config(
    page_title="CHURNIQ",
    page_icon="C",
    layout="wide",
    initial_sidebar_state="expanded",
)


def inject_styles() -> None:
    st.markdown(
        """
        <style>
        :root {
            --navy: #080d1f;
            --panel: #11172a;
            --panel-soft: #151b2f;
            --border: #252d48;
            --text: #f4f7ff;
            --muted: #98a2b9;
            --blue: #5b8cff;
            --violet: #8b7cf6;
            --cyan: #53c7d9;
            --danger: #ff6b7a;
        }
        .stApp {
            background: var(--navy);
            color: var(--text);
        }
        [data-testid="stSidebar"] {
            background: #0b1124;
            border-right: 1px solid var(--border);
        }
        [data-testid="stSidebar"] [data-testid="stMarkdownContainer"] p {
            color: var(--muted);
        }
        [data-testid="stHeader"] {
            background: transparent;
        }
        h1, h2, h3, h4, p, label, span {
            color: var(--text);
        }
        .block-container {
            max-width: 1440px;
            padding-top: 2rem;
            padding-bottom: 3rem;
        }
        .brand-wrap {
            padding: 0.4rem 0.25rem 1.3rem 0.25rem;
            border-bottom: 1px solid var(--border);
            margin-bottom: 1rem;
        }
        .brand-name {
            color: #ffffff;
            font-size: 1.35rem;
            font-weight: 760;
            letter-spacing: 0.14em;
        }
        .brand-subtitle {
            color: var(--muted);
            font-size: 0.78rem;
            margin-top: 0.2rem;
        }
        .page-header {
            margin-bottom: 1.25rem;
        }
        .page-header h1 {
            font-size: 2rem;
            margin: 0;
            letter-spacing: -0.025em;
        }
        .page-header p {
            color: var(--muted);
            margin: 0.35rem 0 0 0;
        }
        .kpi-card {
            background: var(--panel);
            border: 1px solid var(--border);
            border-radius: 14px;
            padding: 1.1rem 1.15rem;
            min-height: 118px;
        }
        .kpi-label {
            color: var(--muted);
            font-size: 0.78rem;
            font-weight: 650;
            text-transform: uppercase;
            letter-spacing: 0.055em;
        }
        .kpi-value {
            color: #ffffff;
            font-size: 1.85rem;
            font-weight: 760;
            margin-top: 0.55rem;
        }
        .kpi-detail {
            color: #77839e;
            font-size: 0.78rem;
            margin-top: 0.25rem;
        }
        .chart-card, .form-section, .result-card {
            background: var(--panel);
            border: 1px solid var(--border);
            border-radius: 14px;
            padding: 1rem;
        }
        .section-title {
            font-size: 0.95rem;
            font-weight: 700;
            margin-bottom: 0.75rem;
        }
        .risk-high { color: #ff8792; }
        .risk-low { color: #67d4ae; }
        .risk-moderate { color: #ffc56e; }
        .result-label {
            color: var(--muted);
            font-size: 0.78rem;
            text-transform: uppercase;
            letter-spacing: 0.06em;
        }
        .result-value {
            color: #ffffff;
            font-size: 1.45rem;
            font-weight: 760;
            margin-top: 0.35rem;
        }
        .probability-big {
            color: #ffffff;
            font-size: 3rem;
            font-weight: 780;
            line-height: 1;
        }
        .stMetric {
            background: transparent;
        }
        .stButton > button, .stFormSubmitButton > button {
            border-radius: 10px;
            border: 1px solid #7297ff;
            background: #5b8cff;
            color: #ffffff;
            min-height: 3rem;
            font-weight: 700;
        }
        .stButton > button:hover, .stFormSubmitButton > button:hover {
            border-color: #93abff;
            background: #668fff;
            color: #ffffff;
        }
        [data-testid="stSelectbox"] div, [data-testid="stNumberInput"] div {
            border-radius: 9px;
        }
        [data-testid="stDataFrame"] {
            background: var(--panel);
        }
        hr {
            border-color: var(--border);
        }
        </style>
        """,
        unsafe_allow_html=True,
    )


@st.cache_data
def load_dataset() -> pd.DataFrame:
    if not DATA_PATH.exists():
        raise FileNotFoundError(f"Dataset not found: {DATA_PATH}")
    data = pd.read_csv(DATA_PATH)
    missing = set(MODEL_FEATURES + ["Churn"]).difference(data.columns)
    if missing:
        raise ValueError(f"Dataset is missing required columns: {sorted(missing)}")
    return data


@st.cache_resource
def load_model():
    if not MODEL_PATH.exists():
        raise FileNotFoundError(f"Model not found: {MODEL_PATH}")
    model = joblib.load(MODEL_PATH)
    if not hasattr(model, "predict") or not hasattr(model, "predict_proba"):
        raise TypeError("Saved model does not provide predict() and predict_proba().")
    return model


@st.cache_data
def load_comparison() -> pd.DataFrame:
    if not COMPARISON_PATH.exists():
        return pd.DataFrame()
    return pd.read_csv(COMPARISON_PATH).set_index("Model")


def page_header(title: str, description: str) -> None:
    st.markdown(
        f'<div class="page-header"><h1>{title}</h1><p>{description}</p></div>',
        unsafe_allow_html=True,
    )


def kpi_card(label: str, value: str, detail: str) -> str:
    return (
        f'<div class="kpi-card"><div class="kpi-label">{label}</div>'
        f'<div class="kpi-value">{value}</div><div class="kpi-detail">{detail}</div></div>'
    )


def chart_theme() -> alt.Chart:
    return alt.Chart(pd.DataFrame())


def base_rule_chart(frame: pd.DataFrame, category: str, value: str, title: str) -> alt.Chart:
    chart = (
        alt.Chart(frame)
        .mark_bar(cornerRadiusTopLeft=4, cornerRadiusTopRight=4)
        .encode(
            x=alt.X(f"{category}:N", sort="-y", title=None, axis=alt.Axis(labelColor="#98a2b9")),
            y=alt.Y(f"{value}:Q", title="Churn rate", axis=alt.Axis(format=".0%", labelColor="#98a2b9")),
            color=alt.Color(
                f"{value}:Q",
                scale=alt.Scale(range=["#5b8cff", "#8b7cf6"]),
                legend=None,
            ),
            tooltip=[
                alt.Tooltip(f"{category}:N"),
                alt.Tooltip(f"{value}:Q", format=".2%"),
                alt.Tooltip("Customers:Q"),
            ],
        )
        .properties(height=235)
    )
    return chart.configure_view(strokeWidth=0).configure_axis(
        gridColor="#252d48",
        domainColor="#252d48",
        labelFontSize=11,
        titleColor="#98a2b9",
    )


def churn_rate_frame(data: pd.DataFrame, feature: str) -> pd.DataFrame:
    frame = data.groupby(feature)["Churn"].agg(
        Customers="size",
        Churned=lambda values: (values == "Yes").sum(),
    ).reset_index()
    frame["ChurnRate"] = frame["Churned"] / frame["Customers"]
    return frame.rename(columns={feature: "Category"})


def render_overview(data: pd.DataFrame) -> None:
    page_header("Overview", "Customer retention and churn performance at a glance")

    total = len(data)
    churned = int((data["Churn"] == "Yes").sum())
    retained = total - churned
    churn_rate = churned / total
    retention_rate = retained / total

    c1, c2, c3, c4 = st.columns(4)
    c1.markdown(kpi_card("Total Customers", f"{total:,}", "All active records"), unsafe_allow_html=True)
    c2.markdown(kpi_card("Churned Customers", f"{churned:,}", "Churn label: Yes"), unsafe_allow_html=True)
    c3.markdown(kpi_card("Churn Rate", f"{churn_rate:.2%}", "Observed in dataset"), unsafe_allow_html=True)
    c4.markdown(kpi_card("Retention Rate", f"{retention_rate:.2%}", "Churn label: No"), unsafe_allow_html=True)

    left, right = st.columns([1.05, 1.95])
    with left:
        st.markdown('<div class="chart-card"><div class="section-title">Customer churn distribution</div></div>', unsafe_allow_html=True)
        distribution = data["Churn"].value_counts().rename_axis("Status").reset_index(name="Customers")
        distribution["Status"] = distribution["Status"].replace({"Yes": "Churned", "No": "Retained"})
        donut = (
            alt.Chart(distribution)
            .mark_arc(innerRadius=72, outerRadius=105, cornerRadius=4)
            .encode(
                theta=alt.Theta("Customers:Q"),
                color=alt.Color(
                    "Status:N",
                    scale=alt.Scale(domain=["Retained", "Churned"], range=["#5b8cff", "#8b7cf6"]),
                    legend=alt.Legend(labelColor="#98a2b9", titleColor="#98a2b9"),
                ),
                tooltip=["Status:N", "Customers:Q"],
            )
            .properties(height=260)
            .configure_view(strokeWidth=0)
        )
        st.altair_chart(donut, use_container_width=True)

    with right:
        st.markdown('<div class="chart-card"><div class="section-title">Churn rate by contract</div></div>', unsafe_allow_html=True)
        contract = churn_rate_frame(data, "Contract")
        contract = contract.rename(columns={"Category": "Contract"})
        contract_chart = base_rule_chart(contract, "Contract", "ChurnRate", "Churn rate by contract")
        st.altair_chart(contract_chart, use_container_width=True)

    row2_left, row2_right = st.columns(2)
    with row2_left:
        st.markdown('<div class="chart-card"><div class="section-title">Churn rate by internet service</div></div>', unsafe_allow_html=True)
        internet = churn_rate_frame(data, "InternetService").rename(columns={"Category": "InternetService"})
        st.altair_chart(base_rule_chart(internet, "InternetService", "ChurnRate", "Internet service"), use_container_width=True)

    with row2_right:
        st.markdown('<div class="chart-card"><div class="section-title">Churn rate by payment method</div></div>', unsafe_allow_html=True)
        payment = churn_rate_frame(data, "PaymentMethod").rename(columns={"Category": "PaymentMethod"})
        st.altair_chart(base_rule_chart(payment, "PaymentMethod", "ChurnRate", "Payment method"), use_container_width=True)

    row3_left, row3_right = st.columns(2)
    with row3_left:
        st.markdown('<div class="chart-card"><div class="section-title">Average tenure by churn status</div></div>', unsafe_allow_html=True)
        tenure = data.assign(Status=data["Churn"].replace({"Yes": "Churned", "No": "Retained"})).groupby("Status", as_index=False)["tenure"].mean()
        tenure_chart = (
            alt.Chart(tenure)
            .mark_bar(cornerRadius=5)
            .encode(
                x=alt.X("Status:N", title=None, axis=alt.Axis(labelColor="#98a2b9")),
                y=alt.Y("tenure:Q", title="Average tenure (months)", axis=alt.Axis(labelColor="#98a2b9")),
                color=alt.Color("Status:N", scale=alt.Scale(domain=["Retained", "Churned"], range=["#5b8cff", "#8b7cf6"]), legend=None),
                tooltip=[alt.Tooltip("Status:N"), alt.Tooltip("tenure:Q", format=".2f")],
            )
            .properties(height=235)
            .configure_view(strokeWidth=0)
            .configure_axis(gridColor="#252d48", domainColor="#252d48")
        )
        st.altair_chart(tenure_chart, use_container_width=True)

    with row3_right:
        st.markdown('<div class="chart-card"><div class="section-title">Average monthly charges by churn status</div></div>', unsafe_allow_html=True)
        charges = data.assign(Status=data["Churn"].replace({"Yes": "Churned", "No": "Retained"})).groupby("Status", as_index=False)["MonthlyCharges"].mean()
        charge_chart = (
            alt.Chart(charges)
            .mark_bar(cornerRadius=5)
            .encode(
                x=alt.X("Status:N", title=None, axis=alt.Axis(labelColor="#98a2b9")),
                y=alt.Y("MonthlyCharges:Q", title="Average monthly charge", axis=alt.Axis(labelColor="#98a2b9")),
                color=alt.Color("Status:N", scale=alt.Scale(domain=["Retained", "Churned"], range=["#5b8cff", "#8b7cf6"]), legend=None),
                tooltip=[alt.Tooltip("Status:N"), alt.Tooltip("MonthlyCharges:Q", format="$.2f")],
            )
            .properties(height=235)
            .configure_view(strokeWidth=0)
            .configure_axis(gridColor="#252d48", domainColor="#252d48")
        )
        st.altair_chart(charge_chart, use_container_width=True)


def category_options(data: pd.DataFrame, column: str) -> list[str]:
    return sorted(data[column].dropna().astype(str).unique().tolist())


def categorical_input(data: pd.DataFrame, column: str, label: str, help_text: str) -> str:
    return st.selectbox(label, category_options(data, column), help=help_text)


def retention_suggestions(values: dict) -> list[str]:
    suggestions = []
    if values["Contract"] == "Month-to-month":
        suggestions.append("Offer a targeted long-term contract incentive or loyalty review.")
    if values["tenure"] <= 12:
        suggestions.append("Prioritize an early-life customer success check-in.")
    if values["InternetService"] == "Fiber optic":
        suggestions.append("Review service quality and perceived value for this fiber customer.")
    if values["OnlineSecurity"] == "No":
        suggestions.append("Explain the benefits of online security as a value-added service.")
    if values["TechSupport"] == "No":
        suggestions.append("Offer a technical-support readiness call or onboarding session.")
    if values["PaymentMethod"] == "Electronic check":
        suggestions.append("Review payment convenience and consider an automatic-payment incentive.")
    if not suggestions:
        suggestions.append("Continue standard engagement and monitor changes in usage or account health.")
    return suggestions


def render_prediction(data: pd.DataFrame, model) -> None:
    page_header("Predict Churn", "Estimate individual customer risk using the saved trained pipeline")

    with st.form("churn_prediction_form"):
        st.markdown('<div class="form-section">', unsafe_allow_html=True)
        st.markdown('<div class="section-title">1. Customer Information</div>', unsafe_allow_html=True)
        customer = st.columns(3)
        with customer[0]:
            gender = categorical_input(data, "gender", "Gender", "Customer's recorded gender category.")
            partner = categorical_input(data, "Partner", "Partner", "Whether the customer has a partner.")
            dependents = categorical_input(data, "Dependents", "Dependents", "Whether the customer has dependents.")
        with customer[1]:
            senior_citizen = st.selectbox(
                "Senior Citizen",
                [0, 1],
                format_func=lambda value: "Yes" if value else "No",
                help="Senior citizen indicator.",
            )
            tenure = st.number_input(
                "Tenure",
                min_value=int(data["tenure"].min()),
                max_value=int(data["tenure"].max()),
                value=int(data["tenure"].median()),
                step=1,
                help="Customer relationship length in months.",
            )
        with customer[2]:
            st.markdown("**Profile readiness**")
            st.caption("Customer information is used by the trained model as raw input.")
        st.markdown("</div>", unsafe_allow_html=True)

        st.markdown('<div class="form-section" style="margin-top:1rem;">', unsafe_allow_html=True)
        st.markdown('<div class="section-title">2. Services and Internet</div>', unsafe_allow_html=True)
        services = st.columns(3)
        with services[0]:
            phone_service = categorical_input(data, "PhoneService", "Phone Service", "Whether the customer has phone service.")
            multiple_lines = categorical_input(data, "MultipleLines", "Multiple Lines", "Phone line configuration.")
            internet_service = categorical_input(data, "InternetService", "Internet Service", "Primary internet service type.")
        with services[1]:
            online_security = categorical_input(data, "OnlineSecurity", "Online Security", "Online security subscription.")
            online_backup = categorical_input(data, "OnlineBackup", "Online Backup", "Online backup subscription.")
            device_protection = categorical_input(data, "DeviceProtection", "Device Protection", "Device protection subscription.")
        with services[2]:
            tech_support = categorical_input(data, "TechSupport", "Technical Support", "Technical support subscription.")
            streaming_tv = categorical_input(data, "StreamingTV", "Streaming TV", "Streaming TV subscription.")
            streaming_movies = categorical_input(data, "StreamingMovies", "Streaming Movies", "Streaming movies subscription.")
        st.markdown("</div>", unsafe_allow_html=True)

        st.markdown('<div class="form-section" style="margin-top:1rem;">', unsafe_allow_html=True)
        st.markdown('<div class="section-title">3. Account and Billing</div>', unsafe_allow_html=True)
        account = st.columns(2)
        with account[0]:
            contract = categorical_input(data, "Contract", "Contract", "Customer contract duration.")
            paperless_billing = categorical_input(data, "PaperlessBilling", "Paperless Billing", "Whether paperless billing is enabled.")
            payment_method = categorical_input(data, "PaymentMethod", "Payment Method", "Customer billing payment method.")
        with account[1]:
            monthly_charges = st.number_input(
                "Monthly Charges",
                min_value=float(data["MonthlyCharges"].min()),
                max_value=float(data["MonthlyCharges"].max()),
                value=float(data["MonthlyCharges"].median()),
                step=0.01,
                help="Current monthly charge.",
            )
            total_charges = st.number_input(
                "Total Charges",
                min_value=float(data["TotalCharges"].min()),
                max_value=float(data["TotalCharges"].max()),
                value=float(data["TotalCharges"].median()),
                step=0.01,
                help="Lifetime recorded charges.",
            )
        st.markdown("</div>", unsafe_allow_html=True)

        submitted = st.form_submit_button("Predict Churn", use_container_width=True)

    if not submitted:
        return

    values = {
        "gender": gender,
        "SeniorCitizen": int(senior_citizen),
        "Partner": partner,
        "Dependents": dependents,
        "tenure": int(tenure),
        "PhoneService": phone_service,
        "MultipleLines": multiple_lines,
        "InternetService": internet_service,
        "OnlineSecurity": online_security,
        "OnlineBackup": online_backup,
        "DeviceProtection": device_protection,
        "TechSupport": tech_support,
        "StreamingTV": streaming_tv,
        "StreamingMovies": streaming_movies,
        "Contract": contract,
        "PaperlessBilling": paperless_billing,
        "PaymentMethod": payment_method,
        "MonthlyCharges": float(monthly_charges),
        "TotalCharges": float(total_charges),
    }

    input_row = pd.DataFrame([values], columns=MODEL_FEATURES)
    try:
        prediction = int(model.predict(input_row)[0])
        probabilities = model.predict_proba(input_row)[0]
        churn_probability = float(probabilities[1])
        retention_probability = float(probabilities[0])
    except (ValueError, TypeError, KeyError) as error:
        st.error(f"Prediction could not be completed: {error}")
        return

    if churn_probability >= 0.70:
        risk_label = "High risk"
        risk_class = "risk-high"
    elif churn_probability >= 0.40:
        risk_label = "Moderate risk"
        risk_class = "risk-moderate"
    else:
        risk_label = "Low risk"
        risk_class = "risk-low"

    outcome = "Likely to churn" if prediction == 1 else "Likely to remain"

    st.markdown("### Prediction result")
    result_left, result_right = st.columns([1.25, 1])
    with result_left:
        st.markdown(
            f"""
            <div class="result-card">
                <div class="result-label">Prediction outcome</div>
                <div class="result-value {risk_class}">{outcome}</div>
                <div style="margin-top:1rem;" class="result-label">Risk indicator</div>
                <div class="result-value {risk_class}">{risk_label}</div>
            </div>
            """,
            unsafe_allow_html=True,
        )
        st.progress(churn_probability)
        st.caption("Churn probability")
        st.progress(retention_probability)
        st.caption("Retention probability")

    with result_right:
        st.markdown(
            f"""
            <div class="result-card">
                <div class="result-label">Churn probability</div>
                <div class="probability-big">{churn_probability:.1%}</div>
                <hr>
                <div class="result-label">Retention probability</div>
                <div class="result-value">{retention_probability:.1%}</div>
            </div>
            """,
            unsafe_allow_html=True,
        )

    st.info("This probability is a model estimate, not a guarantee of future customer behavior.")

    st.markdown("### Retention suggestions")
    for suggestion in retention_suggestions(values):
        st.markdown(f"- {suggestion}")


def render_model_insights() -> None:
    page_header("Model Insights", "Actual evaluation outputs and saved model characteristics")

    comparison = load_comparison()
    if comparison.empty:
        st.warning("Model comparison data is unavailable.")
    else:
        st.markdown('<div class="chart-card"><div class="section-title">Test-set model comparison</div></div>', unsafe_allow_html=True)
        st.dataframe(comparison, use_container_width=True)

        chart_frame = comparison.reset_index().melt(
            id_vars="Model",
            var_name="Metric",
            value_name="Score",
        )
        chart = (
            alt.Chart(chart_frame)
            .mark_bar(cornerRadiusTopLeft=3, cornerRadiusTopRight=3)
            .encode(
                x=alt.X("Model:N", sort=None, title=None, axis=alt.Axis(labelAngle=-20, labelColor="#98a2b9")),
                y=alt.Y("Score:Q", title="Metric score", scale=alt.Scale(domain=[0, 1]), axis=alt.Axis(labelColor="#98a2b9")),
                color=alt.Color("Metric:N", scale=alt.Scale(range=["#5b8cff", "#53c7d9", "#8b7cf6", "#a5b4fc", "#ffb86b"]), legend=alt.Legend(labelColor="#98a2b9", titleColor="#98a2b9")),
                column=alt.Column("Metric:N", header=alt.Header(labelColor="#98a2b9")),
                tooltip=["Model:N", "Metric:N", alt.Tooltip("Score:Q", format=".4f")],
            )
            .properties(height=280)
            .configure_view(strokeWidth=0)
            .configure_axis(gridColor="#252d48", domainColor="#252d48")
        )
        st.altair_chart(chart, use_container_width=True)

    st.markdown('<div class="form-section">', unsafe_allow_html=True)
    st.markdown('<div class="section-title">Saved model</div>', unsafe_allow_html=True)
    model_left, model_right = st.columns(2)
    with model_left:
        st.markdown("**Algorithm**")
        st.write("Logistic Regression")
        st.markdown("**Estimator setting**")
        st.write("class_weight = balanced")
    with model_right:
        st.markdown("**Saved artifact**")
        st.code("models/churn_model.joblib")
        st.markdown("**Pipeline structure**")
        st.write("ColumnTransformer preprocessing + Logistic Regression")
    st.markdown("</div>", unsafe_allow_html=True)

    st.markdown('<div class="form-section" style="margin-top:1rem;">', unsafe_allow_html=True)
    st.markdown('<div class="section-title">Model selection context</div>', unsafe_allow_html=True)
    st.write(
        "Logistic Regression was selected because it had the strongest balance of recall "
        "and ROC-AUC among the three actual test-set comparisons in this project."
    )
    st.caption("Evaluation currently uses a random 80/20 train-test split. A temporal holdout or cross-validation would provide stronger validation.")
    st.caption("The default 0.5 classification threshold has not been optimized against business costs.")
    st.markdown("</div>", unsafe_allow_html=True)


def main() -> None:
    inject_styles()
    try:
        data = load_dataset()
        model = load_model()
    except (FileNotFoundError, ValueError, TypeError) as error:
        st.error(str(error))
        st.stop()

    with st.sidebar:
        st.markdown(
            '<div class="brand-wrap"><div class="brand-name">CHURNIQ</div>'
            '<div class="brand-subtitle">Customer Intelligence Platform</div></div>',
            unsafe_allow_html=True,
        )
        page = st.radio(
            "Workspace",
            ["Overview", "Predict Churn", "Model Insights"],
            label_visibility="collapsed",
        )
        st.markdown("---")
        st.caption("Logistic Regression")
        st.caption("Saved pipeline: churn_model.joblib")

    if page == "Overview":
        render_overview(data)
    elif page == "Predict Churn":
        render_prediction(data, model)
    else:
        render_model_insights()


if __name__ == "__main__":
    main()
