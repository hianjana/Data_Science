# Import required libraries

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.pipeline import Pipeline
from sklearn.model_selection import GridSearchCV
from sklearn.model_selection import cross_val_score
from sklearn.metrics import accuracy_score
from sklearn.metrics import confusion_matrix, classification_report
from sklearn.metrics import roc_curve, auc, roc_auc_score

from sklearn.model_selection import KFold
from sklearn.linear_model import LogisticRegression
from sklearn.tree import DecisionTreeClassifier
from sklearn.discriminant_analysis import LinearDiscriminantAnalysis
from sklearn.naive_bayes import GaussianNB
from sklearn.ensemble import AdaBoostClassifier
from sklearn.ensemble import GradientBoostingClassifier
from sklearn.ensemble import RandomForestClassifier
from sklearn.ensemble import ExtraTreesClassifier


############# Read input file and header #############

df_header = pd.read_csv('header.csv', header=None)

df_colnames = df_header.iloc[[0]]
lst_colnames = df_colnames.values.tolist()
colnames = lst_colnames[0]

df = pd.read_csv('train.csv', header=None, names=colnames)

#################### Exploratory Data Analysis ####################

df.head()

df.info()
# No missing values and no NULL values

# Rename the column 'label' to 'target'
df = df.rename(columns={'label': 'target'})

# Drop the column 'key' as it is an ID column
df_final = df.drop(['key'], axis=1)
df_final.head()

# Checking for outliers
# sns.boxplot(df_final['V1'])
# sns.boxplot(df_final['V2'])
# sns.boxplot(df_final['V3'])
# sns.boxplot(df_final['V4'])
# sns.boxplot(df_final['V5'])
# sns.boxplot(df_final['V6'])
# sns.boxplot(df_final['V7'])
# sns.boxplot(df_final['V8'])
# sns.boxplot(df_final['V9'])
# sns.boxplot(df_final['V10'])

##################### X & y creation #####################

y = df_final['target']
X = df_final.drop('target', axis=1)

##################### Train and test data creation #####################

X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.3, random_state=42)

############# Scaling and Pipelining #######################

scaler = StandardScaler()

scaler.fit(X_train)
X_train_scaled = scaler.transform(X_train)
X_test_scaled = scaler.transform(X_test)

############################# Comparing non-ensemble models #############################

num_folds = 5
seed = 7
scoring = 'roc_auc'

roc_auc_scores_non_ens = []
non_ens_names = []

scoring = 'roc_auc'
non_ens_models = []
non_ens_models.append(('LR', LogisticRegression()))
non_ens_models.append(('LDA', LinearDiscriminantAnalysis()))
non_ens_models.append(('NB', GaussianNB()))
non_ens_models.append(('DT', DecisionTreeClassifier()))

for name, model in non_ens_models:
    kfold = KFold(n_splits=num_folds, random_state=seed)
    cv_results = cross_val_score(model, X_train_scaled, y_train, cv=kfold, scoring=scoring)
    roc_auc_scores_non_ens.append(cv_results)
    non_ens_names.append(name)
    msg = "%s %f %f " % (name, cv_results.mean(), cv_results.std())
    print(msg)

# DecisionTreeClassifier is selected

############################# Comparing ensemble models #############################

num_folds = 5
seed = 7
scoring = 'roc_auc'

roc_auc_scores_ens = []
ens_names = []

ensemble_models = []
ensemble_models.append(('AB', AdaBoostClassifier()))
ensemble_models.append(('GBM', GradientBoostingClassifier()))
ensemble_models.append(('RF', RandomForestClassifier()))
ensemble_models.append(('ET', ExtraTreesClassifier()))

for name, model in ensemble_models:
    kfold = KFold(n_splits=num_folds, random_state=seed)
    cv_results = cross_val_score(model, X_train_scaled, y_train, cv=kfold, scoring=scoring)
    roc_auc_scores_ens.append(cv_results)
    ens_names.append(name)
    msg = "%s: %f (%f)" % (name, cv_results.mean(), cv_results.std())
    print(msg)

