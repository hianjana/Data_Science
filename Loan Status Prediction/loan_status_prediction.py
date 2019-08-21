#!/usr/bin/env python
# coding: utf-8

# In[70]:


import pandas as pd
import numpy as np
import seaborn as sns
import matplotlib.pyplot as plt


# In[288]:


from sklearn.linear_model import LogisticRegression
from sklearn.neighbors import KNeighborsClassifier
from sklearn.tree import DecisionTreeClassifier
from sklearn.ensemble import RandomForestClassifier
from sklearn.svm import SVC


# In[295]:


from sklearn.metrics import accuracy_score, confusion_matrix
from sklearn.metrics import precision_score, recall_score
from sklearn.metrics import f1_score


# In[1]:


############## Read input data ##############


# In[458]:


credit_risk_data = pd.read_csv('Credit_Risk_Train_data.csv')


# In[ ]:


############## EDA ##############


# In[460]:


credit_risk_data.shape
# 614 records and 13 columns


# In[462]:


credit_risk_data.head()


# In[463]:


credit_risk_data.describe()


# In[464]:


# Checking for nulls
credit_risk_data.isnull().sum()


# In[465]:


plt.hist(credit_risk_data['Loan_Status'])


# In[466]:


# To check the distribution of gender
plt.hist(credit_risk_data['Gender'])


# In[467]:


# To check the distribution of married
plt.hist(credit_risk_data['Married'])


# In[468]:


# To check the distribution of Dependents
plt.hist(credit_risk_data['Dependents'])


# In[470]:


var = credit_risk_data.groupby(['Education', 'Loan_Status']).Loan_Status.count()
var.unstack().plot(kind='bar',stacked=False,  color=['yellow','green'], grid=False)


# In[471]:


plt.hist(credit_risk_data['ApplicantIncome'])
# ApplicantIncome is right skewed


# In[472]:


# To check the distribution between Income and Loan Status
plt.scatter(credit_risk_data['ApplicantIncome'], credit_risk_data['Loan_Status'])


# In[473]:


var = credit_risk_data.groupby(['Credit_History', 'Loan_Status']).Loan_Status.count()
var.unstack().plot(kind='bar',stacked=False,  color=['yellow','green'], grid=False)


# In[474]:


plt.hist(credit_risk_data['Self_Employed'])


# In[475]:


var = credit_risk_data.groupby(['Loan_Amount_Term', 'Loan_Status']).Loan_Status.count()
var.unstack().plot(kind='bar',stacked=False,  color=['yellow','green'], grid=False)


# In[476]:


# Imputing missing values


# In[477]:


# Missing values are present in Gender, Married, Dependents, Self_Employed, Loan_Amount, Loan_Amount_Term, Credit_History


# In[478]:


# Gender
gender_mode = credit_risk_data['Gender'].mode()[0]
credit_risk_data['Gender'].fillna(gender_mode,inplace=True)


# In[479]:


# Married
married_mode = credit_risk_data['Married'].mode()[0]
credit_risk_data['Married'].fillna(married_mode,inplace=True)


# In[480]:


# Dependents
dependents_mode = credit_risk_data['Dependents'].mode()[0]
credit_risk_data['Dependents'].fillna(dependents_mode,inplace=True)


# In[481]:


# Self_Employed
self_employed_mode = credit_risk_data['Self_Employed'].mode()[0]
credit_risk_data['Self_Employed'].fillna(self_employed_mode,inplace=True)


# In[482]:


# Credit_History
credit_history_mode = credit_risk_data['Credit_History'].mode()[0]
credit_risk_data['Credit_History'].fillna(credit_history_mode,inplace=True)


# In[483]:


# LoanAmount
credit_risk_data['LoanAmount'].fillna(credit_risk_data['LoanAmount'].median(),inplace=True)


# In[484]:


# Loan_Amount_Term
credit_risk_data['Loan_Amount_Term'].fillna(credit_risk_data['Loan_Amount_Term'].median(),inplace=True)


# In[485]:


# Handling outliers


# In[486]:


plt.boxplot(credit_risk_data['ApplicantIncome'])


# In[487]:


columns = ['ApplicantIncome', 'CoapplicantIncome', 'LoanAmount', 'Loan_Amount_Term']
upper = []
lower = []
values = []

