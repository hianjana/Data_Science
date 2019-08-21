#!/usr/bin/env python
# coding: utf-8

# # Predict the cost of a used car

# **Objective:**
#     
# Given the features of a used car, we need to predict what will be the cost of it.    
# 
# **Dataset description:**
#     
# * Name: The brand and model of the car.
# * Location: The location in which the car is being sold or is available for purchase.
# * Year: The year or edition of the model.
# * Kilometers_Driven: The total kilometres driven in the car by the previous owner(s) in KM.
# * Fuel_Type: The type of fuel used by the car.
# * Transmission: The type of transmission used by the car.
# * Owner_Type: Whether the ownership is Firsthand, Second hand or other.
# * Mileage: The standard mileage offered by the car company in kmpl or km/kg.
# * Engine: The displacement volume of the engine in CC (Cubic Centimeters).
# * Power: The maximum power of the engine in bhp (Break Horse Power).
# * Seats: The number of seats in the car.
# * New_Price: The price of a new car of the same model. 
# * Price: The price of the used car in INR Lakhs.    

# In[1894]:


# Install libraries for EDA
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import xlsxwriter

# Model biulding and selection
from sklearn.model_selection import train_test_split
from sklearn.linear_model import LinearRegression
from sklearn.tree import DecisionTreeRegressor

# Ensemble models
from sklearn.linear_model import ElasticNet, Lasso
from sklearn.ensemble import RandomForestRegressor
from sklearn.ensemble import GradientBoostingRegressor
from sklearn.kernel_ridge import KernelRidge

# Model evaluation
from sklearn.metrics import mean_squared_error


# In[1895]:


# To ignore Python warnings
import warnings
warnings.filterwarnings("ignore")


# In[1896]:


# Load the train dataset
train = pd.read_excel('Data_Train.xlsx')


# ## Exploratory Data Analysis

# In[1897]:


train.shape # View the dimensions of the train dataset


# ### Univariate Analysis

# In[1898]:


# Function to check if the dataset has any missing values
def missing_vals(dataset):
    null_columns=dataset.columns[dataset.isnull().any()]
    print(dataset[null_columns].isnull().sum())


# In[1899]:


# Check if train dataset has any nulls
missing_vals(train)


# New_Price, Seats, Power, Engine, Mileage have nulls

# ### Analyse New Price

# Since almost all values are null, we will drop this column

# In[1900]:


train.drop('New_Price', axis=1, inplace=True)


# ### Analyse Transmission

# In[1901]:


'''
#ax = plt.bar(pd_transmission['index'],pd_transmission['Count'], color='green') 
ax = train['Transmission'].value_counts().plot(kind='barh', color="green", fontsize=13);
ax.set_xlabel('Transmission')
ax.set_ylabel('Frequency')

# create a list to collect the plt.patches data
totals = []

# find the values and append to list
for i in ax.patches:
    totals.append(i.get_width())

# set individual bar lables using above list
total = sum(totals)

# set individual bar lables using above list
for i in ax.patches:
    # get_width pulls left or right; get_y pushes up or down
    ax.text(i.get_width()+.3, i.get_y()+.38, str(round((i.get_width()/total)*100, 2))+'%')

# invert for largest on top 
ax.invert_yaxis()

plt.show()    
'''


# In[1902]:


pd_transmission = train['Transmission'].value_counts().reset_index(name='Count')

plt.figure(figsize=(7,5))
plt.bar(pd_transmission['index'],pd_transmission['Count'], color='green') 
plt.xlabel('Transmission')
plt.ylabel('Frequency')
plt.xticks(rotation='vertical')


# **Observation:**
#     
# Most of the cars in the resale market are manual.

# ### Analyse Fuel_Type

# In[1903]:


pd_fuel_type = train['Fuel_Type'].value_counts().reset_index(name='Count')
pd_fuel_type


# In[1904]:


plt.bar(pd_fuel_type['index'],pd_fuel_type['Count'], color='green') 
plt.xlabel('Fuel Type')
plt.ylabel('Frequency')


# **Observation:**
#     
# Most of the cars are petrol or diesel.    

# ### Analyse Owner_Type

# In[1905]:


pd_owner_type = train['Owner_Type'].value_counts().reset_index(name='Count')
pd_owner_type


# In[1906]:


plt.bar(pd_owner_type['index'],pd_owner_type['Count'], color='green') 
plt.xlabel('Owner Type')
plt.ylabel('Frequency')


# **Observation:**
#     
# Most of the cars are from first hand owners.     

# ### Analyse Location

# In[1907]:


pd_location = train['Location'].value_counts().reset_index(name='Count')
pd_location


# In[1908]:


plt.figure(figsize=(7,5))
plt.bar(pd_location['index'],pd_location['Count'], color='green') 
plt.xlabel('Location')
plt.ylabel('Frequency')
plt.xticks(rotation='vertical')


# **Observation:**
#     
# Mumbai and Hyderabad are dominating the car selling market. Bangalore and Ahmedabad are the lowest. May be because in these cities customers prefer to buy a new car.

# ### Analyse Name

# In[1909]:


# Split the Name column using space delimiter
train['Name'] = train['Name'].str.replace(' Rover', '-Rover')
train['Name'] = train['Name'].str.replace('Mini Cooper', 'Mini-Cooper')


# In[1910]:


# Split the Name column using space delimiter
train['Name_Split'] = train['Name'].apply(lambda x: x.split(' '))


# In[1911]:


[each for each in train['Name_Split'] if len(each) < 3]


# In[1912]:


train.loc[train['Name'] == 'Mini-Cooper S', 'Name'] = 'Mini-Cooper S 2.0'


# In[1913]:


# Split the Name column using space delimiter
train['Name_Split'] = train['Name'].apply(lambda x: x.split(' '))


# In[1914]:


# Extract brand name of the car as the first element of Name and model from the 2nd element
train['Brand'] = train['Name_Split'].apply(lambda x: x[0])
train['Model'] = train['Name_Split'].apply(lambda x: x[1])
train['Variant'] = train['Name_Split'].apply(lambda x: x[2])


