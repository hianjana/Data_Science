# Import libraries for EDA
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import datetime

# Import libraries for model creation
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.linear_model import LogisticRegression
from sklearn.neighbors import KNeighborsClassifier
from sklearn.svm import LinearSVC
from sklearn.linear_model import RidgeClassifier
from sklearn.ensemble import RandomForestClassifier
from sklearn import metrics


# Import libraries for model evaluation
from sklearn.model_selection import cross_val_score, StratifiedKFold
from sklearn.metrics import accuracy_score, precision_score, recall_score


# Load the train dataset
train = pd.read_csv('C:/Users/hianj/Desktop/DataCamp Learnings/Sahaj/Football/data/train.csv')


############################################### EDA ###############################################

# Check for number of rows and columns in train dataset
train.shape

# View the train records
train.head()

# Check the distribution of H, A & D in the target
plt.hist(train['FTR'])

# Rearrange the columns for ease of analysis
new_order = ['HomeTeam', 'AwayTeam', 'Date', 'league', 'AC', 'AF', 'AR', 'AS', 'AST', 'AY', 'HC', 'HF', 'HR', 'HS', 'HST', 'HTAG', 'HTHG', 'HY','FTR']
train = train.reindex(new_order, axis=1)
train.head()


# Check the shape of the dataframe again to confirm that no columns are missed out
train.shape

###################### Handling missing data ######################

# Check for missing values
train.isnull().sum()

# Check for records which do not have HomeTeam information
train[train.HomeTeam.isnull()]

# Drop records which do not have HomeTeam information
train = train[pd.notnull(train['HomeTeam'])]

# Check for missing values again
train.isnull().sum()

# Check for records which has NULL for AC, AF, AR etc
train[train.AC.isnull()]

# Drop the records which as NULL for AC, AF, AR etc
train = train[pd.notnull(train['AC'])]

# Check for missing values again
train.isnull().sum()

# Check for records which has NULL for HF
train[train.HF.isnull()]

# Replace NaN with 0
train['HF'] = train['HF'].fillna(0)
train['AF'] = train['AF'].fillna(0)

# Check for records which has NULL for HTAG
train[train.HTAG.isnull()]

# Replace NaN with 0
train['HTAG'] = train['HTAG'].fillna(0)
train['HTHG'] = train['HTHG'].fillna(0)


# Check for missing values again
train.isnull().sum()

# Check for records which has NULL for HY
train[train.HY.isnull()]

# Replace NaN with 0
train['HY'] = train['HY'].fillna(0)

# Check for missing values again
train.isnull().sum()

###################### Handling missing data ends here ######################

# Check for unique values in target (FTR)
train.FTR.unique()

# Convert Date column to a date object

train['Date'] = pd.to_datetime(train['Date'],format='%d/%m/%y')
train.head()

# Extract year from date
train['Year'] = train['Date'].dt.year

# Check of any team played for more than one league
df = train.groupby(['HomeTeam'])['league'].nunique().reset_index(name='count')
df[df['count'] > 1]


df = train.groupby(['AwayTeam'])['league'].nunique().reset_index(name='count')
df[df['count'] > 1]

# Check for the date range in train and test
print(train['Date'].min())
print(train['Date'].max())

# Convert numerical columns from float to int
float_cols = train.select_dtypes(include=[np.float]).columns.values
for each in float_cols:
    train[each] = train[each].astype(int)

#################################### Basetable creation ################################################

# Create base table for 2 seasons (matches between Aug 2015 and May 2017): Seasons 2015-16 and 2016-17
basetable = train[(train['Date']>= '2015-08-01') & (train['Date'] <= '2017-05-31')]

# Convert datetime to date
basetable['Date'] = basetable['Date'].dt.date

# Print minimum and maximum dates present in the basetable for verification
print(basetable['Date'].min())
print(basetable['Date'].max())

# Populate Season, Last_Season and Last_2_seasons based on start and end dates
start_dt = datetime.date(2015,8,1)
end_dt = datetime.date(2016,5,1)

basetable['Season'] = basetable['Date'].apply(lambda x: '2015-16' if ((x>= start_dt) & (x <= end_dt)) else '2016-17')
basetable['Last_Season'] = basetable['Date'].apply(lambda x: '2014-15' if ((x>= start_dt) & (x <= end_dt)) else '2015-16')
basetable['Last_2_Seasons'] = basetable['Date'].apply(lambda x: '2013-2015' if ((x>= start_dt) & (x <= end_dt)) else '2014-2016')

#### Calculate values for the last season: Last season's Home Team Win(H), Away Team Win (A) and Draws (D)
# Create new columns to hold last season's Home Team Win(H), Away Team Win (A) and Draws (D)

