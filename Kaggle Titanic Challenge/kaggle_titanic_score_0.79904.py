
# coding: utf-8

# In[1]:


# Import all required libraries for EDA, Data pre-processing
import pandas as pd
import numpy as np
import re
import matplotlib.pyplot as plt
from sklearn.model_selection import train_test_split
import seaborn as sns
from sklearn.preprocessing import Imputer


# In[2]:


# Import all libraries for algorithms
from sklearn.model_selection import KFold
from sklearn.neighbors import KNeighborsClassifier
from sklearn.linear_model import LogisticRegression, LogisticRegressionCV
from sklearn.tree import DecisionTreeClassifier
from sklearn.naive_bayes import GaussianNB
from sklearn.ensemble import RandomForestClassifier
from sklearn.svm import LinearSVC
from sklearn.ensemble.gradient_boosting import GradientBoostingClassifier


# In[3]:


# Import libraries for model evaluation
from sklearn.model_selection import GridSearchCV
from sklearn.model_selection import cross_val_score
from sklearn.metrics import accuracy_score
from sklearn.metrics import confusion_matrix


# In[65]:


# Load the train and test datasets
df = pd.read_csv('C:/Users/hianj/Desktop/DataCamp Learnings/Titanic Dataset/train.csv')
df_test = pd.read_csv('C:/Users/hianj/Desktop/DataCamp Learnings/Titanic Dataset/test.csv')


# In[66]:


#################################### EDA and Data-Preprocessing ####################################


# In[67]:


df.head()


# In[68]:


# Store PassengerId before dropping it
df_test_passengers = df_test['PassengerId']


# In[69]:


# Drop PassengerId from train and test datasets as it is just a continuous number
df = df.drop('PassengerId',axis=1)
df_test = df_test.drop('PassengerId',axis=1)


# In[70]:


df.info()


# In[71]:


#### Check for missing values in columns in train and test datasets


# In[72]:


def missings(dataset):
    null_columns=dataset.columns[dataset.isnull().any()]
    print(dataset[null_columns].isnull().sum())


# In[73]:


missings(df)


# In[74]:


missings(df_test)


# In[75]:


########## Fill missing values for: Age ##########


# In[76]:


imp = Imputer(missing_values='NaN', strategy='most_frequent', axis=0)
imp.fit(df[['Age']])
df['Age'] = imp.transform(df[['Age']])

df_test['Age'] = imp.transform(df_test[['Age']])


# In[77]:


# Convert Age to integer
data = [df, df_test]

for dataset in data:
    dataset['Age'] = dataset['Age'].astype(int)


# In[78]:


missings(df)


# In[79]:


missings(df_test)


# In[80]:


########## Fill missing values for: Embarked ##########


# In[81]:


# Check for most frequent value in train dataset
plt.hist(df['Embarked'])


# In[82]:


# Replace missing values in train dataset for the column 'Embarked' with the most frequent value of train: 'S'
# Fill NaN values in column 'Embarked' as 'S'
df['Embarked'].fillna('S',inplace=True)


# In[83]:


missings(df)


# In[84]:


########## Fill missing values for: Fare ##########


# In[85]:


# Replace missing values in test for 'Fare' with 0
df_test['Fare'].fillna(0,inplace=True)


# In[86]:


missings(df_test)


# In[87]:


########## Fill missing values for: Cabin ##########


# In[88]:


# Replace missing values for Cabin with 'U' for 'Unknown'
df['Cabin'].fillna('U',inplace=True)
df_test['Cabin'].fillna('U',inplace=True)


# In[89]:


missings(df)


# In[90]:


missings(df_test)


# In[91]:


############################################# EDA  #############################################


# In[92]:


###### Analyse column: Sex ######


# In[93]:


sns.countplot(x="Sex", hue="Survived", data=df);


# In[94]:


# Map 'male' to 0 and 'female' to 1 in both train and test
# Convert the datatype to int
data = [df, df_test]

for dataset in data:
    dataset['Sex'] = dataset['Sex'].map({'male':0, 'female':1})
    dataset['Sex'] = dataset['Sex'].astype(int)


# In[95]:


df.head()


# In[96]:


##### Analyse column: Pclass #####


# In[97]:


sns.countplot(x="Pclass", hue="Survived", data=df);


# In[98]:


##### Analyse column: Embarked #####


# In[99]:


sns.countplot(x='Embarked', hue='Survived', data=df)


# In[100]:


##### Analyse columns: SibSp & Parch #####


# In[101]:


sns.countplot(x='SibSp', hue='Survived', data=df)


# In[102]:


sns.countplot(x='Parch', hue='Survived', data=df)


# In[103]:


# Create new column 'FamilySize' which is SibSp + Parch + 1 (1 is added to represent oneself)


# In[104]:


dataset = [df, df_test]
for data in dataset:
    data['FamilySize'] = ''
    data['FamilySize'] = data['SibSp'] + data['Parch'] + 1


# In[105]:


sns.countplot(x='FamilySize', hue='Survived', data=df)


# In[106]:


dataset = [df, df_test]
for data in dataset:
    data['Family'] = ''
    data.loc[data['FamilySize'] == 1, 'Family'] = 1
    data.loc[(data['FamilySize'] > 1) & (data['FamilySize'] <= 4), 'Family'] = 2
    data.loc[data['FamilySize'] > 4, 'Family' ] = 3 


# In[107]:


df = df.drop(['SibSp', 'Parch'], axis=1)
df_test = df_test.drop(['SibSp', 'Parch'], axis=1)


# In[108]:


##### Analyse column: Cabin #####


# In[109]:


df['Cabin'].unique()


# In[110]:


# Extract Deck from the column Cabin as 'Deck' and drop Cabin
df['Deck'] = df['Cabin'].str.slice(0,1)
df_test['Deck'] = df_test['Cabin'].str.slice(0,1)


# In[111]:


sns.countplot(x='Deck', hue='Survived', data=df)


# In[112]:


# Count number of people per Deck in train
df.groupby(['Deck']).size()


# In[113]:


# Count number of people per Deck in test
df_test.groupby(['Deck']).size()


# In[114]:


# Replace 'T' with 'U' for Deck in train as there is only one person
df.loc[df['Deck'] == 'T', 'Deck'] = 'U'


# In[115]:


# Check again
df.groupby(['Deck']).size()


# In[116]:


# Drop the column Cabin
df = df.drop(['Cabin'], axis=1)
df_test = df_test.drop(['Cabin'], axis=1)


# In[117]:


##### Analyse column: Age #####


# In[118]:


# To see how Age and Survival are correlated
age_xt = pd.crosstab(df['Age'], df['Survived'])
age_xt_pct = age_xt.div(age_xt.sum(1).astype(float), axis=0)

age_xt_pct.plot(kind='bar', 
                  stacked=True, 
                  title='Age & Survival')
plt.xlabel('Age')
plt.ylabel('Survival Rate')
plt.rcParams["figure.figsize"] = (35, 5)


# In[119]:


dataset = [df, df_test]
for data in dataset:
    data['AgeGrp'] = ''
    data.loc[data['Age'] <=15, 'AgeGrp'] = 'A'
    data.loc[(data['Age'] > 15) & (data['Age'] <= 30), 'AgeGrp'] = 'B'
    data.loc[(data['Age'] > 30) & (data['Age'] <= 45), 'AgeGrp'] = 'C'
    data.loc[(data['Age'] > 45) & (data['Age'] <= 60), 'AgeGrp'] = 'D'
    data.loc[data['Age'] > 60, 'AgeGrp'] = 'E'    


# In[120]:


sns.countplot(x='AgeGrp', hue='Survived', data=df)


# In[121]:


# Drop the column: Age
df = df.drop('Age', axis=1)
df_test = df_test.drop('Age', axis=1)


# In[122]:


##### Analyse column: Fare #####


# In[123]:


# Convert 'Fare' to integer
df['Fare'] = df['Fare'].astype(int)
df_test['Fare'] = df_test['Fare'].astype(int)


# In[124]:


# Create new column 'FarePP' which is FarePerPerson by dividing Fare by FamilySize to get individual person's fare
dataset=[df, df_test]
for data in dataset:
    data['FarePP'] = ''
    data['FarePP'] = data['Fare']/ data['FamilySize']


# In[125]:


# Convert 'FarePP' to integer
df['FarePP'] = df['FarePP'].astype(int)
df_test['FarePP'] = df_test['FarePP'].astype(int)


# In[126]:


# Sort dataframe by 'FarePP' descending order to see it's relation with 'Ticket'
df.sort_values(by='FarePP', ascending=False)
# Those with the same fare have the same Ticket Number. Hence,the column 'Ticket' doesn't seem to give any significant information


# In[127]:


# To see how FarePP and Survival are correlated
farepp_xt = pd.crosstab(df['FarePP'], df['Survived'])
farepp_xt_pct = farepp_xt.div(farepp_xt.sum(1).astype(float), axis=0)

farepp_xt_pct.plot(kind='bar', 
                  stacked=True, 
                  title='FarePP & Survival')
plt.xlabel('FarePP')
plt.ylabel('Survival Rate')
plt.rcParams["figure.figsize"] = (28, 5)


# In[128]:


# Drop columns: Fare, FamilySize
df = df.drop(['Fare', 'FamilySize'], axis=1)
df_test = df_test.drop(['Fare', 'FamilySize'], axis=1)


# In[129]:


df.head()


# In[130]:


###### Analse column: Ticket


# In[131]:


df['Ticket'].unique()


# In[132]:


# Drop the column Ticket as it is not having any significant information
df = df.drop('Ticket', axis=1)
df_test = df_test.drop('Ticket', axis=1)


# In[133]:


##### Analyse the column: Name #####


# In[134]:


# Create a new column: Title
df['Title'] = ''
df_test['Title'] = ''


# In[135]:


# Extract titles into this column
df['Title'] = df.Name.str.extract(' ([A-Za-z]+)\.', expand=False)
df_test['Title'] = df_test.Name.str.extract(' ([A-Za-z]+)\.', expand=False)


# In[136]:


# Check for NULLs
print(df['Title'].isnull().sum())
print(df_test['Title'].isnull().sum())


# In[137]:


# To see how Title and Survival are correlated
title_xt = pd.crosstab(df['Title'], df['Survived'])
title_xt_pct = title_xt.div(title_xt.sum(1).astype(float), axis=0)

title_xt_pct.plot(kind='bar', 
                  stacked=True, 
                  title='Survival Rate by title')
plt.xlabel('Title')
plt.ylabel('Survival Rate')
plt.rcParams["figure.figsize"] = (15,2)


# In[138]:


# Mapping of each title to specific groups
data = [df, df_test]

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


# In[139]:


df['Title'].unique()


# In[140]:


df_test['Title'].unique()


# In[141]:


# Check the Title column again after the mapping
title_xt = pd.crosstab(df['Title'], df['Survived'])
title_xt_pct = title_xt.div(title_xt.sum(1).astype(float), axis=0)

title_xt_pct.plot(kind='bar', 
                  stacked=True, 
                  title='Survival Rate by title')
plt.xlabel('Title')
plt.ylabel('Survival Rate')
plt.rcParams["figure.figsize"] = (15,2)


# In[142]:


# Drop the column: Name
df = df.drop(['Name'], axis=1)
df_test = df_test.drop(['Name'], axis=1)


# In[143]:


df.head()


# In[144]:


############################################# Data Pre-Processing  #############################################


# In[145]:


# Rename the column 'Survived' to 'Target'
df = df.rename(columns={'Survived': 'Target'})


# In[146]:


df.head()


# In[147]:


####### One hot code: Embarked #######


# In[148]:


embarked_one_hot = pd.get_dummies(df['Embarked'], prefix='Embarked')
embarked_one_hot_test = pd.get_dummies(df_test['Embarked'], prefix='Embarked')


# In[149]:


df = df.join(embarked_one_hot)
df_test = df_test.join(embarked_one_hot_test)


# In[150]:


# Drop the column Embarked
df = df.drop(['Embarked'], axis=1)
df_test = df_test.drop(['Embarked'], axis=1)


# In[151]:


####### One hot code: Title #######


# In[152]:


title_one_hot = pd.get_dummies(df['Title'], prefix='Title')
title_one_hot_test = pd.get_dummies(df_test['Title'], prefix='Title')


# In[153]:


df = df.join(title_one_hot)
df_test = df_test.join(title_one_hot_test)


# In[154]:


# Drop the column Title
df = df.drop(['Title'], axis=1)
df_test = df_test.drop(['Title'], axis=1)


# In[155]:


####### One hot code: Pclass #######


# In[156]:


pclass_one_hot = pd.get_dummies(df['Pclass'], prefix='Pclass')
pclass_one_hot_test = pd.get_dummies(df_test['Pclass'], prefix='Pclass')


# In[157]:


df = df.join(pclass_one_hot)
df_test = df_test.join(pclass_one_hot_test)


# In[158]:


# Drop the column: Pclass
df = df.drop(['Pclass'], axis=1)
df_test = df_test.drop(['Pclass'], axis=1)


# In[159]:


####### One hot code: Deck #######


# In[160]:


deck_one_hot = pd.get_dummies(df['Deck'], prefix='Deck')
deck_one_hot_test = pd.get_dummies(df_test['Deck'], prefix='Deck')


# In[161]:


df = df.join(deck_one_hot)
df_test = df_test.join(deck_one_hot_test)


# In[162]:


# Drop the column: Deck
df = df.drop(['Deck'], axis=1)
df_test = df_test.drop(['Deck'], axis=1)


# In[163]:


####### One hot code: Family #######


# In[164]:


family_one_hot = pd.get_dummies(df['Family'], prefix='Family')
family_one_hot_test = pd.get_dummies(df_test['Family'], prefix='Family')


# In[165]:


df = df.join(family_one_hot)
df_test = df_test.join(family_one_hot_test)


# In[166]:


# Drop the column: Family
df = df.drop(['Family'], axis=1)
df_test = df_test.drop(['Family'], axis=1)


# In[167]:


df.head()


# In[168]:


####### One hot code: AgeGrp #######


# In[169]:


age_one_hot = pd.get_dummies(df['AgeGrp'], prefix='AgeGrp')
age_one_hot_test = pd.get_dummies(df_test['AgeGrp'], prefix='AgeGrp')


# In[170]:


df = df.join(age_one_hot)
df_test = df_test.join(age_one_hot_test)


# In[171]:


# Drop the column: AgeGrp
df = df.drop(['AgeGrp'], axis=1)
df_test = df_test.drop(['AgeGrp'], axis=1)


# In[172]:


#### Check all columns


# In[173]:


df.head()


# In[174]:


df_test.head()


# In[175]:


#list(df.columns.values)
#list(df_test.columns.values)


# In[176]:


##################### X & y creation #####################

y = df['Target']
X = df.drop('Target', axis=1)

##################### Train and test data creation #####################

X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.3, random_state=42)


# In[177]:


################################## Model building ############################################


# In[522]:


################################## Try various models ##################################


# In[181]:


num_folds = 5
seed = 7
scoring = 'accuracy'
models = []
scores = []
names = []

models.append(('LR', LogisticRegression()))
models.append(('NB', GaussianNB()))
models.append(('LVC', LinearSVC()))
models.append(('GBC', GradientBoostingClassifier()))
models.append(('DT', DecisionTreeClassifier()))
models.append(('RF', RandomForestClassifier()))

for name, model in models:
    kfold = KFold(n_splits=num_folds, random_state=seed)
    cv_results = cross_val_score(model, X_train, y_train, cv=kfold, scoring=scoring)
    scores.append(cv_results)
    names.append(name)
    msg = "%s %f %f " % (name, cv_results.mean(), cv_results.std())
    print(msg)
    
# LR, GBC and RF selected    


# In[182]:


##################### Logistic Regression with GridSearch ############################


# In[183]:


c_space = np.logspace(-5, 8, 15)
param_grid = {'C': c_space}

logreg = LogisticRegression()

# Instantiate the GridSearchCV object: logreg_cv
logreg_cv = GridSearchCV(logreg, param_grid=param_grid, cv=5)

# Fit model to the data
logreg_cv.fit(X_train, y_train)

lr_model = logreg_cv
parameters = logreg_cv.best_params_

# Print the tuned parameters and score
print("Tuned Logistic Regression Parameters: {}".format(logreg_cv.best_params_)) 
print("Best score is {}".format(logreg_cv.best_score_))


# In[184]:


y_pred_lr = lr_model.predict(X_test)
accuracy_lr = accuracy_score(y_test, y_pred_lr)
print(accuracy_lr)


# In[185]:


##################### Random Forest with Grid Search ############################


# In[186]:


rf_gs = RandomForestClassifier()
param_grid = {
                 'max_depth' : [4, 6, 8],
                 'n_estimators': [10, 50, 100],
                 'criterion': ['gini', 'entropy']
                 }
grid_search = GridSearchCV(rf_gs,
                           scoring='accuracy',
                           param_grid=param_grid,
                           cv=5,
                           verbose=1
                           )


# In[190]:


grid_search.fit(X_train, y_train)


# In[191]:


rf_model = grid_search
parameters = grid_search.best_params_

print('Best score: {}'.format(grid_search.best_score_))
print('Best parameters: {}'.format(grid_search.best_params_))


# In[192]:


y_pred_rf = rf_model.predict(X_test)
accuracy_rf = accuracy_score(y_test, y_pred_rf)
print(accuracy_rf)


# In[193]:


######## Trying Gradient Boost ######


# In[194]:


gbc = GradientBoostingClassifier(n_estimators=100)
gbc.fit(X_train, y_train)


# In[195]:


y_pred_gbc = gbc.predict(X_test)
accuracy_gbc = accuracy_score(y_test, y_pred_gbc)
print(accuracy_gbc)


# In[196]:


############## Model evaluation ##############


# In[197]:


confusion_matrix(y_test, y_pred_lr)


# In[198]:


confusion_matrix(y_test, y_pred_rf)


# In[199]:


confusion_matrix(y_test, y_pred_gbc)


# In[ ]:


# Random Forest with Grid Search selected


# In[200]:


from sklearn.metrics import precision_score, recall_score

print("Precision:", precision_score(y_test, y_pred_rf))
print("Recall:",recall_score(y_test, y_pred_rf))


# In[201]:


from sklearn.metrics import f1_score

f1_score(y_test, y_pred_rf)


# In[612]:


##################### Final Prediction #####################


# In[613]:


y_pred_final = rf_model.predict(df_test)


# In[614]:


final_submission = pd.DataFrame({
        "PassengerId": df_test_passengers,
        "Survived": y_pred_final
    })


# In[615]:


# Output file with 'key' and scores
filename = 'C:/Users/hianj/Desktop/DataCamp Learnings/Titanic Dataset/results/rf_submission_best.csv'
final_submission.to_csv(filename, sep=',', index = False)