# GradientBoostingClassifier, RandomForestClassifier, ExtraTreesClassifier selected


######## Run a basic GradientBoostingClassifier ########

GBC = GradientBoostingClassifier(random_state=10)

# Scaling
steps = [('scaler', scaler),
         ('GBC', GBC)]
#Pipelining
pipeline = Pipeline(steps)

GBC.fit(X_train, y_train)

y_pred = GBC.predict(X_test)
y_predict_prob = GBC.predict_proba(X_test)[:, 1]

cm = confusion_matrix(y_test, y_pred)
print(cm)

# Print accuracy of the model
print ('Score: {}'.format(accuracy_score(y_pred, y_test)))

# Generate ROC curve values: fpr, tpr, thresholds
fpr_gbc, tpr_gbc, thresholds_gbc = roc_curve(y_test, y_predict_prob)
auc_gbc = roc_auc_score(y_test, y_pred)
print("AUC: ", auc_gbc)

#Score: 0.7875964036619049
#AUC:  0.7886511356295131

# Plotting an ROC curve
plt.plot([0, 1], [0, 1], 'k--')
plt.plot(fpr_gbc, tpr_gbc)
plt.xlabel('False Positive Rate')
plt.ylabel('True Positive Rate')
plt.title('ROC Curve')
plt.show()


######## Run a basic DecisionTreeClassifier ########

DT = DecisionTreeClassifier(random_state=10)
# Scaling
steps = [('scaler', scaler),
         ('DT', DT)]
#Pipelining
pipeline = Pipeline(steps)
# Fitting the model
pipeline.fit(X_train, y_train)
# Predicting values for test
y_pred = pipeline.predict(X_test)
y_predict_prob = pipeline.predict_proba(X_test)[:, 1]


# Print the model
print(DT)
# Print accuracy of the model
print ('Score: {}'.format(accuracy_score(y_pred, y_test)))

# Generate ROC curve values: fpr, tpr, thresholds
fpr_dt, tpr_dt, thresholds = roc_curve(y_test, y_predict_prob)
auc_dt = roc_auc_score(y_test, y_pred)
print("AUC: ", auc_dt)

# Print Confusion Matrix
cm = confusion_matrix(y_test, y_pred)
print(cm)

# Plotting an ROC curve
plt.plot([0, 1], [0, 1], 'k--')
plt.plot(fpr_dt, tpr_dt)
plt.xlabel('False Positive Rate')
plt.ylabel('True Positive Rate')
plt.title('ROC Curve')
plt.show()

# Score: 0.9366460950882283
# AUC:  0.9365950859982631


######## Run a basic RandomForest ########

RF = RandomForestClassifier(random_state=10)
steps = [('scaler', scaler),
         ('RF', RF)]
pipeline = Pipeline(steps)
pipeline.fit(X_train, y_train)
y_pred = pipeline.predict(X_test)
y_predict_prob = pipeline.predict_proba(X_test)[:, 1]

# Print the model
print(RF)
# Print accuracy of the model
print ('Score: {}'.format(accuracy_score(y_pred, y_test)))

# Find fpr, tpr
fpr_rf, tpr_rf, thresholds = roc_curve(y_test, y_predict_prob)
auc_rf = auc(fpr_rf, tpr_rf)
print("AUC: ", auc_rf)

# Print Confusion Matrix
cm = confusion_matrix(y_test, y_pred)
print(cm)

# Plotting an ROC curve
plt.plot([0, 1], [0, 1], 'k--')
plt.plot(fpr_rf, tpr_rf)
plt.xlabel('False Positive Rate')
plt.ylabel('True Positive Rate')
plt.title('ROC Curve')
plt.show()

#Score: 0.9398752591936925
#AUC:  0.9837879227432622

