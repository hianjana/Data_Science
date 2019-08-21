import csv
import math

# Initializing lists
data                       = []
article_type               = []
article_type_lst           = []
max_score_per_article_type = []
normalized_data            = []

def read_file():

    with open('/home/hadoop/timeseries/trends_timeseries.csv','r') as f:
         reader=csv.reader(f,delimiter='\t')
         for row in reader:
               data.append(row)
               article_type.append(row[3])
    
    # Find unique value of article_type  
    article_type_set = set(article_type)
    article_type_lst = list(article_type_set)
    return article_type_lst
    
def normalize_scores():
     
     article_type_lst = read_file()
     # Here the maximum score per article_type is calculated and stored in max_score_per_article_type
     for article in article_type_lst:
          score1        = []
          score2        = []
          score3        = []
          max_score1    = 0
          max_score2    = 0
          max_score3    = 0
          for i in data:
               if article == i[3]:
                    score1.append(int(i[5]))
                    score2.append(int(i[6]))
                    score3.append(int(i[7]))
          max_score1 = max(score1)
          max_score2 = max(score2)
          max_score3 = max(score3)
          max_score_per_article_type.append([article, max_score1, max_score2, max_score3])
     
     # Here we are normalizing the 3 scores using the max score calculated per article_type
     for i in data:
           curr_article   = i[3]
           score1_regular = int(i[5])
           score2_regular = int(i[6])
           score3_regular = int(i[7])
           # Finding Max Score 1 for the corresponding article_type
           max_score1_art_type = [t[1] for t in max_score_per_article_type if t[0] == curr_article]
           max_score1_str      = str(max_score1_art_type).strip('[]')
           int_max_score1      = int(max_score1_str)
           # Finding Max Score 2 for the corresponding article_type
           max_score2_art_type = [t[2] for t in max_score_per_article_type if t[0] == curr_article]
           max_score2_str      = str(max_score2_art_type).strip('[]')
           int_max_score2      = int(max_score2_str)
           # Finding Max Score 3 for the corresponding article_type
           max_score3_art_type = [t[3] for t in max_score_per_article_type if t[0] == curr_article]
           max_score3_str      = str(max_score3_art_type).strip('[]')
           int_max_score3      = int(max_score3_str) 
           # Calculate a normalized score by dividing the existing score by the max score obtained for the article type 
           norm_score1         = math.ceil((score1_regular/int_max_score1)*10)
           norm_score2         = math.ceil((score2_regular/int_max_score2)*10)
           norm_score3         = math.ceil((score3_regular/int_max_score3)*10)
           #str_score_1         = 'sep:' + ("%.2f" % norm_score1)
           #str_score_2         = 'oct:' + ("%.2f" % norm_score2)
           #str_score_3         = 'dec:' + ("%.2f" % norm_score3)
           str_score_1         = 'sep:' + repr(norm_score1)
           str_score_2         = 'oct:' + repr(norm_score2)
           str_score_3         = 'dec:' + repr(norm_score3)
           i.append(str_score_1)
           i.append(str_score_2)
           i.append(str_score_3)
           normalized_data.append(i)


def write_op_file():

    f1 = open('/home/hadoop/timeseries/trends_scores_normalized.csv', 'w')
    header = "trend, type, sub_category, article_type, gender, score_1, score_2, score_3, color, fabric, pattern, sleeve, needlework, embellishment, style, score_nrm_1, score_nrm_2, score_nrm_3"
    f1.write(header)
    f1.write('\n')
    for item in normalized_data:
        item_str = str(item)
        item_str = item_str.replace('[', '')
        item_str = item_str.replace(']', '')
        item_str = item_str.replace("'", '')        
        f1.write(item_str)
        f1.write('\n')
    f1.close()
     
def main():
   normalize_scores()
   write_op_file()
   
# Boiler plate
if __name__ == '__main__':
    main()        