basetable['Last_yr_H'] = 0
basetable['Last_yr_A'] = 0
basetable['Last_yr_D'] = 0


# For records having current season as 2016-17, last season is 2015-16: August 2015 to May 2016
# For records having current season as 2015-16, last season is 2014-15: August 2014 to May 2015

last_season_data_2015_16  = train[(train['Date']>= '2015-08-01') & (train['Date'] <= '2016-05-31')]
last_season_data_2014_15  = train[(train['Date']>= '2014-08-01') & (train['Date'] <= '2015-05-31')]


# Aggregating the results from season: 2015-16
last_season_2015_16_results = last_season_data_2015_16.groupby(['HomeTeam', 'AwayTeam', 'FTR']).size().reset_index(name='count')
last_season_2015_16_results['Season'] = '2015-16'
last_season_2015_16_results.head()

# Aggregating the results from season: 2014-15
last_season_2014_15_results = last_season_data_2014_15.groupby(['HomeTeam', 'AwayTeam', 'FTR']).size().reset_index(name='count')
last_season_2014_15_results['Season'] = '2014-15'
last_season_2014_15_results.head()

last_season_2015_16_results.shape

last_season_2014_15_results.shape

# Combine results from both seasons
frames = [last_season_2014_15_results, last_season_2015_16_results]
last_season_results = pd.concat(frames)

last_season_results.shape

# Calculating Home Team Wins, Away Team Wins and Draws in the last year

for index, row in basetable.iterrows():
    hometeam   = row['HomeTeam']
    awayteam   = row['AwayTeam']
    lastseason = row['Last_Season']
    
    # Calculate H (Home Team wins) in the last season
    homewin = last_season_results.loc[(last_season_results['Season'] == lastseason) & (last_season_results['HomeTeam'] == hometeam) & (last_season_results['AwayTeam'] == awayteam) & (last_season_results['FTR'] == 'H')].reset_index()
    if len(homewin) == 0:
        H = 0
    else:
        count = homewin['count']
        H = count[0]

    # Calculate A (Away team wins) in the last season
    awaywin = last_season_results.loc[(last_season_results['Season'] == lastseason) & (last_season_results['HomeTeam'] == hometeam) & (last_season_results['AwayTeam'] == awayteam) & (last_season_results['FTR'] == 'A')].reset_index()
    if len(awaywin) == 0:
        A = 0
    else:
        count = awaywin['count']
        A = count[0]    
    
    # Calculate D (draws) in the last season
    draws = last_season_results.loc[(last_season_results['Season'] == lastseason) & (last_season_results['HomeTeam'] == hometeam) & (last_season_results['AwayTeam'] == awayteam) & (last_season_results['FTR'] == 'D')].reset_index()
    if len(draws) == 0:
        D = 0
    else:
        count = draws['count']
        D = count[0]      
    
    basetable.loc[index,'Last_yr_H'] = H
    basetable.loc[index,'Last_yr_A'] = A
    basetable.loc[index,'Last_yr_D'] = D


basetable.head()


#### Calculate values for the last two seasons: Last season's Home Team Win(H), Away Team Win (A) and Draws (D)
# Create new columns to hold last two season's Home Team Win(H), Away Team Win (A) and Draws (D)

basetable['Past_2yrs_H'] = 0
basetable['Past_2yrs_A'] = 0
basetable['Past_2yrs_D'] = 0

# For records having current season as 2016-17, last two seasons are 2014-15, 2015-16: August 2014 to May 2016
# For records having current season as 2015-16, last two seasons are 2013-14, 2014-15: August 2013 to May 2015
last_2_season_data_2014_2016  = train[(train['Date']>= '2014-08-01') & (train['Date'] <= '2016-05-31')]
last_2_season_data_2013_2015  = train[(train['Date']>= '2013-08-01') & (train['Date'] <= '2015-05-31')]

# Aggregating the results from seasons: 2013-14 & 2014-15
last_season_2013_2015_results = last_2_season_data_2013_2015.groupby(['HomeTeam', 'AwayTeam', 'FTR']).size().reset_index(name='count')
last_season_2013_2015_results['Season'] = '2013-2015'
last_season_2013_2015_results.head()

# Aggregating the results from seasons: 2014-15 & 2015-16
last_season_2014_2016_results = last_2_season_data_2014_2016.groupby(['HomeTeam', 'AwayTeam', 'FTR']).size().reset_index(name='count')
last_season_2014_2016_results['Season'] = '2014-2016'
last_season_2014_2016_results.head()

last_season_2013_2015_results.shape

last_season_2014_2016_results.shape

# Combine results from both seasons
frames = [last_season_2013_2015_results, last_season_2014_2016_results]
last_2_seasons_results = pd.concat(frames)
last_2_seasons_results.shape