# In[1915]:


train.loc[train['Brand'] == 'ISUZU', 'Brand'] = 'Isuzu' # Replace ISUZU with Isuzu


# In[1916]:


#plt.figure(figsize=(15,7))
ax = train['Brand'].value_counts().plot(kind='barh', figsize=(10,7), color="green", fontsize=13);
ax.set_xlabel('Brand')
ax.set_ylabel('Frequency')

# invert for largest on top 
ax.invert_yaxis()


# In[1917]:


# Drop columns: Name, Name_Split

train.drop(['Name', 'Name_Split'], axis=1, inplace=True)


# **Observation:**
# 
# Most selling cars are from Maruti and Hyundai. Some brands are dominating the market whereas some brands are not much in the market.

# In[1918]:


luxury_segment = ['Land-Rover', 'BMW', 'Audi', 'Mercedes-Benz','Jaguar','Volvo','Porsche','Lamborghini',
'Rolls-Royce', 'Mitsubishi','Bentley','Ford', 'Jeep','Isuzu', 'Mini-Cooper']

train['Luxury'] = train['Brand'].apply(lambda x: 1 if x in luxury_segment else 0)


# In[1919]:


train.head()


# ### Analyse Seats

# In[1920]:


train['Seats'] = train['Seats'].astype(float)


# In[1921]:


train[train['Seats'].isnull()].head()


# In[1922]:


# Manually replace null values for seats for some records
train.loc[(train['Model'] == 'Swift') & (train['Variant'] == '1.3'), 'Seats'] = 5
train.loc[(train['Model'] == 'Estilo') & (train['Variant'] == 'LXI'), 'Seats'] = 5
train.loc[(train['Model'] == 'Punto') & (train['Variant'] == '1.2'), 'Seats'] = 5
train.loc[(train['Model'] == 'Punto') & (train['Variant'] == '1.3'), 'Seats'] = 5
train.loc[(train['Model'] == 'Punto') & (train['Variant'] == '1.4'), 'Seats'] = 5

train.loc[(train['Model'] == 'CR-V') & (train['Variant'] == 'AT'), 'Seats'] = 7
train.loc[(train['Model'] == 'CR-V') & (train['Variant'] == 'AT'), 'Engine'] = '1997 CC'
train.loc[(train['Model'] == 'CR-V') & (train['Variant'] == 'AT'), 'Power'] = '152 bhp'


# In[1923]:


# Replace nulls with values from the same brand-model-variant
train['Seats'] = train.groupby(['Brand', 'Model', 'Variant'])['Seats'].transform(lambda x: x.fillna(x.mode()[0]))


# In[1924]:


train['Seats'] = train['Seats'].astype(int)


# In[1925]:


# Check the distribution of number of seats
plt.hist(train['Seats'], bins=10, color='green') 
plt.xlabel('Seats')
plt.ylabel('Frequency')


# **Observation:**
#     
# Most cars have 5 seats but we can see some cars with 0 seats.    

# ### Analyse Year

# In[1926]:


# To see the distribution of the number of kilometers driven by the car

ax = sns.distplot(train['Year'],color='darkblue') 
ax.set(xlabel='Year', ylabel='Density')


# #### Convert Year to number of years since the model was released

# In[1927]:


import datetime

now = datetime.datetime.now()
currYear = now.year
print(currYear)


# In[1928]:


train['Age_of_model'] =  train['Year'].apply(lambda x: currYear - x)


# In[1929]:


# To see the distribution of the age of model

ax = sns.distplot(train['Age_of_model'],color='darkblue') 
ax.set(xlabel='Age_of_model', ylabel='Density')


# Most of the cars are of models which were released 5years back. Some are new models too.

# In[1930]:


# Drop the column Year
train.drop('Year', axis=1, inplace=True)


# ### Analyse Kilometers_Driven

# In[1931]:


# To see the distribution of the number of kilometers driven by the car

ax = sns.distplot(train['Kilometers_Driven'],color='darkblue') 
ax.set(xlabel='Kms driven', ylabel='Density')


# This column is right skewed and needs to be normalized 

# In[1932]:


# Normalize the column kilometers driven
train['Kms_Log'] = np.log(train['Kilometers_Driven'] + 1)
train.drop('Kilometers_Driven', axis=1, inplace=True)


# In[1933]:


# To see the distribution of the normalized values

ax = sns.distplot(train['Kms_Log'],color='darkblue') 
ax.set(xlabel='Kms driven', ylabel='Density')


# Now the column is almost normal

# ### Analyse Engine

# In[1934]:


train[train['Engine'].isnull()].head()


# In[1935]:


train_nulls = train[train['Engine'].isnull()]
train_not_nulls = train[~(train['Engine'].isnull())]
engine_nulls = train_nulls.groupby(['Brand', 'Model', 'Variant']).size().reset_index(name='Count')
engine_nulls


# In[1936]:


for index,row in engine_nulls.iterrows():
    brand = row['Brand']
    model = row['Model']
    variant = row['Variant']
    record = train_not_nulls[(train_not_nulls['Brand'] == brand) & (train_not_nulls['Model'] == model) & (train_not_nulls['Variant']== variant)]
    length = len(record)
    if length == 0:
        print(brand, model, variant)


# In[1937]:


train.loc[(train['Brand'] == 'Fiat') & (train['Model'] == 'Punto') & (train['Variant'] == '1.2'), 'Engine'] = '1172 CC'
train.loc[(train['Brand'] == 'Fiat') & (train['Model'] == 'Punto') & (train['Variant'] == '1.3'), 'Engine'] = '1248 CC'
train.loc[(train['Brand'] == 'Fiat') & (train['Model'] == 'Punto') & (train['Variant'] == '1.4'), 'Engine'] = '1368 CC'
train.loc[(train['Brand'] == 'Maruti') & (train['Model'] == 'Swift') & (train['Variant'] == '1.3'), 'Engine'] = '1197 CC'


