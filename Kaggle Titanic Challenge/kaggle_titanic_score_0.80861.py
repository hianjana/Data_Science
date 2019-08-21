
# coding: utf-8

# In[167]:


# Import all required libraries for EDA, Data pre-processing
import pandas as pd
import numpy as np
import re
import matplotlib.pyplot as plt
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import Imputer
from sklearn.preprocessing import OneHotEncoder, LabelEncoder
import seaborn as sns
sns.set(style='white', context='notebook', palette='deep')


# In[168]:


# Import all libraries for algorithms
from sklearn.ensemble import RandomForestClassifier, GradientBoostingClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.neighbors import KNeighborsClassifier
from sklearn.tree import DecisionTreeClassifier
from sklearn.svm import SVC


# In[169]:


# Import libraries for model evaluation
from sklearn.model_selection import GridSearchCV, cross_val_score, StratifiedKFold, learning_curve
from sklearn.metrics import accuracy_score, confusion_matrix
from sklearn.metrics import precision_score, recall_score
from sklearn.metrics import f1_score


# In[4]:


# Load the train and test datasets
df_train = pd.read_csv('C:/Users/hianj/Desktop/DataCamp Learnings/Titanic Dataset/train.csv')
df_test = pd.read_csv('C:/Users/hianj/Desktop/DataCamp Learnings/Titanic Dataset/test.csv')


# In[5]:


#################################### EDA and Data-Preprocessing ####################################


# In[6]:


df_train.head()


# In[7]:


# Store PassengerId before dropping it
df_test_passengers = df_test['PassengerId']


# In[8]:


# Drop PassengerId from train and test datasets as it is just a continuous number
df_train = df_train.drop('PassengerId',axis=1)
df_test = df_test.drop('PassengerId',axis=1)


# In[9]:


df_train.info()


# In[10]:


#### Check for missing values in columns in train and test datasets


# In[11]:


def missing_vals(dataset):
    null_columns=dataset.columns[dataset.isnull().any()]
    print(dataset[null_columns].isnull().sum())


# In[12]:


missing_vals(df_train)


# In[13]:


missing_vals(df_test)


# In[14]:


########## Fill missing values for: Age ##########


# In[15]:


imp = Imputer(missing_values='NaN', strategy='most_frequent', axis=0)
imp.fit(df_train[['Age']])
df_train['Age'] = imp.transform(df_train[['Age']])

df_test['Age'] = imp.transform(df_test[['Age']])


# In[16]:


# Convert Age to integer
data = [df_train, df_test]

for dataset in data:
    dataset['Age'] = dataset['Age'].astype(int)


# In[17]:


missing_vals(df_train)


# In[18]:


missing_vals(df_test)


# In[19]:


########## Fill missing values for: Embarked ##########


# In[20]:


# Check for most frequent value in train dataset
plt.hist(df_train['Embarked'])
#df_train.groupby(['Embarked']).size()


# In[21]:


# Replace missing values in train dataset for the column 'Embarked' with the most frequent value of train: 'S'
# Fill NaN values in column 'Embarked' as 'S'
df_train['Embarked'].fillna('S',inplace=True)


# In[22]:


missing_vals(df_train)


# In[23]:


########## Fill missing values for: Fare ##########


# In[24]:


# Replace missing values in test for 'Fare' with 0
df_test['Fare'].fillna(0,inplace=True)


# In[25]:


missing_vals(df_test)


# In[26]:


########## Fill missing values for: Cabin ##########


# In[27]:


# Replace missing values for Cabin with 'U' for 'Unknown'
df_train['Cabin'].fillna('U',inplace=True)
df_test['Cabin'].fillna('U',inplace=True)


# In[28]:


missing_vals(df_train)


# In[29]:


missing_vals(df_test)


# In[30]:


#### Analyse columns: SibSp, Parch, Fare


# In[31]:


# Calculate FamilySize in order to calculate Fare Per Person


# In[32]:


# Create new column 'FamilySize' which is SibSp + Parch + 1 (1 is added to represent oneself)
dataset = [df_train, df_test]
for data in dataset:
    data['FamilySize'] = ''
    data['FamilySize'] = data['SibSp'] + data['Parch'] + 1


# In[33]:


# Convert Fare to integer
data = [df_train, df_test]
for dataset in data:
    dataset['Fare'] = dataset['Fare'].astype(int)


# In[34]:


# Create new column 'FarePP' which is FarePerPerson by dividing Fare by FamilySize to get individual person's fare
dataset=[df_train, df_test]
for data in dataset:
    data['FarePP'] = ''
    data['FarePP'] = data['Fare']/ data['FamilySize']


# In[35]:


# Convert FarePP to integer
data = [df_train, df_test]
for dataset in data:
    dataset['FarePP'] = dataset['FarePP'].astype(int)


# In[36]:


###### Analyse column: Sex ######


# In[37]:


sns.countplot(x="Sex", hue="Survived", data=df_train);


# In[38]:


# Map 'male' to 0 and 'female' to 1 in both train and test
# Convert the datatype to int
data = [df_train, df_test]

for dataset in data:
    dataset['Sex'] = dataset['Sex'].map({'male':0, 'female':1})
    dataset['Sex'] = dataset['Sex'].astype(int)


# In[39]:


##### Analyse column: Pclass #####


# In[40]:


sns.countplot(x="Pclass", hue="Survived", data=df_train);


# In[41]:


##### Analyse column: Embarked #####


# In[42]:


sns.countplot(x='Embarked', hue='Survived', data=df_train)


# In[43]:


# Analyse column: FamilySize


# In[44]:


sns.countplot(x='FamilySize', hue='Survived', data=df_train)


# In[45]:


dataset = [df_train, df_test]
for data in dataset:
    data['Family'] = ''
    data.loc[data['FamilySize'] == 1, 'Family'] = 1
    data.loc[(data['FamilySize'] > 1) & (data['FamilySize'] <= 4), 'Family'] = 2
    data.loc[data['FamilySize'] > 4, 'Family' ] = 3 


# In[46]:


df_train = df_train.drop(['SibSp', 'Parch'], axis=1)
df_test = df_test.drop(['SibSp', 'Parch'], axis=1)


# In[47]:


##### Analyse column: Cabin #####


# In[48]:


df_train['Cabin'].unique()


# In[49]:


# Extract Deck from the column Cabin as 'Deck' and drop Cabin
df_train['Deck'] = df_train['Cabin'].str.slice(0,1)
df_test['Deck'] = df_test['Cabin'].str.slice(0,1)


# In[50]:


sns.countplot(x='Deck', hue='Survived', data=df_train)


# In[51]:


# Count number of people per Deck in train
df_train.groupby(['Deck']).size()


# In[52]:


# Count number of people per Deck in test
df_test.groupby(['Deck']).size()


# In[53]:


# Replace 'T' with 'U' for Deck in train as there is only one person
df_train.loc[df_train['Deck'] == 'T', 'Deck'] = 'U'


# In[54]:


# Check again
df_train.groupby(['Deck']).size()


# In[55]:


# Drop the column Cabin
df_train = df_train.drop(['Cabin'], axis=1)
df_test = df_test.drop(['Cabin'], axis=1)


# In[56]:


##### Analyse column: Age #####


# In[59]:


# To see how Age and Survival are correlated
age_xt = pd.crosstab(df_train['Age'], df_train['Survived'])
age_xt_pct = age_xt.div(age_xt.sum(1).astype(float), axis=0)

age_xt_pct.plot(kind='bar', 
                  stacked=True, 
                  title='Age & Survival')
plt.xlabel('Age')
plt.ylabel('Survival Rate')
plt.rcParams["figure.figsize"] = (35, 3)


# In[60]:


df_train['AgeBin'] = pd.qcut(df_train['Age'], 4)


# In[61]:


df_train['AgeBin'].unique()


# In[62]:


# Binning for the column 'Age' in test dataset by referencing the bins formed in train dataset
bins = [-0.001, 22.0, 24.0, 35.0, 80.0]
df_test['AgeBin'] = pd.cut(df_test['Age'], bins)


# In[63]:


df_test['AgeBin'].unique()


# In[64]:


label = LabelEncoder()
df_train['AgeBinCode'] = label.fit_transform(df_train['AgeBin'])
df_test['AgeBinCode'] = label.transform(df_test['AgeBin'])


# In[65]:


df_train['AgeBinCode'].unique()


# In[66]:


df_test['AgeBinCode'].unique()


# In[67]:


sns.countplot(x='AgeBinCode', hue='Survived', data=df_train)


# In[68]:


# Drop the column: Age, AgeBin
df_train = df_train.drop(['Age', 'AgeBin'], axis=1)
df_test = df_test.drop(['Age', 'AgeBin'], axis=1)


# In[69]:


#df_train.head()
df_test.head()


# In[70]:


##### Analyse column: FarePP #####


# In[71]:


# Sort dataframe by 'FarePP' descending order to see it's relation with 'Ticket'
df_train.sort_values(by='FarePP', ascending=False).head(10)
# Those with the same fare have the same Ticket Number. Hence,the column 'Ticket' doesn't seem to give any significant information


# In[72]:


# To see how FarePP and Survival are correlated
farepp_xt = pd.crosstab(df_train['FarePP'], df_train['Survived'])
farepp_xt_pct = farepp_xt.div(farepp_xt.sum(1).astype(float), axis=0)

farepp_xt_pct.plot(kind='bar', 
                  stacked=True, 
                  title='FarePP & Survival')
plt.xlabel('FarePP')
plt.ylabel('Survival Rate')
plt.rcParams["figure.figsize"] = (28, 5)


# In[74]:


df_train['FarePPBin'] = pd.qcut(df_train['FarePP'], 4)


# In[75]:


df_train['FarePPBin'].unique()


# In[76]:


# Binning for the column 'FarePP' in test dataset by referencing the bins formed in train dataset
bins = [-0.001, 7.0, 8.0, 23.0, 512.0]
df_test['FarePPBin'] = pd.cut(df_test['FarePP'], bins)


# In[77]:


df_test['FarePPBin'].unique()


# In[78]:


farelabel = LabelEncoder()
df_train['FareBinCode'] = farelabel.fit_transform(df_train['FarePPBin'])
df_test['FareBinCode'] = farelabel.transform(df_test['FarePPBin'])


# In[81]:


df_train['FareBinCode'].unique()


# In[82]:


df_test['FareBinCode'].unique()


# In[83]:


sns.countplot(x='FareBinCode', hue='Survived', data=df_train)


# In[85]:


# Drop columns: Fare, FamilySize
df_train = df_train.drop(['Fare', 'FamilySize', 'FarePPBin', 'FarePP'], axis=1)
df_test = df_test.drop(['Fare', 'FamilySize', 'FarePPBin', 'FarePP'], axis=1)


# In[292]:


###### Analyse column: Ticket


# In[88]:


df_train['Ticket'].unique()


# In[89]:


# Drop the column Ticket as it is not having any significant information
df_train = df_train.drop('Ticket', axis=1)
df_test = df_test.drop('Ticket', axis=1)


# In[90]:


##### Analyse the column: Name #####


# In[91]:


# Create a new column: Title
df_train['Title'] = ''
df_test['Title'] = ''


# In[92]:


# Extract titles into this column
df_train['Title'] = df_train.Name.str.extract(' ([A-Za-z]+)\.', expand=False)
df_test['Title'] = df_test.Name.str.extract(' ([A-Za-z]+)\.', expand=False)


# In[93]:


# Check for NULLs
print(df_train['Title'].isnull().sum())
print(df_test['Title'].isnull().sum())


# In[94]:


# To see how Title and Survival are correlated
title_xt = pd.crosstab(df_train['Title'], df_train['Survived'])
title_xt_pct = title_xt.div(title_xt.sum(1).astype(float), axis=0)

