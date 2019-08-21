
# coding: utf-8

# In[118]:


# EDA
import numpy as np 
import pandas as pd 
import matplotlib.pyplot as plt  
import seaborn as sns; color = sns.color_palette(); sns.set_style('darkgrid')
from scipy import stats
from scipy.stats import norm, skew
# Data Preprocessing
from sklearn.preprocessing import LabelEncoder
from scipy.special import boxcox1p
from sklearn.pipeline import make_pipeline
from sklearn.preprocessing import RobustScaler
# Models
from sklearn.linear_model import ElasticNet, Lasso
from sklearn.ensemble import GradientBoostingRegressor
from sklearn.kernel_ridge import KernelRidge
# Model evaluation
from sklearn.model_selection import KFold, cross_val_score


# In[124]:


train = pd.read_csv('train.csv')
test = pd.read_csv('test.csv')


# In[126]:


# Store the 'ID' column and drop it from the train and test datasets
train_ID = train['Id']
test_ID = test['Id']

train.drop('Id', axis = 1, inplace = True)
test.drop('Id', axis = 1, inplace = True)


# In[127]:


##### EDA #####


# In[128]:


# Check for skewness in target data
sns.distplot(train['SalePrice'] , fit=norm);


# In[129]:


# Check for Correlation between target and numeric features
numeric_data = train.select_dtypes(include=[np.number])

plt.figure(figsize=(15,7))
corr = numeric_data.corr()
top_corr_features = corr.index[abs(corr["SalePrice"])>0.3]
sns.heatmap(numeric_data[top_corr_features].corr(), annot=True,cmap="RdYlGn")

# Top features found: 'OverallQual', 'GrLivArea', 'GarageCars', 'GarageArea', 'TotalBsmtSF', '1stFlrSF'


# In[130]:


top_features = ['OverallQual', 'GrLivArea', 'GarageCars', 'GarageArea', 'TotalBsmtSF', '1stFlrSF']
n = 1
plt.figure(figsize=(15,8))
for each in top_features:
    plt.subplot(2, 3, n)
    plt.scatter(x = train[each], y = train['SalePrice'])
    plt.title(each)
    n = n + 1
plt.tight_layout()
plt.show()


# In[131]:


### Outlier treatment

train = train.drop(train[(train['GrLivArea']>4000) & (train['SalePrice']<300000)].index)


# In[132]:


# Correct skewness in target
train["SalePrice"] = np.log1p(train["SalePrice"])

# Check target again
sns.distplot(train['SalePrice'] , fit=norm)


# In[133]:


# Store SalePrice in y_train
y_train = train.SalePrice.values


# In[134]:


ntrain = train.shape[0]
ntest = test.shape[0]

all_data = pd.concat((train, test)).reset_index(drop=True)
all_data.drop(['SalePrice'], axis=1, inplace=True)
print("all_data size is : {}".format(all_data.shape))


# In[135]:


all_data["PoolQC"] = all_data["PoolQC"].fillna("None")


# In[136]:


all_data["MiscFeature"] = all_data["MiscFeature"].fillna("None")


# In[137]:


all_data["Alley"] = all_data["Alley"].fillna("None")


# In[138]:


all_data["Fence"] = all_data["Fence"].fillna("None")


# In[139]:


all_data["FireplaceQu"] = all_data["FireplaceQu"].fillna("None")


# In[140]:


all_data["LotFrontage"] = all_data.groupby("Neighborhood")["LotFrontage"].transform(
    lambda x: x.fillna(x.median()))


# In[141]:


for col in ['GarageType', 'GarageFinish', 'GarageQual', 'GarageCond']:
    all_data[col] = all_data[col].fillna('None')


# In[142]:


for col in ('GarageYrBlt', 'GarageArea', 'GarageCars'):
    all_data[col] = all_data[col].fillna(0)


# In[143]:


for col in ('BsmtFinSF1', 'BsmtFinSF2', 'BsmtUnfSF','TotalBsmtSF', 'BsmtFullBath', 'BsmtHalfBath'):
    all_data[col] = all_data[col].fillna(0)


# In[144]:


for col in ('BsmtQual', 'BsmtCond', 'BsmtExposure', 'BsmtFinType1', 'BsmtFinType2'):
    all_data[col] = all_data[col].fillna('None')


# In[145]:


all_data["MasVnrType"] = all_data["MasVnrType"].fillna("None")
all_data["MasVnrArea"] = all_data["MasVnrArea"].fillna(0)


# In[146]:


all_data['MSZoning'] = all_data['MSZoning'].fillna(all_data['MSZoning'].mode()[0])


# In[147]:


all_data = all_data.drop(['Utilities'], axis=1)


# In[148]:


all_data["Functional"] = all_data["Functional"].fillna("Typ")


# In[149]:


mode_col = ['Electrical','KitchenQual', 'Exterior1st', 'Exterior2nd', 'SaleType']
for col in mode_col:
    all_data[col] = all_data[col].fillna(all_data[col].mode()[0])


# In[150]:


all_data['MSSubClass'] = all_data['MSSubClass'].fillna("None")


# In[151]:


#MSSubClass=The building class
all_data['MSSubClass'] = all_data['MSSubClass'].apply(str)


#Changing OverallCond into a categorical variable
all_data['OverallCond'] = all_data['OverallCond'].astype(str)


#Year and month sold are transformed into categorical features.
all_data['YrSold'] = all_data['YrSold'].astype(str)
all_data['MoSold'] = all_data['MoSold'].astype(str)


# In[152]:


# Label encode categorical features

cols = ('FireplaceQu', 'BsmtQual', 'BsmtCond', 'GarageQual', 'GarageCond', 
        'ExterQual', 'ExterCond','HeatingQC', 'PoolQC', 'KitchenQual', 'BsmtFinType1', 
        'BsmtFinType2', 'Functional', 'Fence', 'BsmtExposure', 'GarageFinish', 'LandSlope',
        'LotShape', 'PavedDrive', 'Street', 'Alley', 'CentralAir', 'MSSubClass', 'OverallCond', 
        'YrSold', 'MoSold')

for c in cols:
    lbl = LabelEncoder() 
    lbl.fit(list(all_data[c].values)) 
    all_data[c] = lbl.transform(list(all_data[c].values))
   
all_data.shape


# In[153]:


# Create new feature which is the total of all square footages

all_data['TotalSF'] = all_data['TotalBsmtSF'] + all_data['1stFlrSF'] + all_data['2ndFlrSF']


# In[154]:


# Calculate the skew of all numerical features

numeric_feats = all_data.dtypes[all_data.dtypes != "object"].index

skewed_feats = all_data[numeric_feats].apply(lambda x: skew(x.dropna())).sort_values(ascending=False)
skewness = pd.DataFrame({'Skew' :skewed_feats})
skewness.head(5)


# In[155]:


skewness = skewness[abs(skewness) > 0.75]

skewed_features = skewness.index
lam = 0.15
for feat in skewed_features:
    all_data[feat] = boxcox1p(all_data[feat], lam)


# In[156]:


all_data = pd.get_dummies(all_data)
all_data.shape


# In[159]:


X_train = all_data[:ntrain]

test = all_data[ntrain:]


# In[163]:


KRR = KernelRidge(alpha=0.6, kernel='polynomial', degree=2, coef0=2.5)
KRR.fit(X_train,y_train)


# In[164]:


lasso = make_pipeline(RobustScaler(), Lasso(alpha =0.0005, random_state=1))
lasso.fit(X_train,y_train)


# In[165]:


ENet = make_pipeline(RobustScaler(), ElasticNet(alpha=0.0005, l1_ratio=.9, random_state=3))
ENet.fit(X_train,y_train)


# In[166]:


GBoost = GradientBoostingRegressor(n_estimators=3000, learning_rate=0.05,
                                   max_depth=4, max_features='sqrt',
                                   min_samples_leaf=15, min_samples_split=10, 
                                   loss='huber', random_state =5)
GBoost.fit(X_train,y_train)


# In[114]:


LassoMd = lasso.fit(X_train,y_train)
ENetMd = ENet.fit(X_train,y_train)
KRRMd = KRR.fit(X_train,y_train)
GBoostMd = GBoost.fit(X_train,y_train)


# In[167]:


predictions = (np.expm1(lasso.predict(test.values)) + np.expm1(ENet.predict(test.values)) + np.expm1(KRR.predict(test.values)) + np.expm1(GBoost.predict(test.values)) ) / 4
predictions


# In[168]:


sub = pd.DataFrame()
sub['url_id'] = test_ID
sub['shares'] = predictions
sub.to_csv('prediction.csv',index=False)