# In[1938]:


train['Engine'] = train.groupby(['Brand', 'Model', 'Variant'])['Engine'].transform(lambda x: x.fillna(x.mode()[0]))


# In[1939]:


# Convert Engine to string datatype
train['Engine'] = train['Engine'].astype('str') 
# Remove units
train['Engine'] = train['Engine'].apply(lambda x: x.replace(' CC', ''))
# Convert to int
train['Engine'] = train['Engine'].astype(int)


# In[1940]:


# To see the distribution of engine of all the cars

ax = sns.distplot(train['Engine'],color='darkblue') 
ax.set(xlabel='Engine', ylabel='Density')


# ### Analyse Power

# In[1941]:


train['Power'] = train['Power'].astype(object).fillna('null bhp') # Change nulls to 'null bhp'


# In[1942]:


#len(train[train['Power'] == 'null bhp'])


# In[1943]:


# Replace units of power with blanks
train['Power'] = train['Power'].astype('str')
train['Power'] = train['Power'].apply(lambda x: x.replace(' bhp', '')) 


# In[1944]:


train['Power'] = train['Power'].apply(lambda x: x.replace('null', '0.0')) # Replace 'null' with 0.0 so that the column can be converted to flaot
train['Power'] = train['Power'].astype('float')
# Replace 0.0 with nulls
train.loc[train['Power']==0.0, 'Power'] = np.NaN


# In[1945]:


len(train[train['Power'].isnull()])


# In[1946]:


train_nulls = train[train['Power'].isnull()]
train_not_nulls = train[~(train['Power'].isnull())]
power_nulls = train_nulls.groupby(['Brand', 'Model', 'Engine']).size().reset_index(name='Count')
power_nulls.head()


# In[1947]:


for index,row in power_nulls.iterrows():
    brand = row['Brand']
    model = row['Model']
    engine = row['Engine']
    record = train_not_nulls[(train_not_nulls['Brand'] == brand) & (train_not_nulls['Model'] == model) & (train_not_nulls['Engine']== engine)]
    length = len(record)
    if length == 0:
        print(brand, model, engine)


# In[1948]:


train.loc[(train['Brand'] == 'Audi') & (train['Model'] == 'A4') & (train['Engine'] == 3197), 'Power']    = 251.5
train.loc[(train['Brand'] == 'Fiat') & (train['Model'] == 'Petra') & (train['Engine'] == 1242), 'Power'] = 72.0
train.loc[(train['Brand'] == 'Fiat') & (train['Model'] == 'Punto') & (train['Engine'] == 1248), 'Power'] = 75.0
train.loc[(train['Brand'] == 'Fiat') & (train['Model'] == 'Punto') & (train['Engine'] == 1368), 'Power'] = 88.7
train.loc[(train['Brand'] == 'Fiat') & (train['Model'] == 'Siena') & (train['Engine'] == 1242), 'Power'] = 63.1
train.loc[(train['Brand'] == 'Hyundai') & (train['Model'] == 'Santro') & (train['Engine'] == 999), 'Power'] = 58.0
train.loc[(train['Brand'] == 'Mahindra') & (train['Model'] == 'Jeep') & (train['Engine'] == 2112), 'Power'] = 62.0
train.loc[(train['Brand'] == 'Mahindra') & (train['Model'] == 'Jeep') & (train['Engine'] == 2498), 'Power'] = 105.0
train.loc[(train['Brand'] == 'Maruti') & (train['Model'] == '1000') & (train['Engine'] == 970), 'Power'] = 37.0
train.loc[(train['Brand'] == 'Maruti') & (train['Model'] == 'Estilo') & (train['Engine'] == 1061), 'Power'] = 64.0
train.loc[(train['Brand'] == 'Nissan') & (train['Model'] == 'Teana') & (train['Engine'] == 2349), 'Power'] = 179.5
train.loc[(train['Brand'] == 'Porsche') & (train['Model'] == 'Cayman') & (train['Engine'] == 3436), 'Power'] = 295.0
train.loc[(train['Brand'] == 'Smart') & (train['Model'] == 'Fortwo') & (train['Engine'] == 799), 'Power'] = 53.0


# In[1949]:


#train.loc[train['Model'] == 'Santro', 'Power'] = 58.0 # Replace null with 58 for Santro
#train.loc[train['Model'] == 'Esteem', 'Power'] = 85.0 # Replace null with 85 for Esteem
#train.loc[train['Model'] == '1000', 'Power'] = 37.0 # Replace null with 37 for Maruthi 1000
#train.loc[train['Model'] == 'Siena', 'Power'] = 70.0 # Replace null with 37 for Siena
#train.loc[train['Model'] == 'Fortwo', 'Power'] = 53.0 # Replace null with 53 for Fortwo
#train.loc[train['Model'] == 'Estilo', 'Power'] = 64.0 # Replace null with 64 for Estilo
#train.loc[train['Model'] == 'Jeep', 'Power'] = 65.0 # Replace null with 65 for Jeep
#train.loc[train['Model'] == 'Petra', 'Power'] = 72.0 # Replace null with 72 for Petra
#train.loc[train['Model'] == 'Cayman', 'Power'] = 295.0 # Replace null with 295 for Cayman


# In[1950]:


# Replace null values with the median value for the same number of seats
train['Power'] = train.groupby(['Brand', 'Model', 'Engine'])['Power'].transform(lambda x: x.fillna(x.mode()[0]))


# In[1951]:


train[train['Power'].isnull()] # Check again for nulls


# In[1952]:


# To see the distribution of Power of all the cars

ax = sns.distplot(train['Power'],color='darkblue') 
ax.set(xlabel='Power', ylabel='Density')


# In[1953]:


train.isnull().sum()


# ### Analyse Mileage

# In[1954]:


train[train['Mileage'].isnull()] #Check for records with null values for Mileage


# In[1955]:


# Manually replace nulls for the above records
train.loc[(train['Brand'] == 'Mahindra') & (train['Model'] == 'E') & (train['Fuel_Type'] == 'Electric'), 'Mileage'] = '110.0' 
train.loc[(train['Brand'] == 'Toyota') & (train['Model'] == 'Prius') & (train['Fuel_Type'] == 'Electric'), 'Mileage'] = '23.91' 


# In[1956]:


# Drop the records with null values for Mileage
#train = train[train.Mileage.notnull()]


# In[1957]:


train['Mileage'] = train['Mileage'].apply(lambda x: x.replace(' kmpl', ''))
train['Mileage'] = train['Mileage'].apply(lambda x: x.replace(' km/kg', ''))


# In[1958]:


train.head()


# In[1959]:


train['Mileage'] = train['Mileage'].astype(float)


# In[1960]:


# To see the distribution of mileage of all the cars

ax = sns.distplot(train['Mileage'],color='darkblue') 
ax.set(xlabel='Mileage', ylabel='Density')


# In[1961]:


train[train['Mileage'] == 0.0].head() # Check for records with 0 for mileage


# In[1962]:


train.loc[train['Mileage'] == 0.0 , 'Mileage'] = np.NaN     # Replace 0.0 with NaN


# In[1963]:


#Replace null values with the median value for the same brand, model, transmission and fuel type
train['Mileage'] = train.groupby(['Brand', 'Model', 'Fuel_Type', 'Transmission'])['Mileage'].transform(lambda x: x.fillna(x.median()))


# In[1964]:


train[train['Mileage'].isnull()].head() # Check for missing values in Mileage


# In[1965]:


# Manually replace null values for mileage

train.loc[(train['Brand'] =='Mercedes-Benz') & (train['Model'] == 'C-Class') & (train['Transmission'] == 'Automatic') & (train['Fuel_Type'] == 'Diesel'), 'Mileage'] = 11.9 
train.loc[(train['Brand'] =='Land') & (train['Model'] == 'Rover') & (train['Owner_Type'] == 'First') & (train['Transmission'] == 'Manual'), 'Mileage'] = 12.65
train.loc[(train['Brand'] =='Mahindra') & (train['Model'] == 'Jeep') & (train['Owner_Type'] == 'First') & (train['Transmission'] == 'Manual'), 'Mileage'] = 18.0
train.loc[(train['Brand'] == 'Fiat') & (train['Model'] == 'Siena') & (train['Owner_Type'] == 'Third') & (train['Transmission'] == 'Manual'), 'Mileage'] = 23.0 
train.loc[(train['Brand'] == 'Smart') & (train['Model'] == 'Fortwo'), 'Mileage'] = 23.38


# In[1966]:


train[train['Mileage'].isnull()].head() # Check again for missing values in Mileage


# In[1967]:


# Remove the above record as the corresponding value is not available online
train = train[~((train['Brand'] =='Land-Rover') & (train['Model'] == 'Range-Rover') & (train['Transmission'] == 'Manual') & (train['Fuel_Type'] == 'Petrol'))]


# In[1968]:


train.shape


# In[1969]:


# Distribution of Mileage

ax = sns.distplot(train['Mileage'],color='darkblue') 
ax.set(xlabel='Price', ylabel='Density')


# There is clearly an outlier. We need to check and remove the outlier.

# In[1970]:


train[train['Mileage'] > 100]


# In[1971]:


# Remove the outlier record which has mileage > 100
train = train[train['Mileage'] < 100]


# In[1972]:


# Check again the distribution of Mileage

ax = sns.distplot(train['Mileage'],color='darkblue') 
ax.set(xlabel='Price', ylabel='Density')


# Now the distribution is almost normal.

# ### Analyse Price

# In[1973]:


sns.boxplot(train['Price'])


# In[1974]:


train[train['Price'] == 160]


# This is an outlier

# In[1975]:


# Distribution of target

ax = sns.distplot(train['Price'],color='darkblue') 
ax.set(xlabel='Price', ylabel='Density')


# Target is right skewed and hence needs to be normalized

# In[1976]:


train['Price_Log'] = np.log10(train['Price'])


# In[1977]:


train.drop('Price', axis=1, inplace=True) # Drop column Price
train  = train.rename(columns = {'Price_Log': 'Price'}) # Rename 'Price_Log' to 'Price'


# In[1978]:


# Distribution of target after taking log

ax = sns.distplot(train['Price'],color='darkviolet') 
ax.set(xlabel='Price', ylabel='Density')


# Now the target is normally distributed.

# In[1979]:


train.isnull().sum() # To check if there are any nulls


# ## Bivariate Analysis

# ### Correlation between Mileage for 1st, 2nd 3rd hand and 4th hand cars

# In[1980]:


first_hand = train.loc[train['Owner_Type'] == 'First']
second_hand = train.loc[train['Owner_Type'] == 'Second']
third_hand = train.loc[train['Owner_Type'] == 'Third']
fourth_hand = train.loc[train['Owner_Type'] == 'Fourth & Above']


# In[1981]:


datasets = [first_hand, second_hand, third_hand, fourth_hand]


# In[1982]:


n = 1
plt.figure(figsize=(15, 5))
for dataset in datasets:    
    plt.subplot(2, 2, n)
    plt.scatter(x=dataset['Brand'], y=dataset['Mileage'], color='blue')
    plt.xlabel('Brand')
    plt.ylabel('Mileage')
    plt.xticks(rotation='vertical')
    n = n + 1
    plt.grid(True)
plt.tight_layout()
plt.show()       


# ### Correlation between Price and numerical features

# In[1983]:


plt.scatter(train['Power'], train['Price'], color='green')
plt.xlabel('Power in bhp')
plt.ylabel('Price in INR Lakhs')


# There is a positive linear correlation between power and price of the car.

# In[1984]:


plt.scatter(train['Engine'], train['Price'], color='green')
plt.xlabel('Engine in CC')
plt.ylabel('Price in INR Lakhs')


