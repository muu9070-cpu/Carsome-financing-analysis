# 汽车金融业务流程与贷款转化分析
### From Operational Data to Business Insights

**SQL · Python · Pandas · MySQL · Streamlit · Plotly**

[English README](./README.md) | 中文项目介绍

[查看在线 Dashboard](https://carsome-financing-analysis.streamlit.app/) | [GitHub Repository](https://github.com/muu9070-cpu/Carsome-financing-analysis)

> 本项目是一项独立的商业数据分析作品集项目，以2026年9月创建的订单为分析队列，研究汽车金融业务流程中的贷款参与、阶段转化、放款跟踪、金融机构及门店表现、贷款金额缩减和订单取消情况。项目结合 SQL 数据验证与分析、Python 数据处理以及 Streamlit 交互式仪表板，展示从业务数据到分析洞察的完整流程。本项目不代表 CARSOME 官方发布或认可。

---

## 一、项目概述（Executive Summary）

汽车金融业务涉及多个连续但彼此独立的业务阶段。一笔订单可能依次经历金融申请识别、贷款审批、客户接受贷款方案、放款申请提交、放款到账以及订单完成等环节。

本项目选取 **2026年9月创建的2,747笔唯一订单** 作为分析样本，围绕汽车金融业务流程开展数据分析，重点关注：

- 汽车金融业务参与情况及阶段转化
- 贷款审批与客户接受情况
- 放款提交与实际到账之间的差异
- 不同金融机构及门店的业务表现
- 贷款金额缩减情况（Loan Slash）
- 订单取消情况（Cancellation）

项目通过 SQL 完成数据验证、业务指标计算和数据汇总，使用 Python/Pandas 进行数据处理，并通过 Streamlit 构建包含六个分析页面的交互式 Dashboard。

项目旨在将业务运营数据转化为清晰的绩效指标，识别需要进一步调查的业务环节，并提出可执行的运营跟进建议。

### 核心业务指标

| 指标 | 分析结果 |
|---|---:|
| 订单总数 | 2,747 |
| 汽车金融订单数 | 2,062 |
| 汽车金融订单占比 | 75.06% |
| 已批准贷款订单数 | 1,500 |
| 金融申请至审批转化率 | 72.74% |
| 客户接受贷款方案数 | 1,334 |
| 已提交放款申请数 | 1,149 |
| 已记录放款到账数 | 819 |
| 放款提交至到账转化率 | 71.28% |
| 已提交但未记录到账的订单 | 330 |
| 已完成订单数 | 947 |

**初步业务发现：**

在1,149笔已提交放款申请的订单中，有330笔在当前分析数据快照中尚未记录放款到账，占28.72%。

这些订单构成了值得进一步跟进的业务群体，但不能仅凭这一数据认定所有订单均存在延迟，或将问题归因于某一家金融机构。

---

## 二、业务背景（Business Context）

汽车金融业务是一个涉及多个业务参与方和运营环节的流程。

一笔订单通常可能经历以下阶段：

1. Order Created — 订单创建
2. Financing Case Identified — 识别为金融业务订单
3. Financing Approved — 贷款审批通过
4. Customer Accepts Financing — 客户接受贷款方案
5. Disbursement Submitted — 提交放款申请
6. Disbursement Received — 确认放款到账
7. Order Completed — 订单完成

不同阶段代表不同的业务事件，不能简单地将其合并为一个状态。

例如：

- 贷款审批通过不代表客户已经接受贷款方案。
- 提交放款申请不代表资金已经到账。
- 放款到账也不等于订单已经完成。

因此，本项目采用分阶段分析方法，对不同业务节点进行独立统计和监控，以便更准确地识别业务流程中的差异。

---

## 三、业务问题与分析目标（Business Problems & Analytical Questions）

本项目围绕六个主要业务问题开展分析。

| 分析方向 | 业务问题 | 分析目标 |
|---|---|---|
| Financing Conversion | 订单未能持续进入下一业务阶段 | 识别各阶段订单数量及主要差异 |
| Disbursement Tracking | 部分已提交放款申请的订单没有记录到账 | 统计未记录到账的订单数量及占比 |
| Financier & Store Performance | 不同金融机构及门店的业务结果可能存在差异 | 比较不同机构及门店的订单数量和业务表现 |
| Waiting Time | 部分未到账订单可能已经等待较长时间 | 分析未到账订单的等待时间分布 |
| Loan Slash | 已确认的贷款金额缩减情况存在差异 | 分析贷款缩减金额、比例及分布 |
| Cancellation | 不同业务类型和门店的订单取消情况可能不同 | 比较取消情况并识别需要进一步调查的群体 |

本项目主要采用描述性分析与诊断性分析。

不同业务群体之间的差异用于发现值得调查的业务信号，而不是直接证明某个银行、门店或个人是问题的根本原因。

---

## 四、分析方法与技术方案（Analytical Methodology）

### 4.1 数据质量与验证（Data Quality & Validation）

在开展业务分析之前，首先进行数据质量检查：

- 验证订单队列的日期边界及唯一订单数量。
- 检查关键字段、缺失值、业务阶段标识及数据完整性。
- 将汇总指标与订单级原始记录进行核对。
- 区分不同业务阶段，避免混淆不同状态。
- 对缺失或空白的金融机构信息进行保留和审计。

### 4.2 订单队列与 KPI 构建（Order-level Cohort & KPI Construction）

本项目采用订单创建日期定义主要分析队列：

- 开始日期：2026年9月1日（包含）
- 结束日期：2026年10月1日（不包含）

主要分析单位为唯一订单（Unique Order）。

需要注意的是，贷款审批、客户接受、放款及订单完成等后续业务事件可能发生在9月份之后。

因此，本项目属于基于订单创建日期的 Cohort Analysis，而不是要求所有后续业务事件都必须发生在9月份的同期分析。

### 4.3 漏斗与转化分析（Funnel & Conversion Analysis）

对汽车金融业务各阶段进行订单数量和转化率统计。

重点分析：

- 金融业务参与情况
- 贷款审批情况
- 客户接受贷款方案情况
- 放款申请提交情况
- 放款到账情况
- 订单完成情况

每个转化率均使用明确的分母进行计算。

不同阶段的订单数量不被默认视为互斥群体，除非相应业务定义明确支持这种解释。

### 4.4 业务分群分析（Segmentation Analysis）

按照金融机构（Financier）和门店（Store）进行分组，比较不同业务群体的订单数量及记录结果。

需要注意，金融机构归属可能随着业务阶段发生变化。因此，基于最终记录的金融机构进行分组，不应直接解释为早期银行审批表现的独立比较。

### 4.5 运营诊断分析（Operational Diagnostics）

**等待时间分析（Waiting Time Analysis）**

将符合条件的已提交但尚未记录到账的订单按照等待时间进行分类：

- 0–7天
- 8–14天
- 15–30天
- 超过30天

**贷款金额缩减分析（Loan Slash Analysis）**

针对已确认的贷款金额缩减记录，分析：

- Loan Amount
- Slash Amount
- Individual Slash Ratio
- Weighted Slash-to-Loan Ratio

**订单取消分析（Cancellation Analysis）**

比较汽车金融订单与非汽车金融订单、不同门店之间的取消情况，并结合百分点差异及规则分类，识别需要优先调查的业务群体。

### 4.6 Dashboard 开发（Dashboard Development）

整体技术流程：

- SQL：完成业务数据验证、查询、汇总和分析数据集构建。
- Python/Pandas：加载数据、处理数据类型及规范化字段。
- Streamlit/Plotly：构建交互式、多页面业务分析 Dashboard。

---

## 五、核心分析结果（Key Findings）

### 5.1 汽车金融业务参与及阶段转化

在2,747笔唯一订单中，有2,062笔被识别为汽车金融业务订单，占全部订单的75.06%。

其中，1,500笔贷款申请获得批准，以汽车金融订单数为分母，金融申请至审批转化率为72.74%。

汽车金融订单与已批准订单之间存在562笔的数量差异。

这部分订单值得进一步拆解，但仅凭数量差异无法确定其属于拒绝、撤回、未完成申请或其他业务结果。

### 5.2 放款提交与实际到账之间的差异

分析结果显示：

- 已提交放款申请：1,149笔
- 已记录放款到账：819笔
- 提交至到账转化率：71.28%
- 尚未记录到账：330笔
- 未记录到账占比：28.72%

**业务解读：**

330笔订单构成了一个可以进一步跟进的业务群体。

下一步应检查具体订单状态、放款提交日期的完整性、实际等待时间以及最新运营记录，再判断具体原因和责任归属。

### 5.3 放款到账与订单完成是不同的业务事件

订单级数据核对发现以下三种状态组合：

| 状态组合 | 订单数量 |
|---|---:|
| 已完成订单，但没有记录放款到账 | 538 |
| 已记录放款到账，但订单尚未标记完成 | 410 |
| 同时记录放款到账和订单完成 | 409 |

以上数据分别核对得到：

- 已完成订单总数：947笔
- 已记录放款到账订单：819笔

**业务解读：**

放款到账与订单完成是两个不同的业务节点。

在业务监控和绩效统计中，应将两者作为独立指标，不能将它们视为可以互相替代的状态。

### 5.4 金融机构、等待时间、贷款缩减及订单取消分析

Dashboard 进一步提供以下分析：

- 不同金融机构和门店的订单数量及业务结果比较。
- 已提交但未记录到账订单的等待时间分布。
- 已确认贷款缩减金额及比例分析。
- 不同门店及业务群体的订单取消情况和调查优先级。

这些分析用于发现潜在业务差异并支持进一步调查。

本项目不直接将某家银行、某个门店或某种取消原因认定为业务差异的根本原因。具体结论仍需结合详细记录、样本数量、数据完整性及业务定义进行验证。

---

## 六、业务洞察与运营建议（Business Insights & Recommendations）

基于上述分析，本项目提出六个运营改进方向。

### Priority 1 — 放款待处理订单跟进

**业务信号：**

1,149笔已提交放款申请的订单中，有330笔尚未记录到账。

**建议措施：**

- 建立统一的待到账订单跟踪列表。
- 展示订单编号、金融机构、提交日期、等待天数、最新状态及跟进负责人。
- 定期与相关运营团队核对未解决订单。

**建议监控指标：**

Open Cases、Ageing by Bucket、Cases Resolved Since Last Review。

### Priority 2 — 长时间等待及信息缺失订单升级处理

**业务信号：**

等待时间分析将符合条件的订单分为不同等待时间区间，同时单独识别缺少有效提交日期的记录。

**建议措施：**

- 优先检查等待时间较长的订单。
- 将缺失提交日期的记录单独纳入数据补全队列。
- 记录最新跟进结果，避免重复调查。

**建议监控指标：**

Cases by Ageing Bucket、Cases Over 30 Days、Missing Submission Dates。

### Priority 3 — 建立统一的金融机构与门店绩效分析机制

**业务信号：**

不同金融机构和门店在订单数量及业务结果方面可能存在差异。

**建议措施：**

- 建立统一的金融机构及门店分析指标体系。
- 同时展示订单数量、转化率和业务结果。
- 明确展示各项转化率的分母。
- 对小样本及金融机构信息缺失的群体单独标记。

**建议监控指标：**

Case Volume、Stage Conversion、Submitted-not-received Count/Rate、Missing Assignments。

### Priority 4 — 贷款金额缩减监控

**业务信号：**

已确认的贷款缩减记录包含贷款金额、缩减金额、单笔缩减比例及加权缩减比例。

**建议措施：**

- 同时观察缩减总金额和两种比例指标。
- 对金额较大的缩减案例开展进一步分析。
- 根据金融机构或贷款类型识别重复出现的业务模式。
- 在确定原因前核对具体订单记录。

**建议监控指标：**

Confirmed Slash Cases、Total Slash Amount、Average Individual Slash Ratio、Weighted Slash-to-Loan Ratio。

### Priority 5 — 优先调查重点门店及业务群体的取消情况

**业务信号：**

项目比较了不同业务类型及门店的订单取消情况，并采用以下调查优先级：

- P1
- P2
- P3
- Low Group Volume — Monitor

**建议措施：**

- 根据优先级组织门店级订单调查。
- 使用具体订单证据核实取消原因。
- 对样本量较小的群体谨慎解读百分比差异。

**建议监控指标：**

Overall Cancellation Rate、Segment Rates、Gap in Percentage Points、Cases Reviewed with Verified Reasons。

### Priority 6 — 分别核对放款到账与订单完成情况

**业务信号：**

数据中存在538笔仅记录订单完成、410笔仅记录放款到账，以及409笔同时记录两种状态的订单。

**建议措施：**

- 将放款到账与订单完成分别作为独立运营指标。
- 对仅到账和仅完成的订单进行核对。
- 确认差异是否来自正常业务流程、时间差异或数据质量问题。

**建议监控指标：**

Received-only、Completed-only、Both-status Cases、Outstanding Reconciliation Exceptions。

### 建议运营复盘周期

| 周期 | 重点关注内容 |
|---|---|
| Daily | 待到账订单、等待时间异常、缺失提交日期 |
| Weekly | 金融机构及门店指标、未解决订单、数据完整性 |
| Monthly | 业务漏斗、贷款缩减趋势、取消优先级及调查结果 |

以上建议属于基于现有数据提出的运营监控方案，实际负责人、升级阈值及复盘频率应与业务团队的运营流程和系统更新周期保持一致。

---

## 七、交互式 Dashboard（Interactive Dashboard）

本项目通过 Streamlit 构建包含六个分析页面的交互式业务分析平台。

| 页面 | 分析内容 |
|---|---|
| 1. Executive Overview | 整体订单与汽车金融业务概况 |
| 2. Financing Funnel | 汽车金融业务各阶段的订单数量及转化情况 |
| 3. Financier Performance | 不同金融机构及门店的业务表现 |
| 4. Waiting Time Analysis | 已提交但尚未记录到账订单的等待时间分布 |
| 5. Loan Slash Analysis | 已确认贷款缩减金额及比例分析 |
| 6. Cancellation Recommendations | 需要优先调查的门店及业务群体 |

**在线体验：**

[打开 Carsome Financing Analysis Dashboard](https://carsome-financing-analysis.streamlit.app/)

---

## 八、技术架构（Technical Architecture）

### 8.1 端到端数据分析流程

```text
Source / Order-level Data
          |
          v
SQL Data Validation
& Business Analysis
          |
          v
SQL Result Sets
& Dashboard Datasets
          |
          v
CSV Analytical Extracts
          |
          v
Centralised Python Data Loader
          |
          v
Six-page Streamlit
+ Plotly Dashboard
          |
          v
Business Findings
& Operational Recommendations
```

### 8.2 技术栈

| 技术层 | 使用工具 | 主要用途 |
|---|---|---|
| 数据查询 | SQL / MySQL | 数据验证、关联查询、汇总及业务规则 |
| 数据处理 | Python / Pandas | 数据加载、类型转换、字段规范化 |
| 探索性分析 | Jupyter Notebook | 数据质量检查、特征准备、KPI探索 |
| 数据可视化 | Streamlit / Plotly | 交互式 Dashboard 和业务分析 |
| 版本管理 | Git / GitHub | 项目管理与作品集发布 |

---

## 九、SQL 分析与数据资产（SQL Analysis & Data Assets）

### 9.1 SQL 文件结构

`database/` 目录包含完整的 SQL 分析流程：

| SQL 文件 | 主要用途 |
|---|---|
| `01_data_validation.sql` | 验证源数据及关键字段 |
| `02_business_overview.sql` | 建立整体业务分析视图 |
| `03_cancellation_analysis.sql` | 分析订单取消情况及调查优先级 |
| `04_financing_funnel.sql` | 构建汽车金融阶段及转化分析 |
| `04_financing_performance.sql` | 分析金融业务表现 |
| `05_bank_branch_performance.sql` | 分析金融机构及门店表现 |
| `06_loan_amount_analysis.sql` | 分析贷款金额及 Loan Slash |
| `07_Business_Insights & Recommendations.sql` | 汇总业务洞察及运营建议 |
| `08_Dashboard_Dataset_Preparation.sql` | 准备 Dashboard 分析数据集 |
| `dashboard_views.sql` | 定义 Dashboard 所需 SQL Views |

### 9.2 处理后的分析数据集

`data/processed/` 目录包含九个分析数据集：

- `CARSOME_Financing_Dashboard.csv`
- `financier_overall_performance.csv`
- `financier_store_performance.csv`
- `financier_stage_conversion.csv`
- `financier_assignment_audit.csv`
- `financier_disbursement_conversion.csv`
- `CARSOME_Waiting_Time_Analysis.csv`
- `CARSOME_Loan_Slash_Analysis.csv`
- `CARSOME_Cancellation_Recommendations.csv`

所有 Dashboard 页面均通过统一的 `utils/data_loader.py` 模块加载和验证数据。

---

## 十、Jupyter Notebook

`notebooks/` 目录保留了支持 SQL 数据集和 Dashboard 计算的探索性分析及数据准备工作。

- `Data quality layer.ipynb`
- `Feature layer.ipynb`
- `Feature or KPI Layer.ipynb`

---

## 十一、项目目录结构（Repository Structure）

```text
Carsome-financing-analysis/
│
├── app.py
├── README.md
├── README_CN.md
├── requirements.txt
├── carsome_portfolio_overview.png
│
├── data/
│   └── processed/
│       ├── CARSOME_Financing_Dashboard.csv
│       ├── CARSOME_Waiting_Time_Analysis.csv
│       ├── CARSOME_Loan_Slash_Analysis.csv
│       ├── CARSOME_Cancellation_Recommendations.csv
│       └── financier_*.csv
│
├── database/
│   ├── 01_data_validation.sql
│   ├── 02_business_overview.sql
│   ├── 03_cancellation_analysis.sql
│   ├── 04_financing_funnel.sql
│   ├── 04_financing_performance.sql
│   ├── 05_bank_branch_performance.sql
│   ├── 06_loan_amount_analysis.sql
│   ├── 07_Business_Insights & Recommendations.sql
│   ├── 08_Dashboard_Dataset_Preparation.sql
│   └── dashboard_views.sql
│
├── notebooks/
│   ├── Data quality layer.ipynb
│   ├── Feature layer.ipynb
│   └── Feature or KPI Layer.ipynb
│
├── pages/
│   ├── 1_Executive_Overview.py
│   ├── 2_Financing_Funnel.py
│   ├── 3_Financier_Performance.py
│   ├── 4_Waiting_Time_Analysis.py
│   ├── 5_Loan_Slash_Analysis.py
│   └── 6_Cancellation_Recommendations.py
│
└── utils/
    ├── __init__.py
    └── data_loader.py
```

---

## 十二、本地运行（Run Locally）

### 环境要求

- Python
- `requirements.txt` 中列出的 Python 依赖包

### 1. 克隆项目

```bash
git clone https://github.com/muu9070-cpu/Carsome-financing-analysis.git

cd Carsome-financing-analysis
```

### 2. 创建虚拟环境

```bash
python -m venv .venv
```

Windows PowerShell：

```powershell
.venv\Scripts\Activate.ps1
```

macOS / Linux：

```bash
source .venv/bin/activate
```

### 3. 安装依赖

```bash
pip install -r requirements.txt
```

### 4. 启动 Dashboard

```bash
streamlit run app.py
```

运行前，需要确保 `data/processed/` 目录中存在符合预期文件名和字段结构的九个 CSV 分析数据集。

---

## 十三、项目范围与数据责任（Scope, Limitations & Data Responsibility）

- **分析周期：** 主要分析队列基于2026年9月1日至9月30日创建的订单。后续业务阶段可能发生在9月份之后。
- **等待时间快照：** 等待时间取决于对应分析脚本所使用的数据快照日期，并非实时运营数据。
- **业务阶段区分：** 放款到账与订单完成是两个不同的业务事件。
- **指标分母：** 所有转化率必须结合明确的分母解释，不同阶段的订单数量不能默认使用相同的适用人群。
- **金融机构归属：** 金融机构的记录可能随业务阶段变化。描述性差异不能直接证明某家金融机构造成了某种业务结果。
- **数据缺失：** 缺失日期及金融机构信息可能影响特定计算中可纳入的订单数量。
- **因果关系：** 本项目主要采用描述性和诊断性分析，不直接证明订单取消、贷款缩减或放款未到账的根本原因。
- **数据快照：** 项目结果反映当前可用数据提取及分析快照，不代表企业实时运营情况。

本项目为独立的个人数据分析作品集案例，不代表 CARSOME 官方产品或官方认可。

所有公开的数据、截图和项目内容必须经过授权披露，并进行适当匿名化处理或使用合成数据。不得公开可识别客户身份的信息、公司机密、凭证、私有数据库连接信息或仅供内部使用的网址。

---

**Built with SQL, Python, Pandas, MySQL, Streamlit and Plotly.**
