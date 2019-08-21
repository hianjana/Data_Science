
# coding: utf-8

# In[99]:


import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
sns.set()


# In[100]:


df_white = pd.read_csv('C:/Users/hianj/Desktop/DataCamp Learnings/WineQuality/winequality-white.csv', delimiter=';')
df_red = pd.read_csv('C:/Users/hianj/Desktop/DataCamp Learnings/WineQuality/winequality-red.csv',delimiter=';')


# In[101]:


# df_white.head()


# In[102]:


# df_red.head()


# In[103]:


# Add a flag to indicate 'white wine'
df_white['color'] = 'white'
# Add a flag to indicate 'red wine'
df_red['color'] = 'red'


# In[104]:


# Merge the 2 datasets into one: df
df = pd.concat([df_white, df_red], axis=0)


# In[105]:


# Rename columns to have _ instead of space
df.columns = df.columns.str.strip().str.lower().str.replace(' ', '_').str.replace('(', '').str.replace(')', '')


# In[106]:


# Check the columns of the dataframe to see if there are any missing values/ NULL values
df.info()
# Below data confirms that there are no missing values
# No NULL values either


# In[107]:


# Create dummy variables for the column: color_white, color_red. Keep only one of the dummy columns
df_final = pd.get_dummies(df, drop_first=True)
#df_final = pd.get_dummies(df)


# In[108]:


# To plot the ECDF of 'quality'
x = np.sort(df_final['quality'])
### y-axis has evenly spaced data points with a maximum of 1
n = len(x)
y = np.arange(1, n + 1)/ n


# In[109]:


_ = plt.plot(x, y, marker = '.', linestyle ='none')
_ = plt.xlabel('wine quality')
_ = plt.ylabel('ECDF')
## To ensure none of the data points run over the sides
plt.margins(0.02)
plt.show()


# In[110]:


# To create boxplot of the column 'quality'
sns.boxplot(df_final['quality'])


# In[111]:


mean_quality = np.mean(df_final.quality)
df_final['target'] = np.where(df_final['quality'] > mean_quality, 1, 0)


# In[112]:


# Drop the original column 'quality' as we have the binary equivalent for it 'target'
df_final = df_final.drop(['quality'], axis=1)


# In[113]:


# Oultlier detction
# Since we are not clear what an outlier valu for features like ph, citric_acid etc represent, we are not removing them here
# Hence no outlier detection/ treatment done

##from scipy import stats
##zscores = np.abs(stats.zscore(df_final['fixed_acidity']))
#columns = ['fixed_acidity', 'volatile_acidity', 'citric_acid', 'residual_sugar', 'chlorides', 'free_sulfur_dioxide', 'total_sulfur_dioxide', 'density', 'ph', 'sulphates', 'alcohol', 'color_white']

#for each in columns:
#    std_value = np.std(df_final[each])
#    mean_value = np.mean(df_final[each])
#    df_final[each] = np.where(df_final[each] > 3 * std_value, mean_value, df_final[each])


# In[114]:


df_final.columns.tolist()


# In[115]:


# Feature selction


# In[116]:


# Draw a heatmap to see correlation between features
corr = df_final.corr()
cmap = sns.diverging_palette(220, 10, as_cmap=True)
sns.heatmap(corr, xticklabels=corr.columns, yticklabels=corr.columns, cmap=cmap)


# In[117]:


# Since the correlation between target and color_white is almsot 0, we will drop it from the features
df_final = df_final.drop(['color_white'], axis=1)


# In[118]:


# We are not performing feature selection using Pearson's Correlation Coefficient.
# Hence all other features are being used in the model


# In[119]:


#help(pearsonr)

# Feature selection using Pearson's Correlation Coefficient
#from scipy.stats.stats import pearsonr

#pearsonr(df_final['fixed_acidity'], df_final['target'])
# The correlation is very close to 0 and it is also statistically significant. We can drop this feature from the model


# In[120]:


#pearsonr(df_final['volatile_acidity'], df_final['target'])
# The correlation not very close to 0 and it is also statistically significant. We can keep this feature from the model


# In[24]:


#pearsonr(df_final['citric_acid'], df_final['target'])
# The correlation is very close to 0 and it is also statistically significant. We can drop this feature from the model


# In[25]:


#pearsonr(df_final['residual_sugar'], df_final['target'])
# The correlation is very close to 0 and it is also statistically significant. We can drop this feature from the model


# In[26]:


#pearsonr(df_final['chlorides'], df_final['target'])
# The correlation is not very close to 0 and it is also statistically significant. We can keep this feature from the model


# In[27]:


#pearsonr(df_final['free_sulfur_dioxide'], df_final['target'])
# The correlation is very close to 0 and it is also statistically significant. We can drop this feature from the model


# In[28]:


#pearsonr(df_final['total_sulfur_dioxide'], df_final['target'])
# The correlation is very close to 0 and it is also statistically significant. We can drop this feature from the model


# In[29]:


#pearsonr(df_final['density'], df_final['target'])
# The correlation is not very close to 0 and it is also statistically significant. We can keep this feature from the model


# In[30]:


#pearsonr(df_final['ph'], df_final['target'])
# The correlation is very close to 0 but it is not statistically significant. We can keep this feature from the model


# In[31]:


#pearsonr(df_final['sulphates'], df_final['target'])
# The correlation is very close to 0 and it is also statistically significant. We can drop this feature from the model


# In[32]:


#pearsonr(df_final['alcohol'], df_final['target'])
# The correlation is not very close to 0 and it is also statistically significant. We can keep this feature from the model


# In[33]:


#pearsonr(df_final['color_red'], df_final['target'])
# The correlation is very close to 0 and it is also statistically significant. We can drop this feature from the model


# In[34]:


#pearsonr(df_final['color_white'], df_final['target'])
# The correlation is very close to 0 and it is also statistically significant. We can drop this feature from the model


# In[ ]:


### Creating X and y data for the model


# In[121]:


y = df_final['target']


# In[122]:


X = df_final.drop('target', axis=1)


# In[123]:


##################### Train and test data creation #####################


# In[124]:


# Dividing data into train and test
from sklearn.model_selection import train_test_split

X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.3, random_state=42)


# In[ ]:


# Scaling features, creating a Logistic Regression as classifier and pipelining the steps #################


# In[125]:


from sklearn.preprocessing import StandardScaler
from sklearn.linear_model import LogisticRegression
from sklearn.pipeline import Pipeline

logreg = LogisticRegression()
# Scaling the values and calling Logistic Regression classfier in steps
steps = [('scaler', StandardScaler()),
('logistic_regression', logreg)]


# In[126]:


pipeline = Pipeline(steps)


# In[127]:


################# Fitting the model and predicting for test data #################


# In[128]:


pipeline.fit(X_train, y_train)


# In[129]:


y_pred = pipeline.predict(X_test)


# In[130]:


set(y_pred)


# In[131]:


################# Check for model accuracy and get other model evaluation metrics #################


# In[132]:


# Print accuracy of the model
print ('Score: {}'.format(pipeline.score(X_test, y_test)))


# In[133]:


# Compute and print the confusion matrix and classification report
from sklearn.metrics import confusion_matrix, classification_report


# In[138]:


cm = confusion_matrix(y_test, y_pred)
print(cm)
# Out of 1950 records, 1451 were predicted correctly (413 + 1038) and 499 were wrong (203 + 296)


# In[147]:


# Plot confusion matrix
sns.heatmap(cm, annot=True, fmt = '.0f', linewidth=0.5, square= True, cmap = 'Blues_r')
plt.xlabel('Predicted label')
plt.ylabel('Actual label')
score = pipeline.score(X_test, y_test)
plot_title = ('Accuracy: {}'.format(score))
plt.title(plot_title, size=15)


# In[135]:


print(classification_report(y_test, y_pred))


# In[33]:


################# Plot ROC curve #################


# In[34]:


# Compute predicted probabilities: y_pred_prob
y_pred_prob = pipeline.predict_proba(X_test)[:,1]


# In[35]:


from sklearn.metrics import roc_curve

# Generate ROC curve values: fpr, tpr, thresholds
fpr, tpr, thresholds = roc_curve(y_test, y_pred_prob)


# In[36]:


# Plotting an ROC curve
plt.plot([0, 1], [0, 1], 'k--')
plt.plot(fpr, tpr)
plt.xlabel('False Positive Rate')
plt.ylabel('True Positive Rate')
plt.title('ROC Curve')
plt.show()