# There is positive linear correlation between engine volume and price of the car.

# In[1985]:


plt.scatter(train['Power'], train['Mileage'], color='blue')
plt.xlabel('Power')
plt.ylabel('Mileage')


# There is negative linear correlation between power and mileage of a car.

# In[1986]:


plt.scatter(train['Engine'], train['Mileage'], color='blue')
plt.xlabel('Engine')
plt.ylabel('Mileage')


# There is negative linear correlation between engine capacity and mileage of a car.

# In[1987]:


plt.scatter(train['Seats'], train['Price'], color='orange')
plt.xlabel('Number of seats')
plt.ylabel('Price in INR Lakhs')


# There is not much linear correlation between number of seats and price of the car.

# In[1988]:


plt.scatter(train['Age_of_model'], train['Price'], color='orange')
plt.xlabel('Number of years')
plt.ylabel('Price in INR Lakhs')


# There is a negative linear correlation between the number of years since the model was released and the price of the car.

# In[1989]:


plt.scatter(train['Mileage'], train['Price'], color='blue')
plt.xlabel('Mileage')
plt.ylabel('Price in INR Lakhs')


# There is not much linear correlation between mileage and price of the car. Still we can say that cars with less mileage are highly priced. This is seen in luxury cars where mileage is less but price is very ligh.

# In[1990]:


plt.scatter(train['Kms_Log'], train['Price'], color='blue')
plt.xlabel('Kilometers')
plt.ylabel('Price in INR Lakhs')


# There is not much linear correlation between number of kilometers driven and price of the car. But there are some outliers which needs to be removed.

# In[1991]:


sns.boxplot(train['Kms_Log'])


# #### Outlier treatment for Kilometers_Driven

# In[1992]:


kms_q1, kms_q3 = np.percentile(train['Kms_Log'], [25,75])
kms_std = train['Kms_Log'].std()
kms_3_std = 3 * kms_std

kms_upper_limit = kms_q3 + kms_3_std
kms_lower_limit = kms_q1 - kms_3_std

kms_median = train['Kms_Log'].median() # Find the median value of number of kilometers driven

# Replace the outliers with median and check again
train.loc[train['Kms_Log'] > kms_upper_limit, 'Kms_Log'] = kms_upper_limit
train.loc[train['Kms_Log'] < kms_lower_limit, 'Kms_Log'] = kms_lower_limit


# In[1993]:


'''
plt.scatter(train['Kms_Log'], train['Price'], color='blue')
plt.xlabel('Kilometers')
plt.ylabel('Price in INR Lakhs')
'''


# There is a slight negative linear correlation between number of kilometers driven and price of the car.

# ### Correlation between Price and categorical features

# In[1994]:


### Correlation between luxury segment and price

# Transmission-Price relation using Violin plot
plt.figure(figsize=(7,7))
sns.violinplot(x="Luxury", y="Price", data=train, size=8)
plt.show()


# Luxury segment cars are highly priced.

# In[1995]:


#Boxplot to check how fuel type of a car and it's price vary

plt.figure(figsize=(10,7))
ax = sns.boxplot(x='Price',y='Fuel_Type', data=train) 
ax.set(xlabel='Price', ylabel='Fuel Type')
plt.show()


# There are more petrol and diesel cars compared to electric, LPG and CNG. Diesel cars are more priced compared to petrol.
# Fuel type has a correlation with the price of the car.

# In[1996]:


'''
# Convert Fuel_Type column to numeric
fuel_map = {'Diesel': 1, 'Petrol': 2, 'Electric': 3, 'CNG':4, 'LPG':5}
train['Fuel_Type_Map'] = train['Fuel_Type'].map(fuel_map)

train.drop('Fuel_Type', axis=1,inplace=True)
'''


# In[1997]:


# Transmission-Price relation using Violin plot
plt.figure(figsize=(7,7))
sns.violinplot(x="Transmission", y="Price", data=train, size=8)
plt.show()


# Automatic cars are higher priced than manual cars.

# In[1998]:


# Convert Transmission column to numeric
trans_map = {'Manual': 1, 'Automatic': 2}
train['Transmission_Map'] = train['Transmission'].map(trans_map)


# In[1999]:


train.drop('Transmission', axis=1,inplace=True)


# In[2000]:


# Owner type-Price relation using Violin plot
plt.figure(figsize=(7,7))
sns.violinplot(x="Owner_Type", y="Price", data=train, size=8)
plt.show()


# 4th hand and above cars are priced much lower than 1st, 2nd and 3rd cars. 
# There is not much price difference between 1st, 2nd and 3rd hand car pricing.

# In[2001]:


owner_map = {'First': 1, 'Second': 2, 'Third': 3, 'Fourth & Above': 4}
train['Owner_Type_Map'] = train['Owner_Type'].map(owner_map)


# In[2002]:


train.drop('Owner_Type', axis=1,inplace=True)


# In[2003]:


#Boxplot to check how location(city) of a car and it's price vary

plt.figure(figsize=(10,7))
ax = sns.boxplot(x='Price',y='Location', data=train) 
ax.set(xlabel='Price', ylabel='Location')
plt.show()


# Coimbatore and Bangalore have cars with higher prices.
# Jaipur, Chennai, Delhi, Kolkata, Pune, Hyderabad, Pune, Mumbai have cars with lower prices.

# In[2004]:


# Plot all the features in pairs to see how they vary together


# In[2005]:


sns.pairplot(train);


# In[2006]:


# Check for correlation using a heatmap
matrix = train.corr()
f, ax = plt.subplots(figsize=(9, 6))
sns.heatmap(matrix, vmax=.8, square=True, cmap="BuPu", annot=True);


# **Correlations found:**
#     
# * Price has strong +ve linear correlation to Power, Engine    
# * Price has -ve correlation to number of years since the model was released
# * Number of years and kilometers driven are +vely correlated.
# * Engine and power are strongly +vely correlated.
# * Mileage is -vely correlated to engine and power.
# * Number of seats and engine are +vely correlated.