title_xt_pct.plot(kind='bar', 
                  stacked=True, 
                  title='Survival Rate by title')
plt.xlabel('Title')
plt.ylabel('Survival Rate')
plt.rcParams["figure.figsize"] = (15,2)


# In[95]:


# Mapping of each title to specific groups
data = [df_train, df_test]

for dataset in data:
    dataset['Title'] = dataset['Title'].replace('Mme', 'Mrs')
    dataset['Title'] = dataset['Title'].replace('Ms', 'Mrs')      
    dataset['Title'] = dataset['Title'].replace('Mrs', 'Mrs')
    dataset['Title'] = dataset['Title'].replace('Mlle', 'Miss')     
    dataset['Title'] = dataset['Title'].replace('Miss', 'Miss')
    dataset['Title'] = dataset['Title'].replace('Master', 'Master')
    dataset['Title'] = dataset['Title'].replace('Mr', 'Mr')
    dataset['Title'] = dataset['Title'].replace('Capt', 'Officer')
    dataset['Title'] = dataset['Title'].replace('Major', 'Officer')
    dataset['Title'] = dataset['Title'].replace('Dr', 'Officer')
    dataset['Title'] = dataset['Title'].replace('Col', 'Officer')
    dataset['Title'] = dataset['Title'].replace('Rev', 'Officer') 
    dataset['Title'] = dataset['Title'].replace('Jonkheer', 'Royalty')    
    dataset['Title'] = dataset['Title'].replace('Don', 'Royalty')
    dataset['Title'] = dataset['Title'].replace('Dona', 'Royalty')
    dataset['Title'] = dataset['Title'].replace('Countess', 'Royalty')
    dataset['Title'] = dataset['Title'].replace('Lady', 'Royalty')
    dataset['Title'] = dataset['Title'].replace('Sir', 'Royalty')  


# In[96]:


df_train['Title'].unique()


# In[97]:


df_test['Title'].unique()


# In[98]:


# Check the Title column again after the mapping
title_xt = pd.crosstab(df_train['Title'], df_train['Survived'])
title_xt_pct = title_xt.div(title_xt.sum(1).astype(float), axis=0)

title_xt_pct.plot(kind='bar', 
                  stacked=True, 
                  title='Survival Rate by title')
plt.xlabel('Title')
plt.ylabel('Survival Rate')
plt.rcParams["figure.figsize"] = (15,2)


# In[99]:


# Drop the column: Name
df_train = df_train.drop(['Name'], axis=1)
df_test = df_test.drop(['Name'], axis=1)


# In[100]:


################ One hot encoding and renaming  ################


# In[101]:


# Rename the column 'Survived' to 'Target'
df_train = df_train.rename(columns={'Survived': 'Target'})


# In[102]:


####### One hot code: Embarked #######


# In[103]:


embarked_one_hot = pd.get_dummies(df_train['Embarked'], prefix='Embarked')
embarked_one_hot_test = pd.get_dummies(df_test['Embarked'], prefix='Embarked')


# In[104]:


df_train = df_train.join(embarked_one_hot)
df_test = df_test.join(embarked_one_hot_test)


# In[105]:


# Drop the column Embarked
df_train = df_train.drop(['Embarked'], axis=1)
df_test = df_test.drop(['Embarked'], axis=1)


# In[106]:


####### One hot code: Title #######


# In[107]:


title_one_hot = pd.get_dummies(df_train['Title'], prefix='Title')
title_one_hot_test = pd.get_dummies(df_test['Title'], prefix='Title')


# In[108]:


df_train = df_train.join(title_one_hot)
df_test = df_test.join(title_one_hot_test)


# In[109]:


# Drop the column Title
df_train = df_train.drop(['Title'], axis=1)
df_test = df_test.drop(['Title'], axis=1)


# In[110]:


####### One hot code: Pclass #######


# In[111]:


pclass_one_hot = pd.get_dummies(df_train['Pclass'], prefix='Pclass')
pclass_one_hot_test = pd.get_dummies(df_test['Pclass'], prefix='Pclass')