last_2_seasons_results.head()

# Calculating Home Team Wins, Away Team Wins and Draws for the past 2 years
for index, row in basetable.iterrows():
    hometeam = row['HomeTeam']
    awayteam = row['AwayTeam']
    last_2_seasons = row['Last_2_Seasons']
    
    # Calculate H (Home Team wins) in the past 2 years
    homewin = last_2_seasons_results.loc[(last_2_seasons_results['Season'] == last_2_seasons) & (last_2_seasons_results['HomeTeam'] == hometeam) & (last_2_seasons_results['AwayTeam'] == awayteam) & (last_2_seasons_results['FTR'] == 'H')].reset_index()
    if len(homewin) == 0:
        H = 0
    else:
        count = homewin['count']
        H = count[0]

    # Calculate A (Away team wins) in the past 2 years
    awaywin = last_2_seasons_results.loc[(last_2_seasons_results['Season'] == last_2_seasons) & (last_2_seasons_results['HomeTeam'] == hometeam) & (last_2_seasons_results['AwayTeam'] == awayteam) & (last_2_seasons_results['FTR'] == 'A')].reset_index()
    if len(awaywin) == 0:
        A = 0
    else:
        count = awaywin['count']
        A = count[0]    
    
    # Calculate D (draws) in the past 2 years
    draws = last_2_seasons_results.loc[(last_2_seasons_results['Season'] == last_2_seasons) & (last_2_seasons_results['HomeTeam'] == hometeam) & (last_2_seasons_results['AwayTeam'] == awayteam) & (last_2_seasons_results['FTR'] == 'D')].reset_index()
    if len(draws) == 0:
        D = 0
    else:
        count = draws['count']
        D = count[0]    

    basetable.loc[index,'Past_2yrs_H'] = H
    basetable.loc[index,'Past_2yrs_A'] = A
    basetable.loc[index,'Past_2yrs_D'] = D


basetable.head()

########################################## Load external data ##########################################

# Load defending champions' data
champions = pd.read_csv('C:/Users/hianj/Desktop/DataCamp Learnings/Sahaj/Football/data/List_Of_Champions.csv')

# Create 2 new columns to represent if HT (Home Team) or AT(Away team) is the current defending champion
basetable['Is_HT_Defending_Champion'] = 0
basetable['Is_AT_Defending_Champion'] = 0

# Check if Home Team of Away Team is the Defending Champion from last season
for index, row in basetable.iterrows():
    hometeam = row['HomeTeam']
    awayteam = row['AwayTeam']
    league = row['league']
    lastseason = row['Last_Season']
    
    champion = champions[(champions['Season'] == lastseason) & (champions['League'] == league)].reset_index()
    defending_champ = champion['Champion'][0]
    
    if defending_champ == hometeam:
        basetable.loc[index,'Is_HT_Defending_Champion'] = 1
        
    if defending_champ == awayteam:
        basetable.loc[index,'Is_AT_Defending_Champion'] = 1


basetable.head()

# Load current team standings data (rank at the end of each season)
team_standings = pd.read_csv('C:/Users/hianj/Desktop/DataCamp Learnings/Sahaj/Football/data/Team_Standings.csv')

# Convert float to int
team_standings['Standing'] = team_standings['Standing'].astype(int)
team_standings.head()

# Create 2 new columns to store current team standing of Home Team and Away Team (standing is the rank from last season)
basetable['HT_Standing'] = 0
basetable['AT_Standing'] = 0

for index, row in basetable.iterrows():
    hometeam = row['HomeTeam']
    awayteam = row['AwayTeam']
    lastseason = row['Last_Season']
    
    # Retrieve the current standing of the home team (rank from last season)
    standing = team_standings[(team_standings['Season'] == lastseason) & (team_standings['Team'] == hometeam)].reset_index()
    if len(standing) == 0:
        hometeam_standing = 999
    else:
        hometeam_standing = standing['Standing'][0]
    
    basetable.loc[index,'HT_Standing'] = hometeam_standing
    
    # Retrieve the current standing of the away team (rank from last season)
    standing = team_standings[(team_standings['Season'] == lastseason) & (team_standings['Team'] == awayteam)].reset_index()
    if len(standing) == 0:
        awayteam_standing = 999
    else:
        awayteam_standing = standing['Standing'][0]
    
    basetable.loc[index,'AT_Standing'] = awayteam_standing

basetable.head()

############ Load betting odds data ############

# External data of bundesliga
## http://www.football-data.co.uk/germanym.php