######## Run a basic ExtraTreesClassifier ########

ET = ExtraTreesClassifier(random_state=42)

steps = [('scaler', scaler),
         ('ET', ET)]

pipeline = Pipeline(steps)

pipeline.fit(X_train, y_train)

y_pred = pipeline.predict(X_test)
y_predict_prob = pipeline.predict_proba(X_test)[:, 1]

# Print the model
print(ET)

# Print accuracy of the model
print ('Score: {}'.format(accuracy_score(y_pred, y_test)))

# Find fpr, tpr
fpr_et, tpr_et, thresholds = roc_curve(y_test, y_predict_prob)
auc_et = auc(false_positive_rate, true_positive_rate)
print("AUC: ", auc_et)

# Print Confusion Matrix
cm = confusion_matrix(y_test, y_pred)
print(cm)

# Plotting an ROC curve
plt.plot([0, 1], [0, 1], 'k--')
plt.plot(fpr_et, tpr_et)
plt.xlabel('False Positive Rate')
plt.ylabel('True Positive Rate')
plt.title('ROC Curve')
plt.show()

# Score: 0.9353675428028161
# AUC:  0.9837879227432622


### Plot all ROCs together for comparison

# Plotting an ROC curve
plt.plot([0, 1], [0, 1], 'k--')
plt.plot(fpr_dt, tpr_dt, c= 'r', label="Decision Tree, auc="+str(auc_dt))
plt.plot(fpr_rf, tpr_rf, c= 'b', label="Random Forest, auc="+str(auc_rf))
plt.plot(fpr_et, tpr_et, c= 'g', label="Extra Tree, auc="+str(auc_et))
plt.plot(fpr_gbc, tpr_gbc, c= 'y', label="Gradient Boosting, auc="+str(auc_gbc))
plt.xlabel('False Positive Rate')
plt.ylabel('True Positive Rate')
plt.title('ROC Curve')
plt.legend(loc=0)
plt.show()

# Decision Tree, Random Forest and Extra Tree are performing the best and we will fine tune them

############### Final Decision Tree with hyper parameter tuning ###############


DT = DecisionTreeClassifier(random_state=0)

parameters={'criterion': ['gini', 'entropy'],
            'max_depth': [10, 15, 20, 25, 30, 32, 33, 34, 35],
            'min_samples_split' : [2, 5, 10, 100, 200, 500]
           }

grid_search = GridSearchCV(DT, param_grid=parameters, cv=5, n_jobs = -1)

grid_search.fit(X_train_scaled, y_train)

grid_search_score = grid_search.score(X_test_scaled, y_test)

# Predict
y_pred = grid_search.predict(X_test_scaled)

# Print accuracy of the model
print ('Accuracy: {}'.format(accuracy_score(y_pred, y_test)))

# Compute predicted probabilities: y_pred_prob
y_pred_prob = grid_search.predict_proba(X_test_scaled)[:,1]

# Generate ROC curve values: fpr, tpr, thresholds
fpr_dt, tpr_dt, thresholds_dt = roc_curve(y_test, y_pred_prob)
auc_dt = roc_auc_score(y_test, y_pred)
print("AUC: ", auc_dt)

# Accuracy: 0.9403096391368133
# AUC:  0.940252984046818

print("Best parameters: {}".format(grid_search.best_params_))

# Compute and print the confusion matrix and classification report
cm = confusion_matrix(y_test, y_pred)
print(cm)
# Out of 122013 records, 114730 were predicted correctly (59107 + 55623) and 7283 were wrong (3622 + 3661)

print(classification_report(y_test, y_pred))

################################ Fine tuning Random Forest ################################

RF = RandomForestClassifier(n_estimators=500, max_features= 54, criterion='entropy', n_jobs=-1, random_state=42)
RF.fit(X_train_scaled, y_train)
y_pred = RF.predict(X_test_scaled)

# Print the model
print(RF)