# In[112]:


df_train = df_train.join(pclass_one_hot)
df_test = df_test.join(pclass_one_hot_test)


# In[113]:


# Drop the column: Pclass
df_train = df_train.drop(['Pclass'], axis=1)
df_test = df_test.drop(['Pclass'], axis=1)


# In[114]:


####### One hot code: Deck #######


# In[115]:


deck_one_hot = pd.get_dummies(df_train['Deck'], prefix='Deck')
deck_one_hot_test = pd.get_dummies(df_test['Deck'], prefix='Deck')


# In[116]:


df_train = df_train.join(deck_one_hot)
df_test = df_test.join(deck_one_hot_test)


# In[117]:


# Drop the column: Deck
df_train = df_train.drop(['Deck'], axis=1)
df_test = df_test.drop(['Deck'], axis=1)


# In[118]:


####### One hot code: Family #######


# In[119]:


family_one_hot = pd.get_dummies(df_train['Family'], prefix='Family')
family_one_hot_test = pd.get_dummies(df_test['Family'], prefix='Family')


# In[120]:


df_train = df_train.join(family_one_hot)
df_test = df_test.join(family_one_hot_test)


# In[121]:


# Drop the column: Family
df_train = df_train.drop(['Family'], axis=1)
df_test = df_test.drop(['Family'], axis=1)


# In[122]:


####### One hot code: AgeBinCode #######


# In[123]:


age_one_hot = pd.get_dummies(df_train['AgeBinCode'], prefix='AgeBinCode')
age_one_hot_test = pd.get_dummies(df_test['AgeBinCode'], prefix='AgeBinCode')


# In[124]:


df_train = df_train.join(age_one_hot)
df_test = df_test.join(age_one_hot_test)


# In[125]:


# Drop the column: AgeBinCode
df_train = df_train.drop(['AgeBinCode'], axis=1)
df_test = df_test.drop(['AgeBinCode'], axis=1)


# In[ ]:


####### One hot code: FareBinCode #######


# In[126]:


fare_one_hot = pd.get_dummies(df_train['FareBinCode'], prefix='FareBinCode')
fare_one_hot_test = pd.get_dummies(df_test['FareBinCode'], prefix='FareBinCode')


# In[127]:


df_train = df_train.join(fare_one_hot)
df_test = df_test.join(fare_one_hot_test)


# In[128]:


# Drop the column: FareBinCode
df_train = df_train.drop(['FareBinCode'], axis=1)
df_test = df_test.drop(['FareBinCode'], axis=1)


# In[129]:


#### Check all columns


# In[130]:


df_train.head()


# In[131]:


df_test.head()


# In[107]:


#list(df_train.columns.values)


# In[108]:


#list(df_test.columns.values)


# In[132]:


##################### X & y creation #####################

y = df_train['Target']
X = df_train.drop('Target', axis=1)

##################### Train and test data creation #####################

X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.3, random_state=42)


# In[133]:


################################## Model building ############################################


# In[134]:


### Cross validate various models ###

num_folds = 5
seed = 2
scoring = 'accuracy'
models = []
scores = []
names = []

models.append(('LR', LogisticRegression()))
models.append(('SVC', SVC()))
models.append(('KNN', KNeighborsClassifier()))
models.append(('GBC', GradientBoostingClassifier()))
models.append(('DT', DecisionTreeClassifier()))
models.append(('RF', RandomForestClassifier()))

for name, model in models:
    kfold = StratifiedKFold(n_splits=num_folds, random_state=seed)
    cv_results = cross_val_score(model, X_train, y_train, cv=kfold, scoring=scoring)
    scores.append(cv_results)
    names.append(name)
    msg = "%s %f %f " % (name, cv_results.mean(), cv_results.std())
    print(msg)
    
# LR, GBC, DT and RF selected    


# In[182]:


##################### Logistic Regression with GridSearch ############################


# In[135]:


c_space = np.logspace(-5, 8, 15)
param_grid = {'C': c_space}