# ## Data Pre-processing

# In[2007]:


train.head()


# ### Normalise skewed numerical features

# In[2008]:


train.info() # Check the datatypes of all the columns


# In[2009]:


numerical_features = list(train.select_dtypes(include=[np.float, np.integer]).columns)
numerical_features.remove('Price')
numerical_features


# In[2010]:


n = 1
plt.figure(figsize=(15,5))
for each in numerical_features:
    plt.subplot(3, 4, n)
    plt.hist(train[each], color='orange')
    plt.xlabel(each)
    n = n + 1
plt.tight_layout()
plt.show()    


# Kilometers_Driven, Engine, Power are right skewed.

# ### Normalising numerical features

# In[2011]:


#train['Kilometers_Driven'] = np.log10(train['Kilometers_Driven'])

train['Engine'] = np.log(train['Engine'] + 1)
train['Power'] = np.log(train['Power'] + 1)
train['Age_of_model'] = np.log(train['Age_of_model'] + 1)


# In[2012]:


# Check again after normalizing
n = 1
plt.figure(figsize=(15,5))
for each in numerical_features:
    plt.subplot(3, 4, n)
    plt.hist(train[each], color='green')
    plt.xlabel(each)
    n = n + 1
plt.tight_layout()
plt.show() 


# In[2013]:


'''
mileage_bins = [0, 10, 15, 20, 25, 30, 100]
labels = ['mil_0_10', 'mil_10_15', 'mil_15_20', 'mil_20_25', 'mil_25_30', 'mil_30_100']
train['Mileage_binned'] = pd.cut(train['Mileage'], bins=mileage_bins, labels=labels)

age_bins = [0,0.5,1,1.5,2,2.5,3,10]
labels = ['age_0_0.5', 'age_0.5_1', 'age_1_1.5', 'age_1.5_2', 'age_2_2.5', 'age_2.5_3', 'age_3_above']
train['Age_binned'] = pd.cut(train['Age_of_model'], bins=age_bins, labels=labels)

kms_bins = [0,3.5,4,4.5,5,5.5,10]
labels = ['kms_below_3.5', 'kms_3.5_4', 'kms_4_4.5', 'kms_4.5_5', 'kms_5_5.5', 'kms_above_5.5']
train['Kms_binned'] = pd.cut(train['Kms_Log'], bins=kms_bins, labels=labels)
'''


# In[2014]:


# Drop the column Mileage, Age_of_model, Kms_Log
#train.drop(['Mileage', 'Age_of_model', 'Kms_Log'], axis=1,inplace=True)


# In[2015]:


# Drop the column Model, Variant
train.drop(['Model', 'Variant'], axis=1,inplace=True)


# In[2016]:


train.head()


# In[2017]:


train_dummies = pd.get_dummies(train, columns=['Location','Fuel_Type' ,'Brand'])# , 'Mileage_binned', 'Age_binned', 'Kms_binned'])
train_dummies.head()


# In[2018]:


# Split into X & y
y=train_dummies['Price']
X = train_dummies.drop(['Price'], axis=1)


# In[2019]:


missing_vals(X) # Check if any missing values are present in X


# In[2020]:


X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.3, random_state=0)


# ### Model building

# In[2021]:


model = LinearRegression()
model.fit(X_train, y_train)
y_pred_lr = model.predict(X_test)

# Compute RMSE
rmse_lr = np.sqrt(mean_squared_error(y_test, y_pred_lr))
print(rmse_lr)
print(1-rmse_lr)


# In[2022]:


dt = DecisionTreeRegressor()
dt.fit(X_train, y_train)
y_pred_dt = dt.predict(X_test)

# Compute RMSE
rmse_dt = np.sqrt(mean_squared_error(y_test, y_pred_dt))
print(rmse_dt)
print(1-rmse_dt)


# In[2023]:


rf = RandomForestRegressor(n_estimators=100)
rf.fit(X_train, y_train)
y_pred_rf = rf.predict(X_test)

# Compute RMSE
rmse_rf = np.sqrt(mean_squared_error(y_test, y_pred_rf))
print(rmse_rf)
print(1-rmse_rf)


# In[2024]:


gb = GradientBoostingRegressor(n_estimators=3000, learning_rate=0.01,
                                   max_depth=10, max_features='sqrt',
                                   min_samples_leaf=15, min_samples_split=10, 
                                   loss='huber', random_state =5)
gb.fit(X_train, y_train)
y_pred_gb = gb.predict(X_test)

# Compute the rmse: rmse
rmse_gb = np.sqrt(mean_squared_error(y_test, y_pred_gb))
print(rmse_gb)
print(1-rmse_gb)


# # Load test data

# In[2025]:


test = pd.read_excel('Data_Test.xlsx')


# ## Test Data Pre-Processing

# In[2026]:


test.drop('New_Price', axis=1, inplace=True)


# In[2027]:


missing_vals(test)


# Engine, Power and Seats have nulls

# #### Name column

# In[2028]:


test['Name'] = test['Name'].str.replace(' Rover', '-Rover')
test['Name'] = test['Name'].str.replace('Mini Cooper', 'Mini-Cooper')
test['Name'] = test['Name'].str.replace('Hindustan Motors', 'Hindustan-Motors')
test.loc[test['Name'] == 'OpelCorsa 1.4Gsi', 'Name'] = 'Opel Corsa 1.4Gsi'


# In[2029]:


# Split the Name column using space delimiter
test['Name_Split'] = test['Name'].apply(lambda x: x.split(' '))


# In[2030]:


# Check if there are any names without model and variant information
[each for each in test['Name_Split'] if len(each)<3]


# In[2031]:


test.loc[test['Name'] == 'Mini-Cooper S', 'Name'] = 'Mini-Cooper S 2.0'


# In[2032]:


# Split the Name column using space delimiter
test['Name_Split'] = test['Name'].apply(lambda x: x.split(' '))


# In[2033]:


# Extract brand name and model of the car as the first and second element of Name
test['Brand'] = test['Name_Split'].apply(lambda x: x[0])
test['Model'] = test['Name_Split'].apply(lambda x: x[1])
test['Variant'] = test['Name_Split'].apply(lambda x: x[2])


# In[2034]:


test.loc[test['Brand'] == 'ISUZU', 'Brand'] = 'Isuzu' # Replace ISUZU with Isuzu


# In[2035]:


luxury_segment = ['Land-Rover', 'BMW', 'Audi', 'Mercedes-Benz','Jaguar','Volvo','Porsche','Lamborghini',
'Rolls-Royce', 'Mitsubishi','Bentley','Ford', 'Jeep','Isuzu', 'Mini-Cooper']

test['Luxury'] = test['Brand'].apply(lambda x: 1 if x in luxury_segment else 0)


# In[2036]:


# Drop columns: Name, Name_Split
test.drop(['Name', 'Name_Split'], axis=1, inplace=True)


# In[2037]:


test.head()


# #### Seat column

# In[2038]:


test[test['Seats'].isnull()] # Check for nulls


# In[2039]:


test['Seats'] = test['Seats'].astype(float)


# In[2040]:


test_nulls = test[test['Seats'].isnull()]
test_not_nulls = test[~(test['Seats'].isnull())]
seat_nulls = test_nulls.groupby(['Brand', 'Model', 'Variant']).size().reset_index(name='Count')

for index,row in seat_nulls.iterrows():
    brand = row['Brand']
    model = row['Model']
    variant = row['Variant']
    record = test_not_nulls[(test_not_nulls['Brand'] == brand) & (test_not_nulls['Model'] == model) & (test_not_nulls['Variant']== variant)]
    length = len(record)
    if length == 0:
        print(brand, model, variant)


# In[2041]:


test.loc[(test['Brand']== 'Fiat') & (test['Model']== 'Punto') & (test['Variant'] == '1.4'), 'Seats'] = 5
test.loc[(test['Brand']== 'Honda') & (test['Model']== 'Jazz') & (test['Variant'] == '2020'), 'Seats'] = 5
test.loc[(test['Brand']== 'Hyundai') & (test['Model']== 'i20') & (test['Variant'] == 'new'), 'Seats'] = 5
test.loc[(test['Brand']== 'Maruti') & (test['Model']== 'Swift') & (test['Variant'] == '1.3'), 'Seats'] = 5
test.loc[(test['Brand']== 'Skoda') & (test['Model']== 'Laura') & (test['Variant'] == '1.8'), 'Seats'] = 5


# In[2042]:


test['Seats'] = test.groupby(['Brand', 'Model', 'Variant'])['Seats'].transform(lambda x: x.fillna(x.mode()[0]))


# In[2043]:


test[test['Seats'].isnull()] # Check again for nulls


# In[2044]:


test['Seats'] = test['Seats'].astype(int)


# #### Year column

# In[2045]:


# Create a new column Years_Since which is number of years since the car model was released
test['Age_of_model'] =  test['Year'].apply(lambda x: currYear - x)

# Drop the column Year
test.drop('Year', axis=1, inplace=True)


# #### Engine column

# In[2046]:


test[test['Engine'].isnull()] # Check for nulls


# In[2047]:


test_nulls = test[test['Engine'].isnull()]
test_not_nulls = test[~(test['Engine'].isnull())]
engine_nulls = test_nulls.groupby(['Brand', 'Model', 'Variant', 'Fuel_Type']).size().reset_index(name='Count')


for index,row in engine_nulls.iterrows():
    brand = row['Brand']
    model = row['Model']
    variant = row['Variant']
    fuel = row['Fuel_Type']
    record = test_not_nulls[(test_not_nulls['Brand'] == brand) & (test_not_nulls['Model'] == model) & (test_not_nulls['Variant']== variant) & (test_not_nulls['Fuel_Type']== fuel)]
    length = len(record)
    if length == 0:
        print(brand, model, variant, fuel)


# In[2048]:


# Manually replace nulls for the above records
test.loc[(test['Model'] == 'Punto') & (test['Variant'] == '1.4') & (test['Fuel_Type'] == 'Petrol'), 'Engine'] = '1172 CC'
test.loc[(test['Model'] == 'i20') & (test['Variant'] == 'new') & (test['Fuel_Type'] == 'Petrol'), 'Engine'] = '1197 CC'
test.loc[(test['Model'] == 'Laura') & (test['Variant'] == '1.8') & (test['Fuel_Type'] == 'Petrol'), 'Engine'] = '1798 CC'
test.loc[(test['Model'] == 'Swift') & (test['Variant'] == '1.3') & (test['Fuel_Type'] == 'Petrol'), 'Engine'] = '1493 CC'
#test.loc[(test['Model'] == 'Laura'), 'Mileage'] = '18.49 kmpl'


# In[2049]:


# Replace null values with the most occuring value for the same Brand-Model-Variant-Fuel Type
test['Engine'] = test.groupby(['Brand', 'Model', 'Variant', 'Fuel_Type'])['Engine'].transform(lambda x: x.fillna(x.mode()[0])) 


# In[2050]:


test[test['Engine'].isnull()] # Check again for nulls


# In[2051]:


# Remove units and convert engine values to integer

test['Engine'] = test['Engine'].astype(str)
test['Engine'] = test['Engine'].apply(lambda x: x.replace(' CC', ''))
test['Engine'] = test['Engine'].astype(int)


# #### Power column

# In[2052]:


test['Power'] = test['Power'].astype('str') # Convert Power to string datatype
test['Power'] = test['Power'].apply(lambda x: x.replace(' bhp', '')) # Replace units of power with blanks
test['Power'] = test['Power'].apply(lambda x: x.replace('null', '0.0')) # Replace 'null' with 0.0 so that the column can be converted to float

test['Power'] = test['Power'].astype('float') # Convert Power to float datatype
test.loc[test['Power'] == 0.0 , 'Power'] = np.NaN     # Replace 0.0 with NaN


