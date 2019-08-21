# Importing libraries for EDA
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns; sns.set_style('darkgrid')

# Data preparation
from scipy.stats import norm, skew
import sklearn.preprocessing as preproc
from sklearn.preprocessing import MinMaxScaler
from sklearn.model_selection import train_test_split

# Modelling
from sklearn.linear_model import Ridge, Lasso, ElasticNet
from sklearn.ensemble import RandomForestRegressor, GradientBoostingRegressor
from sklearn.grid_search import GridSearchCV


# Read the training dataset
train = pd.read_csv('../training_data.csv')


# Print the number of rows and columns of the train dataset
train.shape

# Check for the datatypes of each column
train.info()
# No nulls found


# Strip the preceding spaces in the column names
train.columns = train.columns.str.strip()


# Rename the column 'shares' to 'Target'
train = train.rename(columns = {'shares': 'target'})


# Drop the columns url_id and timedelta as both are non-predictive
train = train.drop(['url_id', 'timedelta'], axis=1)


################################ EDA ################################

# Function to check if there are any missing values
def missing_vals(dataset):
    null_columns=dataset.columns[dataset.isnull().any()]
    print(dataset[null_columns].isnull().sum())
    
# Call the function to check if train dataset has any missing values
missing_vals(train)
# No missing values in train    

# Check if the target is skewed
sns.distplot(train['target'], fit=norm)
# Target is right skewed


# Explore correlation beween target and number of words in the url
plt.figure(figsize=(5,5))
plt.scatter(x=train['n_tokens_content'], y=train['target'])
plt.xlabel('No:of words in content')
plt.ylabel('No:of shares')
# The more the text in the content lesser the shares


# Explore correlation beween target and number of images in the url
plt.figure(figsize=(5,5))
plt.scatter(x=train['num_imgs'], y=train['target'])
plt.xlabel('No:of images')
plt.ylabel('No:of shares')
# Images are important but too many images is not yielding many shares. Beyond 20 images is not resulting in increased shares.

# Explore correlation beween target and number of videos in the url
plt.figure(figsize=(5,5))
plt.scatter(x=train['num_videos'], y=train['target'])
plt.xlabel('No:of videos')
plt.ylabel('No:of shares')
# Beyond 10 videos per link is not yielding much shares


# Explore correlation beween target and number of links in the url
plt.figure(figsize=(5,5))
plt.scatter(x=train['num_hrefs'], y=train['target'])
plt.xlabel('No:of links')
plt.ylabel('No:of shares')
# Beyond 30 hyperlinks per link is not yielding much shares


# Check the distribution of articles on number of words in title
n_tokens_title_grouped = train.groupby(['n_tokens_title']).size().reset_index()
n_tokens_title_grouped = n_tokens_title_grouped.rename(columns={n_tokens_title_grouped.columns[1]: 'size' })
n_tokens_title_grouped = n_tokens_title_grouped.sort_values('size', ascending=False)
plt.scatter(n_tokens_title_grouped['n_tokens_title'], n_tokens_title_grouped['size'])
# Most articles have title having 5-15 words


# Check the distribution of articles on weekdays Vs weekends
train.groupby(['is_weekend']).size()
# More articles are published during weekdays than weekends


# Plot histogram of features to see if any are skewed
features = train.columns.values

n = 1
plt.figure(figsize=(15,35))
for each in features:
    plt.subplot(15, 4, n)
    plt.hist(train[each])
    plt.title(each)
    n = n + 1
plt.tight_layout()
plt.show()


# Check for correlation between the features and the target where correlation is greater than 0.03
plt.figure(figsize=(10,10))
corr = train.corr()
top_corr_features = corr.index[abs(corr['target'])>0.03]
sns.heatmap(train[top_corr_features].corr(), annot=True,cmap="RdYlGn")
# Linear correlation between the features and target is very low

############ Data pre-processing ############

# Right skewed features which need log transformation: n_tokens_content, num_hrefs, num_self_hrefs, num_imgs, num_videos
train['log_n_tokens_content'] = np.log10(train['n_tokens_content'] + 1)
train['log_num_hrefs'] = np.log10(train['num_hrefs'] + 1)
train['log_num_self_hrefs'] = np.log10(train['num_self_hrefs'] + 1)
train['log_num_imgs'] = np.log10(train['num_imgs'] + 1)
train['log_num_videos'] = np.log10(train['num_videos'] + 1)
train = train.drop(['n_tokens_content', 'num_hrefs', 'num_self_hrefs', 'num_imgs', 'num_videos'], axis=1)


# Plot the transformed features
features = ['log_n_tokens_content', 'log_num_hrefs', 'log_num_self_hrefs', 'log_num_imgs', 'log_num_videos']
plt.figure(figsize=(15,3))
n = 1
for each in features:
    plt.subplot(1, 5, n)
    plt.hist(train[each])
    plt.title(each)
    n = n + 1
plt.tight_layout()
plt.show()


# Correct skewness in target
train['target'] = np.log1p(train['target'])


# Seperate X & y
X = train.drop('target', axis=1)
y = train['target']

############ Feature Selection ############

# Feature selection using RandomForestRegressor
forest = RandomForestRegressor(n_estimators=100, n_jobs=-1)
forest.fit(X, y)
importances = forest.feature_importances_
indices = np.argsort(importances)[::-1]


# Get the feature names and their indexes
features = X.columns.values
features = list(features)
feature_index = []
for each in features:
    indx = X.columns.get_loc(each)
    feature_index.append(indx)
features_indices = pd.DataFrame({'feature' :features, 'index':feature_index})


# Plot the feature importances of the forest
plt.figure(figsize=(15,3))
plt.title("Feature importances")
plt.bar(range(X.shape[1]), importances[indices], color="r")
plt.xticks(range(X.shape[1]), indices)
plt.xlim([-1, X.shape[1]])
plt.show()
# Feature 2 is not very useful. So it can be dropped


# Retrieve the name of the least important feature
features_indices[features_indices['index']==2]


# Drop the least important feature: n_non_stop_words
X = X.drop(['n_non_stop_words'], axis=1)


############### Feature Scaling ###############

scaler = MinMaxScaler()
X_scaled = scaler.fit_transform(X)


############### Model building ###############

# Train and test data creation
X_train, X_test, y_train, y_test = train_test_split(X_scaled, y, test_size=0.3, random_state=0)

# Function to calculate MAPE
def mean_absolute_percentage_error(y_true, y_pred): 
    y_true, y_pred = np.array(y_true), np.array(y_pred)
    return np.mean(np.abs((y_true - y_pred) / y_true)) * 100


# Lasso
lasso = Lasso(alpha =0.0005, random_state=1)
lasso.fit(X_train,y_train)
y_pred = lasso.predict(X_test)

mape = mean_absolute_percentage_error(y_test, y_pred)
print(mape)


# Ridge
ridge = Ridge(alpha =0.0005, random_state=1)
ridge.fit(X_train,y_train)
y_pred = ridge.predict(X_test)

mape = mean_absolute_percentage_error(y_test, y_pred)
print(mape)


# ElasticNet
EN = ElasticNet(alpha=0.0005, l1_ratio=.9, random_state=3)
EN.fit(X_train,y_train)
y_pred = EN.predict(X_test)

mape = mean_absolute_percentage_error(y_test, y_pred)
print(mape)


# RandomForestRegressor
rf = RandomForestRegressor(n_estimators = 100, random_state = 42)

rf.fit(X_train,y_train)
y_pred = rf.predict(X_test)

mape = mean_absolute_percentage_error(y_test, y_pred)
print(mape)


# GradientBoostingRegressor
GBoost = GradientBoostingRegressor(n_estimators=1000, learning_rate=0.01,
                                   max_depth=6, max_features='sqrt',
                                   min_samples_leaf=15, min_samples_split=10, 
                                   loss='huber', random_state =5)

GBoost.fit(X_train,y_train)
y_pred = GBoost.predict(X_test)

mape = mean_absolute_percentage_error(y_test, y_pred)
print(mape)


################## Process test dataset ###################

# Read the test dataset
test = pd.read_csv('C:/Users/hianj/Desktop/Sigmoid/test_data.csv')


# Print the number of rows and columns of the test dataset
test.shape

# Call the function to check if test dataset has any missing values
missing_vals(test)
# No missing values in test

# Strip the preceding spaces in the column names
test.columns = test.columns.str.strip()


# Store the url_ids before dropping the column
test_url_ids = test['url_id']


# Drop the columns url_id and timedelta
test = test.drop(['url_id', 'timedelta', 'n_non_stop_words'], axis=1)


# Log transform the right skewed features: n_tokens_content, num_hrefs, num_self_hrefs, num_imgs, num_videos
test['log_n_tokens_content'] = np.log10(test['n_tokens_content'] + 1)
test['log_num_hrefs'] = np.log10(test['num_hrefs'] + 1)
test['log_num_self_hrefs'] = np.log10(test['num_self_hrefs'] + 1)
test['log_num_imgs'] = np.log10(test['num_imgs'] + 1)
test['log_num_videos'] = np.log10(test['num_videos'] + 1)


# Drop the skewed columns: n_tokens_content, num_hrefs, num_self_hrefs, num_imgs, num_videos
test = test.drop(['n_tokens_content', 'num_hrefs', 'num_self_hrefs', 'num_imgs', 'num_videos'], axis=1)


# Apply the MinMaxScaler to the test data
test_scaled = scaler.transform(test)


# Predict the test data using the best model: GBoost (GradientBoostingRegressor)
predictions = np.expm1(GBoost.predict(test_scaled))
predictions1 = [int(each) for each in predictions]


# Create the submission file with url_id and the predicted 'share values
sub = pd.DataFrame()
sub['url_id'] = test_url_ids
sub['shares'] = predictions1
sub.to_csv('../final_submission.csv',index=False)