ed_bundesliga = pd.read_csv('C:/Users/hianj/Desktop/DataCamp Learnings/Sahaj/Football/data/2015_2017_external_data/bundesliga.csv')
ed_bundesliga = ed_bundesliga[['Date','HomeTeam','AwayTeam','HTR', 'BbOU', 'BbMx>2.5', 'BbAv>2.5', 'BbMx<2.5', 'BbAv<2.5', 'B365H', 'B365D', 'B365A', 'BWH', 'BWD', 'BWA', 'IWH', 'IWD', 'IWA', 'LBH', 'LBD', 'LBA', 'PSH', 'PSD', 'PSA', 'WHH', 'WHD', 'WHA', 'VCH', 'VCD', 'VCA']]
ed_bundesliga['league'] = 'bundesliga'
ed_bundesliga.shape


# External data of serie-a
# http://www.football-data.co.uk/italym.php

ed_serie_a = pd.read_csv('C:/Users/hianj/Desktop/DataCamp Learnings/Sahaj/Football/data/2015_2017_external_data/serie_a.csv')
ed_serie_a = ed_serie_a[['Date','HomeTeam','AwayTeam','HTR', 'BbOU', 'BbMx>2.5', 'BbAv>2.5', 'BbMx<2.5', 'BbAv<2.5', 'B365H', 'B365D', 'B365A', 'BWH', 'BWD', 'BWA', 'IWH', 'IWD', 'IWA', 'LBH', 'LBD', 'LBA', 'PSH', 'PSD', 'PSA', 'WHH', 'WHD', 'WHA', 'VCH', 'VCD', 'VCA']]
ed_serie_a['league'] = 'serie-a'
ed_serie_a.shape

# External data of la-liga
# http://www.football-data.co.uk/spainm.php
    
ed_la_liga = pd.read_csv('C:/Users/hianj/Desktop/DataCamp Learnings/Sahaj/Football/data/2015_2017_external_data/la_liga.csv')
ed_la_liga = ed_la_liga[['Date','HomeTeam','AwayTeam','HTR', 'BbOU', 'BbMx>2.5', 'BbAv>2.5', 'BbMx<2.5', 'BbAv<2.5', 'B365H', 'B365D', 'B365A', 'BWH', 'BWD', 'BWA', 'IWH', 'IWD', 'IWA', 'LBH', 'LBD', 'LBA', 'PSH', 'PSD', 'PSA', 'WHH', 'WHD', 'WHA', 'VCH', 'VCD', 'VCA']]
ed_la_liga['league'] = 'la-liga'
ed_la_liga.shape


# External data of premier-league
# http://www.football-data.co.uk/englandm.php

ed_premier_league = pd.read_csv('C:/Users/hianj/Desktop/DataCamp Learnings/Sahaj/Football/data/2015_2017_external_data/premier_league.csv')
ed_premier_league = ed_premier_league[['Date','HomeTeam','AwayTeam','HTR', 'BbOU', 'BbMx>2.5', 'BbAv>2.5', 'BbMx<2.5', 'BbAv<2.5', 'B365H', 'B365D', 'B365A', 'BWH', 'BWD', 'BWA', 'IWH', 'IWD', 'IWA', 'LBH', 'LBD', 'LBA', 'PSH', 'PSD', 'PSA', 'WHH', 'WHD', 'WHA', 'VCH', 'VCD', 'VCA']]
ed_premier_league['league'] = 'premier-league'
ed_premier_league.shape


# External data of ligue-1
# http://www.football-data.co.uk/francem.php

ed_ligue_1 = pd.read_csv('C:/Users/hianj/Desktop/DataCamp Learnings/Sahaj/Football/data/2015_2017_external_data/ligue_1.csv')
ed_ligue_1 = ed_ligue_1[['Date','HomeTeam','AwayTeam','HTR', 'BbOU', 'BbMx>2.5', 'BbAv>2.5', 'BbMx<2.5', 'BbAv<2.5', 'B365H', 'B365D', 'B365A', 'BWH', 'BWD', 'BWA', 'IWH', 'IWD', 'IWA', 'LBH', 'LBD', 'LBA', 'PSH', 'PSD', 'PSA', 'WHH', 'WHD', 'WHA', 'VCH', 'VCD', 'VCA']]
ed_ligue_1['league'] = 'ligue-1'
ed_ligue_1.shape


######## Combine all the external betting data ##########


frames = [ed_bundesliga, ed_serie_a, ed_la_liga, ed_premier_league, ed_ligue_1]
ed_data_all = pd.concat(frames)
ed_data_all.head()

# Check for any null values
ed_data_all.isnull().sum()

# Check for records where HTR is null
ed_data_all[ed_data_all.HTR.isnull()]

# Replace HTR nulls iwth 'D' (for draw)
ed_data_all['HTR'] = ed_data_all['HTR'].fillna('D')

# Replace all missing numerical values with 0
ed_data_all = ed_data_all.fillna(0)

# Convert 'Date' column to date format
ed_data_all['Date'] = pd.to_datetime(ed_data_all['Date'],format='%d/%m/%y')
ed_data_all.shape

ed_data_all['Date'] = ed_data_all['Date'].dt.date
ed_data_all.sort_values(['league', 'HomeTeam', 'AwayTeam', 'Date'], inplace=True)
ed_data_all.head()

############ Join basetable data and external data #############

basetable_new = pd.merge(basetable, ed_data_all, how='left', on=['HomeTeam', 'AwayTeam', 'Date','league'])
basetable_new.shape

basetable_new.head()

# Drop columns that are not required
basetable_new.drop(['HomeTeam', 'AwayTeam', 'Date', 'league', 'Season','Last_Season', 'Last_2_Seasons', 'Year'], axis=1, inplace=True)

# Map FTR and HTR values as H:1, A:2, D: 3
ftr_map = {'H':1, 'A':2, 'D': 3}
basetable_new['FTR'] = basetable_new['FTR'].map(ftr_map)
basetable_new['HTR'] = basetable_new['HTR'].map(ftr_map)


############ Create X & y ############

y = basetable_new['FTR'].values
X = basetable_new.drop('FTR', axis=1)


############ Create train and test ############

X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.3, random_state=111, stratify=y)


# Feature Scaling
scaler = StandardScaler()
X_train_scaled = scaler.fit_transform(X_train)
X_test_scaled = scaler.transform(X_test)


###### Cross validate various models ######

num_folds = 5
seed = 2
scoring = 'accuracy'
models = []
names = []
cv_scores = []
test_accuracy = []
precisions = []
recalls = []


models.append(('LR', LogisticRegression(multi_class='multinomial', solver='newton-cg')))
models.append(('SVC', LinearSVC(multi_class='crammer_singer')))
models.append(('KNN', KNeighborsClassifier()))
models.append(('Ridge', RidgeClassifier()))
models.append(('RF', RandomForestClassifier()))


# Crossvalidate all the models and also calculate the test accuracies and other metrics for each model

for name, model in models:
    names.append(name)
    kfold = StratifiedKFold(n_splits=num_folds, random_state=seed)
    cv_results = cross_val_score(model, X_train_scaled, y_train, cv=kfold, scoring=scoring)
    cv_score_mean = round(cv_results.mean(),3)
    cv_scores.append(cv_score_mean)
    
    model.fit(X_train_scaled, y_train)
    y_pred_test = model.predict(X_test_scaled)
    accuracy_test = round(metrics.accuracy_score(y_test, y_pred_test),3)
    test_accuracy.append(accuracy_test)
    
    precision = round(precision_score(y_test, y_pred_test, average='micro'),3)
    recall = round(recall_score(y_test, y_pred_test, average='micro'),3)
    precisions.append(precision)
    recalls.append(recall)
    
    print(name, ':', cv_score_mean, ':', accuracy_test, ':', precision, ':', recall)


# Create a dataframe with all the evaluated metrices
pd_results = pd.DataFrame({'model': names, 'cv_score_train': cv_score_mean, 'test_accuracy': test_accuracy, 'precision': precisions, 'recall': recalls})
order = ['model', 'test_accuracy', 'cv_score_train', 'precision', 'recall']
pd_results = pd_results.reindex(order, axis=1)
pd_results.sort_values(['test_accuracy'], ascending=False, inplace=True)
pd_results



### Logistic Regression selected
# Fit and train the model using train data

clf = LogisticRegression(multi_class='multinomial', solver='newton-cg')
clf.fit(X_train_scaled, y_train)

# Predict on train and test
y_pred_train = clf.predict(X_train_scaled)
y_pred_test = clf.predict(X_test_scaled)

# Check accuracy of the model in train and test
train_accuracy = metrics.accuracy_score(y_train, y_pred_train)
test_accuracy = metrics.accuracy_score(y_test, y_pred_test)

print ('Multinomial Logistic regression Train Accuracy: ', train_accuracy)
print ('Multinomial Logistic regression Test Accuracy: ', test_accuracy)


########################################## Make predictions on test dataset ######################################

# Load the test dataset
test = pd.read_csv('C:/Users/hianj/Desktop/DataCamp Learnings/Sahaj/Football/data/test.csv')
test.shape

# Check for nulls
test.isnull().sum()

# Store the keys of test dataset
test_index = test['index']
test_league = test['league']
test_HT = test['HomeTeam']
test_AT = test['AwayTeam']
test_Date = test['Date']

# Drop columns which are not required
test.drop(['index', 'Referee'], axis=1,inplace=True)