for col in columns:
    q1, q3 = np.percentile(credit_risk_data[col],[25,75])    
    IQR = q3 - q1
    lower_bound = q1 - (1.5 * IQR)
    upper_bound = q3 + (1.5 * IQR)
    col_median = credit_risk_data[col].median()
    credit_risk_data[col] = np.where(credit_risk_data[col] > upper_bound, col_median, credit_risk_data[col])
    credit_risk_data[col] = np.where(credit_risk_data[col] < lower_bound, col_median, credit_risk_data[col])
    upper.append(upper_bound)
    lower.append(lower_bound)
    values.append(col_median)    


# In[489]:


outlier_treatment = pd.DataFrame({'col': columns, 'upper_bound': upper, 'lower_bound': lower ,'replace_with': values})
outlier_treatment


# In[494]:


categorical_columns = ['Gender', 'Education', 'Married', 'Dependents', 'Self_Employed', 'Property_Area']
train_dummies = pd.get_dummies(credit_risk_data[categorical_columns])


# In[495]:


all_columns = credit_risk_data.columns
other_columns = [each for each in all_columns if each not in categorical_columns]


# In[496]:


other_columns.remove('Loan_Status')


# In[497]:


train_numerical = credit_risk_data[other_columns]


# In[498]:


train_numerical['Credit_History'] = train_numerical['Credit_History'].astype(int)


# In[499]:


train = pd.concat([train_dummies, train_numerical], axis=1)


# In[500]:


train = train.drop(['Loan_ID'], axis=1)


# In[501]:


train.shape


# In[502]:


train.head()


# In[503]:


credit_risk_data.loc[credit_risk_data['Loan_Status'] == 'Y', 'Loan_Status'] = 1
credit_risk_data.loc[credit_risk_data['Loan_Status'] == 'N', 'Loan_Status'] = 0


# In[504]:


X = train
y = credit_risk_data['Loan_Status']


# In[505]:


# Train - Test split


# In[506]:


from sklearn.model_selection import train_test_split


# In[507]:


X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.3, random_state=0)


# In[508]:


# Scaling


# In[509]:


from sklearn.preprocessing import StandardScaler

sc_X = StandardScaler()
X_train_scaled = sc_X.fit_transform(X_train)


# In[510]:


X_test_scaled = sc_X.transform(X_test)


# In[511]:


########## Model building


# In[512]:


models = []
accuracy = []
precision = []
recall = []


# In[513]:


# Logistic Regression


# In[514]:


LR = LogisticRegression()
LR.fit(X_train_scaled, y_train)

y_pred_lr = LR.predict(X_test_scaled)


# In[515]:


accuracy_lr = accuracy_score(y_test, y_pred_lr)
print(accuracy_lr)


# In[516]:


models.append('LogisticRegression')
accuracy.append(accuracy_lr)


# In[517]:


precision_lr = precision_score(y_test, y_pred_lr)
recall_lr = recall_score(y_test, y_pred_lr)

precision.append(precision_lr)
recall.append(recall_lr)

print("Precision:", precision_lr)
print("Recall:", recall_lr)


# In[518]:


# KNeighborsClassifier


# In[519]:


KNC = KNeighborsClassifier()
KNC.fit(X_train_scaled, y_train)

y_pred_knc = KNC.predict(X_test_scaled)


# In[520]:


accuracy_knc = accuracy_score(y_test, y_pred_knc)
print(accuracy_knc)


# In[521]:


models.append('KNeighborsClassifier')
accuracy.append(accuracy_knc)


# In[522]:


precision_kn = precision_score(y_test, y_pred_knc)
recall_kn = recall_score(y_test, y_pred_knc)

precision.append(precision_kn)
recall.append(recall_kn)

print("Precision:", precision_kn)
print("Recall:", recall_kn)


# In[523]:


# Decision Tree


# In[524]:


DT = DecisionTreeClassifier()
DT.fit(X_train_scaled, y_train)

y_pred_dt = DT.predict(X_test_scaled)


# In[525]:


accuracy_dt = accuracy_score(y_test, y_pred_dt)
print(accuracy_dt)


# In[526]:


models.append('DecisionTreeClassifier')
accuracy.append(accuracy_dt)


# In[527]:


precision_dt = precision_score(y_test, y_pred_dt)
recall_dt = recall_score(y_test, y_pred_dt)

precision.append(precision_dt)
recall.append(recall_dt)

print("Precision:", precision_dt)
print("Recall:", recall_dt)


# In[528]:


# Random Forest


# In[529]:


RF = RandomForestClassifier(n_estimators=100)
RF.fit(X_train_scaled, y_train)

y_pred_rf = RF.predict(X_test_scaled)


# In[530]:


accuracy_rf = accuracy_score(y_test, y_pred_dt)
print(accuracy_rf)


# In[531]:


models.append('RandomForestClassifier')
accuracy.append(accuracy_rf)


# In[532]:


precision_rf = precision_score(y_test, y_pred_rf)
recall_rf = recall_score(y_test, y_pred_rf)

precision.append(precision_rf)
recall.append(recall_rf)

print("Precision:", precision_rf)
print("Recall:", recall_rf)


# In[533]:


# SVC


# In[534]:


svc= SVC()
svc.fit(X_train_scaled, y_train)

y_pred_svc = svc.predict(X_test_scaled)


# In[535]:


accuracy_svc = accuracy_score(y_test, y_pred_svc)
print(accuracy_svc)


# In[536]:


models.append('SVC')
accuracy.append(accuracy_svc)


# In[537]:


precision_svc = precision_score(y_test, y_pred_svc)
recall_svc = recall_score(y_test, y_pred_svc)

precision.append(precision_svc)
recall.append(recall_svc)

print("Precision:", precision_svc)
print("Recall:", recall_svc)


# In[538]:


scores = pd.DataFrame({'model': models, 'accuracy': accuracy, 'precision': precision, 'recall': recall})
scores.sort_values(by=['accuracy'])


# In[540]:


##### Process test data


# In[565]:


validation_data = pd.read_csv('Credit_Risk_Validate_data.csv')


# In[566]:


validation_data.isnull().sum()


# In[570]:


validation_data.loc[validation_data['outcome'] == 'Y', 'outcome'] = 1
validation_data.loc[validation_data['outcome'] == 'N', 'outcome'] = 0


# In[573]:


validation_y = validation_data['outcome']


# In[574]:


# Impute missing values
validation_data['Gender'].fillna(gender_mode,inplace=True)
validation_data['Dependents'].fillna(dependents_mode,inplace=True)
validation_data['Self_Employed'].fillna(self_employed_mode,inplace=True)
validation_data['Credit_History'].fillna(credit_history_mode,inplace=True)
validation_data['LoanAmount'].fillna(credit_risk_data['LoanAmount'].median(),inplace=True)
validation_data['Loan_Amount_Term'].fillna(credit_risk_data['Loan_Amount_Term'].median(),inplace=True)


# In[575]:


outlier_treatment


# In[576]:


# Outlier treatment
columns = ['ApplicantIncome', 'CoapplicantIncome', 'LoanAmount', 'Loan_Amount_Term']

for col in columns:
    upper_bound = outlier_treatment[outlier_treatment['col'] == col]['upper_bound'].values[0]
    lower_bound = outlier_treatment[outlier_treatment['col'] == col]['lower_bound'].values[0]
    replace_with = outlier_treatment[outlier_treatment['col'] == col]['replace_with'].values[0]
    validation_data[col] = np.where(validation_data[col] > upper_bound, col_median, validation_data[col])
    validation_data[col] = np.where(validation_data[col] < lower_bound, col_median, validation_data[col])


# In[577]:


categorical_columns = ['Gender', 'Education', 'Married', 'Dependents', 'Self_Employed', 'Property_Area']
validation_dummies = pd.get_dummies(validation_data[categorical_columns])

validation_numerical = validation_data[other_columns]
validation_numerical['Credit_History'] = validation_numerical['Credit_History'].astype(int)

validation = pd.concat([validation_dummies, validation_numerical], axis=1)

validation = validation.drop(['Loan_ID'], axis=1)


# In[582]:


validation.shape


# In[585]:


# Standard scaling
val_scaled = sc_X.transform(validation)


# In[586]:


y_pred_final = svc.predict(val_scaled)


# In[589]:


accuracy_score(validation_y, y_pred_final)


# In[590]:


# Confusion Matrix for SVC
confusion_matrix(validation_y, y_pred_final)


# In[591]:


#TP = 57 - Actual Loan_Status = 1 and predicted as 1
#FP = 20 - Actual Loan_Status = 0 and predicted as 1
#FN = 1 - Actual Loan_Status = 1 and predicted as 0
#TN = 289 - Actual Loan_Status = 0 and predicted as 0

