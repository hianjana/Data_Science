import csv
import codecs

class RefinementOfTrends(object):

##############################################################################################################
#
# Initialize all the lists
#
############################################################################################################## 

   def __init__(self):
        self.trends         = []
        self.scores         = []
        self.articletypes   = []
        self.refined_trends = []  

##############################################################################################################
#
# Load the clean input file: clean_trends.csv and lookup files: article_types.csv, fashion_taxonomy.csv
#
##############################################################################################################

   def Load_Input(self):

     with codecs.open('/home/ubuntu/cleaning/output/cleansed_trends.csv', 'r', encoding='utf-8') as csvfile:
        csv_reader = csv.reader(csvfile, delimiter='\t')
        for trend,score in csv_reader:
              self.trends.append(trend)
              self.scores.append(score)
     csvfile.close()
     
     with codecs.open('/home/ubuntu/cleaning/lookup/article_types.csv', 'r', encoding='utf-8') as csvfile:
        csv_reader = csv.reader(csvfile, delimiter='\t')
        for subcategory,articletype,gender in csv_reader:
              self.articletypes.append(subcategory)
              self.articletypes.append(articletype)
     csvfile.close() 
     
     with codecs.open('/home/ubuntu/cleaning/lookup/fashion_taxonomy.csv', 'r', encoding='utf-8') as csvfile:
        csv_reader = csv.reader(csvfile, delimiter='\t')
        for product,subcategory,gender in csv_reader:
              self.articletypes.append(product)
     csvfile.close()      
     
     # To remove duplicates
     self.articletypes = set(self.articletypes)
     self.articletypes = list(self.articletypes)
     
     # Sort the list on descending order by length of the word
     self.articletypes.sort(key=len, reverse=True)

##############################################################################################################
#
# Refine the trends by removing anything which is appearing after a matching trend. 
# For example: If the trend is 'red coat options' and 'coat' is identified as an article_type, subcategory 
#              or product, then only 'red coat' is extracted and anything appearing after 'coat' is ignored.
#
##############################################################################################################

   def RefineTrends(self):
     
     for trend in self.trends:
         trend_refined  = trend
         for article in self.articletypes:
            len_found = trend.rfind(article)           
            if len_found >= 0:
               len_of_article = len(article)
               len_to_subs    = len_found + len_of_article
               trend_refined  = trend[:len_to_subs]
               break
         self.refined_trends.append(trend_refined)  
               
##############################################################################################################
#
# Write the refined trends into a tab delimited output file: refined_trends.csv
#
##############################################################################################################

   def WriteFile(self):
        trends_scores = zip(self.refined_trends, self.scores)        
        with open('/home/ubuntu/cleaning/output/refined_trends.csv', 'wt') as f:
                dw = csv.writer(f, delimiter='\t')
                for row in trends_scores:
                       dw.writerow(row)
        f.close()

##############################################################################################################
#
# Main function which will call all the sub functions
#
##############################################################################################################

def main():
    obj_refinement = RefinementOfTrends()
    obj_refinement.Load_Input()
    obj_refinement.RefineTrends()
    obj_refinement.WriteFile()
    
# Boiler plate
if __name__ == '__main__':
 main()    