# Convert Date column to a date object
test['Date'] = pd.to_datetime(test['Date'],format='%d/%m/%y')
test.head()

# Populate Season, Last_Season and Last_2_seasons
test['Season'] = '2017-18'
test['Last_Season'] = '2016-17'
test['Last_2_Seasons'] = '2015-2017'

# Create new columns to hold last season's Home Team Win(H), Away Team Win (A) and Draws (D)
test['Last_yr_H'] = 0
test['Last_yr_A'] = 0
test['Last_yr_D'] = 0

# Create new columns to hold last two season's Home Team Win(H), Away Team Win (A) and Draws (D)
test['Past_2yrs_H'] = 0
test['Past_2yrs_A'] = 0
test['Past_2yrs_D'] = 0


# Create last season data: 2016-17
last_season_data_2015_16  = train[(train['Date']>= '2016-08-01') & (train['Date'] <= '2017-05-31')]

# Aggregate last season's results: 2016-17
last_season_2016_17_results = last_season_data_2015_16.groupby(['HomeTeam', 'AwayTeam', 'FTR']).size().reset_index(name='count')
last_season_2016_17_results['Season'] = '2016-17'
last_season_2016_17_results.head()


#### Calculate values for the last season: 2016-17

# Calculating Home Team Wins, Away Team Wins and Draws in the last year
for index, row in test.iterrows():
    hometeam   = row['HomeTeam']
    awayteam   = row['AwayTeam']
    lastseason = row['Last_Season']
    
    # Calculate H (Home Team wins) in the last season
    homewin = last_season_2016_17_results.loc[(last_season_2016_17_results['Season'] == lastseason) & (last_season_2016_17_results['HomeTeam'] == hometeam) & (last_season_2016_17_results['AwayTeam'] == awayteam) & (last_season_2016_17_results['FTR'] == 'H')].reset_index()
    if len(homewin) == 0:
        H = 0
    else:
        count = homewin['count']
        H = count[0]

    # Calculate A (Away team wins) in the last season
    awaywin = last_season_2016_17_results.loc[(last_season_2016_17_results['Season'] == lastseason) & (last_season_2016_17_results['HomeTeam'] == hometeam) & (last_season_2016_17_results['AwayTeam'] == awayteam) & (last_season_2016_17_results['FTR'] == 'A')].reset_index()
    if len(awaywin) == 0:
        A = 0
    else:
        count = awaywin['count']
        A = count[0]    
    
    # Calculate D (draws) in the last season
    draws = last_season_2016_17_results.loc[(last_season_2016_17_results['Season'] == lastseason) & (last_season_2016_17_results['HomeTeam'] == hometeam) & (last_season_2016_17_results['AwayTeam'] == awayteam) & (last_season_2016_17_results['FTR'] == 'D')].reset_index()
    if len(draws) == 0:
        D = 0
    else:
        count = draws['count']
        D = count[0]      
    
    test.loc[index,'Last_yr_H'] = H
    test.loc[index,'Last_yr_A'] = A
    test.loc[index,'Last_yr_D'] = D


test.head()

#### Calculate values for the last two seasons: 2015-16, 2016-17 (2015-2017)

last_2_season_data_2015_2017  = train[(train['Date']>= '2015-08-01') & (train['Date'] <= '2017-05-31')]

# Aggregating the results from seasons: 2015-16, 2016-17
last_season_2015_2017_results = last_2_season_data_2015_2017.groupby(['HomeTeam', 'AwayTeam', 'FTR']).size().reset_index(name='count')
last_season_2015_2017_results['Season'] = '2013-2015'
last_season_2015_2017_results.head()

# Calculating Home Team Wins, Away Team Wins and Draws for the past 2 years
for index, row in test.iterrows():
    hometeam = row['HomeTeam']
    awayteam = row['AwayTeam']
    last_2_seasons = row['Last_2_Seasons']
    
    # Calculate H (Home Team wins) in the past 2 years
    homewin = last_season_2015_2017_results.loc[(last_season_2015_2017_results['Season'] == last_2_seasons) & (last_season_2015_2017_results['HomeTeam'] == hometeam) & (last_season_2015_2017_results['AwayTeam'] == awayteam) & (last_season_2015_2017_results['FTR'] == 'H')].reset_index()
    if len(homewin) == 0:
        H = 0
    else:
        count = homewin['count']
        H = count[0]

    # Calculate A (Away team wins) in the past 2 years
    awaywin = last_season_2015_2017_results.loc[(last_season_2015_2017_results['Season'] == last_2_seasons) & (last_season_2015_2017_results['HomeTeam'] == hometeam) & (last_season_2015_2017_results['AwayTeam'] == awayteam) & (last_season_2015_2017_results['FTR'] == 'A')].reset_index()
    if len(awaywin) == 0:
        A = 0
    else:
        count = awaywin['count']
        A = count[0]    
    
    # Calculate D (draws) in the past 2 years
    draws = last_season_2015_2017_results.loc[(last_season_2015_2017_results['Season'] == last_2_seasons) & (last_season_2015_2017_results['HomeTeam'] == hometeam) & (last_season_2015_2017_results['AwayTeam'] == awayteam) & (last_season_2015_2017_results['FTR'] == 'D')].reset_index()
    if len(draws) == 0:
        D = 0
    else:
        count = draws['count']
        D = count[0]    

    test.loc[index,'Past_2yrs_H'] = H
    test.loc[index,'Past_2yrs_A'] = A
    test.loc[index,'Past_2yrs_D'] = D


