# Bethany Thomas-Smyth - Data Science Professional Practice

## Manual Extraction and Development of Pre-Made Reports to Migrate into Data Tool

### Tools & Applications
- RStudio
- Tableau
- Excel

## Data Science Project

### Executive Summary
This project focuses on developing a robust data pipeline to create a comprehensive data source within Tableau. The goal is to generate key point analyses and data visualizations that will be instrumental in driving business decisions, particularly in aligning performance metrics with forecast and budget figures. 

The current process is highly manual, necessitating problem-solving to create an output file that will serve as a data source, consolidating information from various pre-made Excel reports. This new data source will be crucial for creating dashboards that enhance decision-making processes and influence sales strategies across the organization.

### Data Infrastructure & Tools

#### Primary Tool: RStudio
RStudio has been chosen as the primary tool for this project due to its robust capabilities in data analysis, including importing, accessing, transforming, and modeling data. It is particularly well-suited for structuring and combining various datasets that are currently only available in Excel format.

**Advantages:**
- ✅ User-friendly interface
- ✅ Straightforward process for loading multiple files as data
- ✅ Efficient code writing and data set management

**Challenges:**
- ⚠️ Limited to key individuals for data source refreshing
- ⚠️ Potentially slower performance compared to alternatives like Python due to higher memory usage

**Alternative Considered:** Python was considered as an alternative due to its faster performance, but RStudio was ultimately chosen for its user-friendliness and suitability for the specific tasks at hand.

🔗 [View RStudio Code](code/index.R)

### Data Engineering

#### ETL Process Overview
1. **Extract:** 📤 Data is sourced from pre-made Excel reports.
2. **Transform:** 
   - 🧹 Data cleaning to remove missing or duplicated values
   - 🔗 Merging of various fields from different Excel reports using unique identifiers
   - 🏛️ Ensuring historical data is maintained without duplication
3. **Load:** 📥 Processed data is loaded into Tableau for visualization and analysis

This ETL process marks a significant step towards automation, ensuring access to accurate and complete data for analysis.

### Data Visualization & Dashboard

Tableau has been selected as the platform for creating interactive and user-friendly dashboards. These dashboards will provide:

- 📈 Meaningful insights
- 🔄 Real-time business metrics
- 🎨 Tailored visualizations for different stakeholders (e.g., Marketing team)

**Key Features:**
- 🖱️ Interactive elements for non-technical users
- 🔧 Customizable views for various business needs
- ⏱️ Real-time data updates (pending full automation)

### Data Analytics

#### Primary Analytical Method: Linear Regression for Trend Analysis

**Objective:** To evaluate the effectiveness of various business incentives on sales performance.

**Metrics Analyzed:**
- 📈 Sales volume
- 💰 Sale value
- 📊 Revenue impact

**Key Insights:**
- 🔗 Correlation between incentives and sales volume
- 💹 Impact on overall revenue
- 🔍 Identification of other significant factors affecting performance


This analysis allows for a nuanced understanding of incentive effectiveness, highlighting cases where increased sales might not necessarily translate to proportional revenue growth.

### Results

The implementation of Tableau dashboards has significantly enhanced the business's analytical capabilities:

1. **Accuracy and Completeness:** ✅ Dashboards now provide reliable, comprehensive data.
2. **Accessibility:** 🖥️ Easy-to-use interfaces allow for daily interaction by various teams.
3. **Time Efficiency:** ⏱️ Quicker access to insights facilitates faster decision-making.

#### Sample Visualizations
![Dashboard 1](assets/dashboard1.png)
![Dashboard 2](assets/dashboard2.png)
![Dashboard 3](assets/dashboard3.png)

### Conclusion and Future Directions

The success of this project in creating valuable Tableau visualizations has demonstrated the immense potential of advanced data analytics in our business operations. Moving forward, we recommend:

1. **🔄 Further Automation:** Transition from Excel-based reports to direct ETL files.
2. **☁️ Cloud Integration:** Implement a cloud-based data warehouse for more efficient data management.
3. **📈 Expanded Analytics:** Explore more advanced predictive analytics models.
4. **🎓 Training and Adoption:** Develop a company-wide program to maximize the use of these new tools.

These next steps will not only streamline our data processes but also minimize risks associated with manual data handling, setting the stage for more sophisticated and impactful business intelligence capabilities.