# In[ ]:


################# Estimate model performance using Stratified k-fold Cross Validation method (default) #################


# In[118]:


# from sklearn.model_selection import cross_val_score
from sklearn.model_selection import cross_validate
from sklearn.metrics import recall_score

# Specify what measure of model quality to report
scoring=['roc_auc', 'precision_macro', 'recall_macro']
cross_val = cross_validate(pipeline, X_train, y_train, cv=5, scoring=scoring, return_train_score=False)

#cross_val_scores = cross_val_score(pipeline, X_train, y_train, cv=5, scoring='roc_auc')


# In[119]:


# Print all the keys associated to cross_val
cross_val.keys()


# In[105]:


# Various scoring outcomes: roc_auc, precision_macro, recall_macro


# In[116]:


cross_val_scores_roc_auc = cross_val['test_roc_auc']
#print("Cross-validation scores using roc_auc: {}".format(cross_val_scores))
print("Area Under the ROC Curve from prediction scores: %0.2f (+/- %0.2f)" % (cross_val_scores_roc_auc.mean(), cross_val_scores_roc_auc.std() * 2))


# In[112]:


cross_val_scores_precision = cross_val['test_precision_macro']
#print("Cross-validation scores using precision_macro: {}".format(cross_val_scores_precision))
print("Precision Accuracy: %0.2f (+/- %0.2f)" % (cross_val_scores_precision.mean(), cross_val_scores_precision.std() * 2))


# In[113]:


cross_val_scores_recall = cross_val['test_recall_macro']
#print("Cross-validation scores using recall_macro: {}".format(cross_val_scores_recall))
print("Recall Accuracy: %0.2f (+/- %0.2f)" % (cross_val_scores_recall.mean(), cross_val_scores_recall.std() * 2))


# In[ ]:


################# Estimate model performance using k-fold Cross Validation method #################


# In[136]:


from sklearn.model_selection import KFold


# In[137]:


kfold = KFold(n_splits=5)


# In[138]:


cross_val_scores = cross_val_score(pipeline, X, y, cv=kfold)


# In[140]:


print("k-Fold Cross Validation Scores: {}".format(cross_val_scores))


# In[141]:


print("Mean of k-Fold Cross Validation Scores: {}".format(cross_val_scores.mean()))


# In[ ]:


################# Estimate model performance using k-fold Cross Validation method and shuffle #################


# In[142]:


kfold = KFold(n_splits=5, shuffle=True, random_state=0)


# In[143]:


cross_val_scores_shuffle = cross_val_score(pipeline, X, y, cv=kfold)


# In[144]:


print("k-Fold Cross Validation Scores with shuffle: {}".format(cross_val_scores_shuffle))


# In[145]:


print("Mean of k-Fold Cross Validation Scores With Shuffle: {}".format(cross_val_scores_shuffle.mean()))


# In[ ]:


################# Estimate model performance using Shuffle-split Cross Validation method #################


# In[146]:


from sklearn.model_selection import ShuffleSplit


# In[147]:


shuffle_split = ShuffleSplit(train_size = 0.5, test_size=0.5, n_splits=10)
shuffle_split_scores = cross_val_score(pipeline, X, y, cv=shuffle_split)


# In[148]:


print("Shuffle Split Cross Validation Scores: {}".format(shuffle_split_scores.mean()))


# In[ ]:


############################### Parameter tuning ##########################################


# In[ ]:


############## Naive Grid Search Implementation ##############


# In[ ]:


############## 3-fold split of data into - Train, Validation and Test ##############
# Train dataset =  Build the model
# Validation dataset = Select the parameters of the model
# Test dataset = To evaluate the performance of the selected parameters
# Implementation of SVC: Hyper parameters are gamma and C


# In[160]:


from sklearn.svm import SVC


# In[162]:


# Split dataset into train+validation and test datasets
X_trainval, X_test, y_trainval, y_test = train_test_split(X, y, random_state=0)


# In[163]:


# Split train+validation dataset into train and validation datasets
X_train, X_valid, y_train, y_valid = train_test_split(X_trainval, y_trainval, random_state=1)


# In[167]:


print(" Size of Train dataset: {}\n Size of Validation dataset: {}\n Size of Test dataset: {}\n".format(X_train.shape, X_valid.shape, X_test.shape))


# In[170]:


best_score = 0
for gamma in [0.001, 0.01, 0.1, 1, 10, 100]:
    for C in [0.001, 0.01, 0.1, 1, 10, 100]:
        #for each combination of parameters, train an SVC
        svm = SVC(gamma=gamma, C=C)
        svm.fit(X_train, y_train)
        #Evaluate the values of gamma and C on the Validation dataset
        score = svm.score(X_valid, y_valid)
        # Check if we got a better score. If yes, store it, else keep the old score
        if score > best_score:
                best_score = score
                best_parameters = {'C': C, 'gamma': gamma}


# In[173]:


# Rebuild a model using the best parameters on the combined training and validation dataset and evaluate it on test dataset
svm_new = SVC(**best_parameters)


# In[174]:


svm_new.fit(X_trainval, y_trainval)


# In[175]:


test_score = svm.score(X_test, y_test)


# In[176]:


print("Best score on validation dataset: {}". format(best_score))


# In[177]:


print("Best parameters: {}". format(best_score))


# In[178]:


print("Test score with best parameters: {}". format(test_score))


# In[ ]:


######################### Grid Search with Cross-Validation #########################


# In[179]:


best_score = 0
for gamma in [0.001, 0.01, 0.1, 1, 10, 100]:
    for C in [0.001, 0.01, 0.1, 1, 10, 100]:
        #for each combination of parameters, train an SVC
        svm = SVC(gamma=gamma, C=C)
        # Perform cross validation
        scores = cross_val_score(svm, X_trainval, y_trainval, cv=5)
        score = np.mean(scores)
        # Check if we got a better score. If yes, store it, else keep the old score
        if score > best_score:
                best_score = score
                best_parameters = {'C': C, 'gamma': gamma}


# In[180]:


# Rebuild a model using the best parameters on the combined training and validation dataset and evaluate it on test dataset
svm_grid_cv = SVC(**best_parameters)
svm_grid_cv.fit(X_trainval, y_trainval)


# In[181]:


test_score_cv = svm_grid_cv.score(X_test, y_test)


# In[182]:


print("Best score on validation dataset with cross validation: {}". format(best_score))


# In[183]:


print("Best parameters with crossvalidation: {}". format(best_parameters))


# In[184]:


print("Test score with best parameters and cross validation: {}". format(test_score_cv))


# In[ ]:


################# GridSearchCV Implementation #################


# In[228]:


param_grid = {'C': [0.001, 0.01, 0.1, 1, 10, 100],
'gamma': [0.001, 0.01, 0.1, 1, 10, 100]}

print("Parameter grid: \n{}".format(param_grid))


# In[37]:


from sklearn.model_selection import GridSearchCV
from sklearn.svm import SVC


# In[231]:


# Instantiating GridSearchCV class with the model: SVC, the parameter grid to search: param_grid
# and cross validation strategt: 5-fold stratified cross validation


# In[233]:


grid_search = GridSearchCV(SVC(), param_grid, cv=5)


# In[236]:


X_train, X_test, y_train, y_test = train_test_split(X, y, random_state=0)


# In[237]:


grid_search.fit(X_train, y_train)


# In[238]:


grid_search_score = grid_search.score(X_test, y_test)


# In[240]:


print("Test dataset score: {}".format(grid_search_score))


# In[241]:


print("Best parameters: {}".format(grid_search.best_params_))


# In[242]:


# Mean cross vaildation accuracy with cv performed on the training dataset
print("Best cross validation score: {}".format(grid_search.best_score_))


# In[243]:


# Model with the best parameters trained on the whole training dataset
print("Best estimator: {}".format(grid_search.best_estimator_))


# In[ ]:


# Results of grid search
results= pd.DataFrame(grid_search.cv_results_)
results.head()


# In[ ]:


scores=np.array(results.mean_test_score).reshape(6,6)


# In[ ]:


# Plot the mean cross-validation scores
# Ligh colors = High accuracy
# Dark colors = Low accuracy

import mglearn

mglearn.tools.heatmap(scores, xlabel='gamma', ylabel='C', xticklabels=param_grid['gamma'], yticklabels=param_grid['C'], cmap='viridis')