# Populate defending champion data

# Create 2 new columns to represent if HT (Home Team) or AT(Away team) is the current defending champion
test['Is_HT_Defending_Champion'] = 0
test['Is_AT_Defending_Champion'] = 0

# Check if Home Team of Away Team is the Defending Champion from last season
for index, row in test.iterrows():
    hometeam = row['HomeTeam']
    awayteam = row['AwayTeam']
    league = row['league']
    lastseason = row['Last_Season']
    
    champion = champions[(champions['Season'] == lastseason) & (champions['League'] == league)].reset_index()
    defending_champ = champion['Champion'][0]
    
    if defending_champ == hometeam:
        test.loc[index,'Is_HT_Defending_Champion'] = 1
        
    if defending_champ == awayteam:
        test.loc[index,'Is_AT_Defending_Champion'] = 1

# Populate current team standings data from 2016-17 matches
# Create 2 new columns to store current team standing of Home Team and Away Team (standing is the rank from last season)
test['HT_Standing'] = 0
test['AT_Standing'] = 0

for index, row in test.iterrows():
    hometeam = row['HomeTeam']
    awayteam = row['AwayTeam']
    lastseason = row['Last_Season']
    
    # Retrieve the current standing of the home team (rank from last season)
    standing = team_standings[(team_standings['Season'] == lastseason) & (team_standings['Team'] == hometeam)].reset_index()
    if len(standing) == 0:
        hometeam_standing = 999
    else:
        hometeam_standing = standing['Standing'][0]
    
    test.loc[index,'HT_Standing'] = hometeam_standing
    
    # Retrieve the current standing of the away team (rank from last season)
    standing = team_standings[(team_standings['Season'] == lastseason) & (team_standings['Team'] == awayteam)].reset_index()
    if len(standing) == 0:
        awayteam_standing = 999
    else:
        awayteam_standing = standing['Standing'][0]
    
    test.loc[index,'AT_Standing'] = awayteam_standing


#### Load external data for all leagues for season 2016-17

tst_ed_bundesliga = pd.read_csv('C:/Users/hianj/Desktop/DataCamp Learnings/Sahaj/Football/data/2017_18_external_data/bundesliga.csv')
tst_ed_bundesliga = tst_ed_bundesliga[['Date','HomeTeam','AwayTeam','HTR', 'BbOU', 'BbMx>2.5', 'BbAv>2.5', 'BbMx<2.5', 'BbAv<2.5', 'B365H', 'B365D', 'B365A', 'BWH', 'BWD', 'BWA', 'IWH', 'IWD', 'IWA', 'LBH', 'LBD', 'LBA', 'PSH', 'PSD', 'PSA', 'WHH', 'WHD', 'WHA', 'VCH', 'VCD', 'VCA']]
tst_ed_bundesliga['league'] = 'bundesliga'
tst_ed_bundesliga.shape

tst_ed_serie_a = pd.read_csv('C:/Users/hianj/Desktop/DataCamp Learnings/Sahaj/Football/data/2017_18_external_data/serie_a.csv')
tst_ed_serie_a = tst_ed_serie_a[['Date','HomeTeam','AwayTeam','HTR', 'BbOU', 'BbMx>2.5', 'BbAv>2.5', 'BbMx<2.5', 'BbAv<2.5', 'B365H', 'B365D', 'B365A', 'BWH', 'BWD', 'BWA', 'IWH', 'IWD', 'IWA', 'LBH', 'LBD', 'LBA', 'PSH', 'PSD', 'PSA', 'WHH', 'WHD', 'WHA', 'VCH', 'VCD', 'VCA']]
tst_ed_serie_a['league'] = 'serie-a'
tst_ed_serie_a.shape