# Print accuracy of the model
print ('Accuracy: {}'.format(accuracy_score(y_pred, y_test)))

# Compute predicted probabilities: y_pred_prob
y_pred_prob = RF.predict_proba(X_test_scaled)[:,1]

# Find fpr, tpr
fpr_rf, tpr_rf, thresholds = roc_curve(y_test, y_pred_prob)
auc_rf = auc(fpr_rf, tpr_rf)
print("AUC: ", auc_rf)

# Accuracy: 0.9729782891986919
# AUC:  0.9960806784563451

# Compute and print the confusion matrix and classification report
cm = confusion_matrix(y_test, y_pred)
print(cm)
# Out of 122013 records, 118716 were predicted correctly (60945 + 57771) and 3297 were wrong (1513 + 1784)

print(classification_report(y_test, y_pred))

########################## Fine tuning ExtraTreeClassifier ##########################

ET = ExtraTreesClassifier(n_estimators=500, max_features= 54, criterion='entropy', n_jobs=-1, random_state=42)
ET.fit(X_train_scaled, y_train)
y_pred = ET.predict(X_test_scaled)

# Print the model
print(ET)

# Print accuracy of the model
print ('Score: {}'.format(accuracy_score(y_pred, y_test)))

# Compute predicted probabilities: y_pred_prob
y_pred_prob = ET.predict_proba(X_test_scaled)[:,1]

# Find fpr, tpr
fpr_et, tpr_et, thresholds = roc_curve(y_test, y_pred_prob)
auc_et = auc(fpr_et, tpr_et)
print("AUC: ", auc_et)
# Score: 0.9729782891986919
# AUC:  0.9970485066002697

# Compute and print the confusion matrix and classification report
cm = confusion_matrix(y_test, y_pred)
print(cm)
# Out of 122013 records, 118716 were predicted correctly (60945 + 57771) and 3297 were wrong (1513 + 1784)

print(classification_report(y_test, y_pred))

################# Plot ROC curve of the selected models #################

plt.plot([0, 1], [0, 1], 'k--')
plt.plot(fpr_dt, tpr_dt, c= 'g', label="Decision Tree, auc="+str(auc_dt))
plt.plot(fpr_rf, tpr_rf, c= 'b', label="Random Forest, auc="+str(auc_rf))
plt.plot(fpr_et, tpr_et, c= 'r', label="Extra Tree, auc="+str(auc_et))
plt.xlabel('False Positive Rate')
plt.ylabel('True Positive Rate')
plt.title('ROC Curve')
plt.legend(loc=0)
plt.show()

################################## Scoring on test data ##################################

colnames_test = lst_colnames[0]
colnames_test.remove('label')

# Load the data for scoring
df_scoring = pd.read_csv('test.csv', header=None, names=colnames_test)

df_scoring.head()

# Check for NULL or missing values
df_scoring.info()

# Drop the column 'key' as it is an ID column
df_scoring_final = df_scoring.drop(['key'], axis=1)

# Scale the test data
df_scoring_scaled = scaler.transform(df_scoring_final)

# Predict using ExtraTreeClassifier
y_pred_final = ET.predict(df_scoring_scaled)

# Compute predicted probabilities: y_pred_prob
y_pred_prob_final = ET.predict_proba(df_scoring_scaled)[:,1]

# Convert the scores into a dataframe
scores = pd.DataFrame(y_pred_prob_final)


# Add 'key' to the scores
all_keys = df_scoring[['key']]
results = pd.concat([all_keys, scores], axis=1, join_axes=[all_keys.index])
# Rename the column 'label' to 'target'
results = results.rename(columns={ results.columns[1]: "score" })

# Sort the scores in descending order
results_sorted  = results.sort_values(by=['score'], ascending=False)

# Output file with 'key' and scores
filename = 'scores_ET_final.csv'
results_sorted.to_csv(filename, sep=',', index = False)


