import csv

# Initialize array
all_trends = []

####################################################################################################
#
# Merge all the cleansed trends from trends_3_words.csv, trends_4_words.csv and trends_5_words.csv
# Write the merged trends into clean_trends.csv
#
####################################################################################################

with open('/home/ubuntu/cleaning/output/trends_3_words.csv', 'r') as csvfile:
        csv_reader = csv.reader(csvfile, delimiter=',')
        next(csv_reader)
        for row in csv_reader:
            if len(row) != 0:
                trend = row[1]
                score = row[2]
                if trend.strip() != ' ' and trend.strip() != '':
                        new_row = trend.strip() + '\t' + score
                        all_trends.append(new_row)
                
                
with open('/home/ubuntu/cleaning/output/trends_4_words.csv', 'r') as csvfile:
        csv_reader = csv.reader(csvfile, delimiter=',')
        next(csv_reader)
        for row in csv_reader:
            if len(row) != 0:
                trend = row[1]
                score = row[2]
                if trend.strip() != ' ' and trend.strip() != '':
                        new_row = trend.strip() + '\t' + score
                        all_trends.append(new_row)                
                
with open('/home/ubuntu/cleaning/output/trends_5_words.csv', 'r') as csvfile:
        csv_reader = csv.reader(csvfile, delimiter=',')
        next(csv_reader)
        for row in csv_reader:
            if len(row) != 0:
                trend = row[1]
                score = row[2]
                if trend.strip() != ' ' and trend.strip() != '':
                        new_row = trend.strip() + '\t' + score
                        all_trends.append(new_row)                   
                
f1 = open('/home/ubuntu/cleaning/output/cleansed_trends.csv', 'w')   
for item in all_trends:
        f1.write(str(item))
        f1.write('\n')
f1.close()