tst_ed_la_liga = pd.read_csv('C:/Users/hianj/Desktop/DataCamp Learnings/Sahaj/Football/data/2017_18_external_data/la_liga.csv')
tst_ed_la_liga = tst_ed_la_liga[['Date','HomeTeam','AwayTeam','HTR', 'BbOU', 'BbMx>2.5', 'BbAv>2.5', 'BbMx<2.5', 'BbAv<2.5', 'B365H', 'B365D', 'B365A', 'BWH', 'BWD', 'BWA', 'IWH', 'IWD', 'IWA', 'LBH', 'LBD', 'LBA', 'PSH', 'PSD', 'PSA', 'WHH', 'WHD', 'WHA', 'VCH', 'VCD', 'VCA']]
tst_ed_la_liga['league'] = 'la-liga'
tst_ed_la_liga.shape

tst_ed_premier_league = pd.read_csv('C:/Users/hianj/Desktop/DataCamp Learnings/Sahaj/Football/data/2017_18_external_data/premier_league.csv')
tst_ed_premier_league = tst_ed_premier_league[['Date','HomeTeam','AwayTeam','HTR', 'BbOU', 'BbMx>2.5', 'BbAv>2.5', 'BbMx<2.5', 'BbAv<2.5', 'B365H', 'B365D', 'B365A', 'BWH', 'BWD', 'BWA', 'IWH', 'IWD', 'IWA', 'LBH', 'LBD', 'LBA', 'PSH', 'PSD', 'PSA', 'WHH', 'WHD', 'WHA', 'VCH', 'VCD', 'VCA']]
tst_ed_premier_league['league'] = 'premier-league'
tst_ed_premier_league.shape

tst_ed_ligue_1 = pd.read_csv('C:/Users/hianj/Desktop/DataCamp Learnings/Sahaj/Football/data/2017_18_external_data/ligue_1.csv')
tst_ed_ligue_1 = tst_ed_ligue_1[['Date','HomeTeam','AwayTeam','HTR', 'BbOU', 'BbMx>2.5', 'BbAv>2.5', 'BbMx<2.5', 'BbAv<2.5', 'B365H', 'B365D', 'B365A', 'BWH', 'BWD', 'BWA', 'IWH', 'IWD', 'IWA', 'LBH', 'LBD', 'LBA', 'PSH', 'PSD', 'PSA', 'WHH', 'WHD', 'WHA', 'VCH', 'VCD', 'VCA']]
tst_ed_ligue_1['league'] = 'ligue-1'
tst_ed_ligue_1.shape


######## Combine all the external data ##########

frames = [tst_ed_bundesliga, tst_ed_serie_a, tst_ed_la_liga, tst_ed_premier_league, tst_ed_ligue_1]
tst_ed_data_all = pd.concat(frames)
tst_ed_data_all.head()

tst_ed_data_all.isnull().sum()

# Replace all missing numerical values with 0
tst_ed_data_all = tst_ed_data_all.fillna(0)

# Convert 'Date' column to date format
tst_ed_data_all['Date'] = pd.to_datetime(tst_ed_data_all['Date'],format='%d/%m/%y')
#tst_ed_data_all['Date'] = tst_ed_data_all['Date'].dt.date

tst_ed_data_all.shape

# Sort the dataframe
tst_ed_data_all.sort_values(['league', 'HomeTeam', 'AwayTeam', 'Date'], inplace=True)
tst_ed_data_all.head()

# Combine the test dataset and the external data collected
test_new = pd.merge(test, tst_ed_data_all, how='left', on=['HomeTeam', 'AwayTeam', 'Date','league'])
test_new.shape

test_new.head()

# Drop columns which are not required for the model
test_new.drop(['HomeTeam', 'AwayTeam', 'Date', 'league', 'Season','Last_Season', 'Last_2_Seasons'], axis=1, inplace=True)

# Map FTR and HTR values as H:1, A:2, D: 3
ftr_map = {'H':1, 'A':2, 'D': 3}
test_new['HTR'] = test_new['HTR'].map(ftr_map)

test_new.shape

# Scale data using StandardScaler fitted in train
test_scaled = scaler.transform(test_new)


############ Predict on the test data ############

predictions = clf.predict(test_scaled)

# Create a dataframe with keys of test dataset and the predictions made
results = pd.DataFrame({
        'Index': test_index,
        'league': test_league,
        'HomeTeam': test_HT,
        'AwayTeam': test_AT,
        'Date': test_Date,
        'FTR': predictions
    })

# Map FTR and HTR values as H:1, A:2, D: 3
ftr_map = {1:'H', 2:'A', 3:'D'}
results['FTR'] = results['FTR'].map(ftr_map)

# Output file 
filename = 'C:/Users/hianj/Desktop/DataCamp Learnings/Sahaj/Football/results_2017_18.csv'
results.to_csv(filename, sep=',', index = False)