# In[2053]:


test[test['Power'].isnull()].head() # Check for nulls


# In[2054]:


test_nulls = test[test['Power'].isnull()]
test_not_nulls = test[~(test['Power'].isnull())]
power_nulls = test_nulls.groupby(['Brand', 'Model', 'Engine']).size().reset_index(name='Count')

for index,row in power_nulls.iterrows():
    brand = row['Brand']
    model = row['Model']
    engine = row['Engine']
    record = test_not_nulls[(test_not_nulls['Brand'] == brand) & (test_not_nulls['Model'] == model) & (test_not_nulls['Engine']== engine)]
    length = len(record)
    if length == 0:
        print(brand, model, engine)


# In[2055]:


#Manually enter the power and milage values
test.loc[(test['Model'] == 'Laura') & (test['Engine'] == 1798), 'Power'] = 157.8
test.loc[(test['Model'] == 'Teana') & (test['Engine'] == 2349), 'Power'] = 170
test.loc[(test['Model'] == 'Punto') & (test['Engine'] == 1172), 'Power'] = 67
test.loc[(test['Model'] == 'Santro') & (test['Engine'] == 999), 'Power'] = 62
test.loc[(test['Model'] == 'Contessa') & (test['Engine'] == 1995), 'Power'] = 35.5
test.loc[(test['Model'] == 'Swift') & (test['Engine'] == 1493), 'Power'] = 70.0

#test.loc[(test['Model'] == 'Santro') & (test['Engine'] == 999), 'Mileage'] = 32


# In[2056]:


# Replace null values with the median value for the same Brand-Model-Engine
test['Power'] = test.groupby(['Brand', 'Model', 'Engine'])['Power'].transform(lambda x: x.fillna(x.mode()[0]))


# In[2057]:


test[test['Power'].isnull()] # Check again for nulls


# #### Mileage column

# In[2058]:


test['Mileage'] = test['Mileage'].astype(str)


# In[2059]:


test['Mileage'] = test['Mileage'].apply(lambda x: x.replace(' kmpl', ''))
test['Mileage'] = test['Mileage'].apply(lambda x: x.replace(' km/kg', ''))


# In[2060]:


test['Mileage'] = test['Mileage'].astype(float)


# In[2061]:


test[test['Mileage'] == 0.0] # Check for records with 0 for mileage


# In[2062]:


test.loc[test['Mileage'] == 0.0 , 'Mileage'] = np.NaN # Replace 0s with nulls


# In[2063]:


#Replace null values with the median value for the same brand, model, transmission and fuel type
test['Mileage'] = test.groupby(['Brand', 'Model', 'Fuel_Type', 'Transmission'])['Mileage'].transform(lambda x: x.fillna(x.median()))


# In[2064]:


test.isnull().sum() # Check for nulls


# #### Kilometers_Driven column

# In[2065]:


# Normalize the column kilometers driven
test['Kms_Log'] = np.log(test['Kilometers_Driven'] + 1)
test.drop('Kilometers_Driven', axis=1, inplace=True)


# ### Mapping Transmission and Owner_Type columns to numeric

# In[2066]:


trans_map = {'Manual': 1, 'Automatic': 2}
test['Transmission_Map'] = test['Transmission'].map(trans_map)

owner_map = {'First': 1, 'Second': 2, 'Third': 3, 'Fourth & Above': 4}
test['Owner_Type_Map'] = test['Owner_Type'].map(owner_map)

# Convert Fuel_Type column to numeric
#fuel_map = {'Diesel': 1, 'Petrol': 2, 'Electric': 3, 'CNG':4, 'LPG':5}
#test['Fuel_Type_Map'] = test['Fuel_Type'].map(fuel_map)


# In[2067]:


test.drop('Transmission', axis=1,inplace=True)
test.drop('Owner_Type', axis=1,inplace=True)
#test.drop('Fuel_Type', axis=1,inplace=True)


# ### Normalising numerical features

# In[2068]:


test['Engine'] = np.log(test['Engine'] + 1)
test['Power'] = np.log(test['Power'] + 1)
test['Age_of_model'] = np.log(test['Age_of_model'] + 1)


# In[2069]:


# Drop the column Mileage, Age_of_model, Kms_Log
#test.drop(['Mileage', 'Age_of_model', 'Kms_Log'], axis=1,inplace=True)

# Drop the column Model, Variant
test.drop(['Model', 'Variant'], axis=1,inplace=True)


# In[2070]:


test_dummies = pd.get_dummies(test, columns=['Location','Fuel_Type','Brand']) # , 'Mileage_binned', 'Age_binned', 'Kms_binned'])
test_dummies.head()


# In[2071]:


X_train.shape


# In[2072]:


test_dummies.shape


# In[2073]:


test_columns = test_dummies.columns.values


# In[2074]:


train_columns = X_train.columns.values


# In[2075]:


[each  for each in train_columns if each not in test_columns]


# In[2076]:


# Adding missing columns to test
test_dummies['Fuel_Type_Electric'] = 0
test_dummies['Brand_Ambassador'] = 0
test_dummies['Brand_Force'] = 0
test_dummies['Brand_Lamborghini'] = 0
test_dummies['Brand_Smart'] = 0


# In[2077]:


[each  for each in test_columns if each not in train_columns]


# In[2078]:


# Drop columns that are not present in train
test_dummies.drop(['Brand_Hindustan-Motors','Brand_Opel'], axis=1, inplace=True)


# In[2079]:


#test_scaled = sc.transform(test_dummies)


# In[2080]:


predictions = gb.predict(test_dummies)


# In[2081]:


predictions_exp = [round(10**x,2) for x in predictions]


# In[2082]:


sub = pd.DataFrame()
sub['Price'] = predictions_exp


# In[2083]:


sub.head(10)


# In[2084]:


sub.to_excel('car_price_predictions.xlsx',index=False, engine='xlsxwriter')


# In[ ]:




