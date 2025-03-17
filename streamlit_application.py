import streamlit as st
import pandas as pd
import math
import plotly.express as px
from snowflake.snowpark.context import get_active_session

millnames = ['','K','M','B','T']
session = get_active_session()

def millify(n):
    n = float(n)
    millidx = max(0,min(len(millnames)-1,
                        int(math.floor(0 if n == 0 else math.log10(abs(n))/3))))

    return '{:.0f}{}'.format(n / 10**(3 * millidx), millnames[millidx])

def update_date_data():
    sql = 'select * from CRICKETANALYTICS.TRANFORMED_DATA.vw_latest_years'
    return session.sql(sql).collect()

def kpis_data():
    sql = 'select * from CRICKETANALYTICS.TRANFORMED_DATA.VW_KPIS'
    return session.sql(sql).collect()

@st.cache_data
def players_stats_data():
    sql = 'select * from CRICKETANALYTICS.TRANFORMED_DATA.vw_player_statistics'
    return session.sql(sql).collect()

@st.cache_data
def players_stats_data_overall():
    sql = 'select * from CRICKETANALYTICS.TRANFORMED_DATA.vw_player_statistics_overall'
    return session.sql(sql).collect()

st.title("Cricket Analytics Dashboard 🏏")
st.write("Data flows from https://cricsheet.org/ to S3 to Snowflake to dbt to Snowflake and orchestrated using Airflow")

update_date_data_df = pd.DataFrame(update_date_data(), columns=['Match Type', 'Latest Year Available'])
players_stats_df = pd.DataFrame(players_stats_data()).fillna({
    'FORMAT': "Not Available",
    'GENDER': "Not Available",
    'FORMAT_TYPE': "Not Available"
},)
players_stats_overall_df = pd.DataFrame(players_stats_data_overall()).fillna({
    'GENDER': "Not Available",
},)
kpis_data_df = pd.DataFrame(kpis_data())

col1, col2, col3 = st.columns([1, 2, 1]) 
with col2:  
    st.dataframe(update_date_data_df, hide_index=True)


st.divider()

col7, col8 = st.columns([1,1])
match_types = kpis_data_df["MATCH_TYPE"].unique().tolist()
match_formats = kpis_data_df["EVENT_TYPE"].unique().tolist()

with col7:
    selected_match_type = st.selectbox("Select Match Type", sorted(match_types), index=0)
with col8:
    selected_match_format = st.selectbox("Select Match Format", sorted(match_formats), index=0)
    
col1, col2, col3, col4 = st.columns(4)
col5, col6 = st.columns([1,1])


# total_matches = millify(kpis_data_df[(kpis_data_df['KEY']=='Total Matches') & (kpis_data_df['MATCH_TYPE']==selected_match_type) & (kpis_data_df['EVENT_TYPE']==selected_match_format)]['VALUE'].sum())
total_matches = kpis_data_df[(kpis_data_df['KEY']=='Total Matches') & (kpis_data_df['MATCH_TYPE']==selected_match_type) & (kpis_data_df['EVENT_TYPE']==selected_match_format)]['VALUE'].sum()
total_wickets = millify(kpis_data_df[(kpis_data_df['KEY']=='Total Wickets') & (kpis_data_df['MATCH_TYPE']==selected_match_type) & (kpis_data_df['EVENT_TYPE']==selected_match_format)]['VALUE'].sum())
total_runs = millify(kpis_data_df[(kpis_data_df['KEY']=='Total Runs') & (kpis_data_df['MATCH_TYPE']==selected_match_type) & (kpis_data_df['EVENT_TYPE']==selected_match_format)]['VALUE'].sum())
total_extras = millify(kpis_data_df[(kpis_data_df['KEY']=='Total Extras') & (kpis_data_df['MATCH_TYPE']==selected_match_type) & (kpis_data_df['EVENT_TYPE']==selected_match_format)]['VALUE'].sum())
total_male_match = millify(kpis_data_df[(kpis_data_df['KEY']=='Total Male Matches') & (kpis_data_df['MATCH_TYPE']==selected_match_type) & (kpis_data_df['EVENT_TYPE']==selected_match_format)]['VALUE'].sum())
total_female_match = millify(kpis_data_df[(kpis_data_df['KEY']=='Total Female Matches') & (kpis_data_df['MATCH_TYPE']==selected_match_type) & (kpis_data_df['EVENT_TYPE']==selected_match_format)]['VALUE'].sum())
if selected_match_format == 'ALL' and selected_match_type == 'ALL':
    stats_df = players_stats_overall_df
else:
    stats_df = players_stats_df[(players_stats_df['FORMAT'] == selected_match_type) & (players_stats_df['FORMAT_TYPE'] == selected_match_format)]
    
with col1:
    st.metric("Total # of Matches", total_matches)
with col2:
    st.metric("Total # of Wickets", total_wickets)
with col3:
    st.metric("Total # of Runs", total_runs)
with col4:
    st.metric("Total # of Extras", total_extras)
with col5:
    st.metric("Total # of Male Matches", total_male_match)
with col6:
    st.metric("Total # of Female Matches", total_female_match)

st.divider()

st.write('Highest Runs Tally')

top_n = st.slider('Top N Players', 1, 40, value=10)

top_n_runs_df = stats_df.sort_values(by='TOTAL_RUNS', ascending=False)[['PLAYER_NAME','TOTAL_RUNS']].head(top_n)

fig = px.bar(top_n_runs_df, x='PLAYER_NAME', y='TOTAL_RUNS')

st.plotly_chart(fig)

st.divider()

st.write('Players Statistics Summary')

st.dataframe(stats_df, hide_index=True)