LR = LogisticRegression()

# Instantiate the GridSearchCV object: logreg_cv
lr_gs = GridSearchCV(LR, param_grid=param_grid, cv=5)

# Fit model to the data
lr_gs.fit(X_train, y_train)

parameters = lr_gs.best_params_

# Print the tuned parameters and score
print("Tuned Logistic Regression Parameters: {}".format(lr_gs.best_params_)) 
print("Best score is {}".format(lr_gs.best_score_))


# In[136]:


y_pred_lr = lr_gs.predict(X_test)
accuracy_lr = accuracy_score(y_test, y_pred_lr)
print(accuracy_lr)


# In[137]:


##################### Random Forest with Grid Search ############################


# In[138]:


RF = RandomForestClassifier()
param_grid = {
                 'max_depth' : [4, 6, 8],
                 'n_estimators': [50, 100],
                 'min_samples_split': [2, 3, 10],
                 'min_samples_leaf': [1, 3, 10],
                 'criterion': ['gini', 'entropy']
                 }
rf_gs = GridSearchCV(RF,
                           scoring='accuracy',
                           param_grid=param_grid,
                           cv=5,
                           verbose=1
                           )


# In[139]:


rf_gs.fit(X_train, y_train)


# In[140]:


parameters = rf_gs.best_params_

print('Best score: {}'.format(rf_gs.best_score_))
print('Best parameters: {}'.format(rf_gs.best_params_))


# In[141]:


y_pred_rf = rf_gs.predict(X_test)
accuracy_rf = accuracy_score(y_test, y_pred_rf)
print(accuracy_rf)


# In[142]:


######## Trying Gradient Boost ######


# In[143]:


GBC = GradientBoostingClassifier(n_estimators=100)
gb_param_grid = {'loss' : ["deviance"],
              'n_estimators' : [100,200,300],
              'learning_rate': [0.1, 0.05, 0.01],
              'max_depth': [4, 8],
              'min_samples_leaf': [100,150],
              'max_features': [0.3, 0.1] 
              }


# In[144]:


gbc_gs = GridSearchCV(GBC, param_grid = gb_param_grid, cv=kfold, scoring='accuracy', n_jobs= 4, verbose = 1)


# In[145]:


gbc_gs.fit(X_train, y_train)


# In[146]:


y_pred_gbc = gbc_gs.predict(X_test)
accuracy_gbc = accuracy_score(y_test, y_pred_gbc)
print(accuracy_gbc)


# In[147]:


############## Model evaluation ##############


# In[148]:


confusion_matrix(y_test, y_pred_lr)


# In[149]:


confusion_matrix(y_test, y_pred_rf)


# In[150]:


confusion_matrix(y_test, y_pred_gbc)


# In[ ]:


# Scores of LR


# In[159]:


print("Precision:", precision_score(y_test, y_pred_lr))
print("Recall:",recall_score(y_test, y_pred_lr))
print("F1 Score:", f1_score(y_test, y_pred_lr))


# In[151]:


# Scores of GBC


# In[158]:


print("Precision:", precision_score(y_test, y_pred_gbc))
print("Recall:",recall_score(y_test, y_pred_gbc))
print("F1 Score:", f1_score(y_test, y_pred_gbc))


# In[ ]:


# Scores of RF


# In[160]:


print("Precision:", precision_score(y_test, y_pred_rf))
print("Recall:",recall_score(y_test, y_pred_rf))
print("F1 Score:", f1_score(y_test, y_pred_rf))


# In[154]:


##################### Final Prediction #####################


# In[164]:


y_pred_final = gbc_gs.predict(df_test)


# In[165]:


final_submission = pd.DataFrame({
        "PassengerId": df_test_passengers,
        "Survived": y_pred_final
    })


# In[166]:


# Output file with 'key' and scores
filename = 'C:/Users/hianj/Desktop/DataCamp Learnings/Titanic Dataset/results/titanic_gbc_again2.csv'
final_submission.to_csv(filename, sep=',', index = False)

