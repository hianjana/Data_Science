import csv
import codecs
import inflection
import nltk
from nltk.tokenize import word_tokenize


class SplittingOfTrends(object):

##############################################################################################################
#
# Initialize all the lists
#
##############################################################################################################    

        def __init__(self):
                self.input_trends                  = []
                self.input_scores                  = []
                self.article_type_list             = []     
                self.mult_trends                   = []
                self.mult_scores                   = []
                self.mult_count                    = []
    
##############################################################################################################
#
# Load the input file : refined_trends.csv and lookup file: article_types.csv
#
##############################################################################################################

        def Load_Input(self):
                with codecs.open('/home/ubuntu/cleaning/output/refined_trends.csv', 'r', encoding='utf-8') as csvfile:
                        csv_reader = csv.reader(csvfile, delimiter='\t')
                        for row in csv_reader:
                                trend        = row[0]
                                score        = row[1]
                                self.input_trends.append(trend)
                                self.input_scores.append(score)
                csvfile.close()

                with open('/home/ubuntu/cleaning/lookup/article_types.csv', 'r', encoding='utf-8') as csvfile:
                        csv_reader = csv.reader(csvfile, delimiter='\t')
                        for row in csv_reader:
                                sub_category = row[0]
                                article_type = row[1]
                                self.article_type_list.append(sub_category)
                                self.article_type_list.append(article_type)
                csvfile.close()       

                # To remove duplicates
                self.article_type_list = set(self.article_type_list)
                self.article_type_list = list(self.article_type_list)
                # Remove 'denim' from list as an exception
                self.article_type_list.remove('denim')

##############################################################################################################
#
# Check if any trend has more than one article type or sub-category associated with it
#
##############################################################################################################

        def ProcessTrends(self):
                for trend in self.input_trends:
                        no_of_matches        = 0    
                        # To retrieve the corresponding score
                        pos_trend            = self.input_trends.index(trend)
                        matching_score       = self.input_scores[pos_trend]   
                        if int(float(matching_score)) < 1000:
                                # Tokenize the trend
                                tokenized_trends     = []
                                tokenized_trends     = nltk.word_tokenize(trend)    
                                singular_trends      = [inflection.singularize(each) for each in tokenized_trends]
                                for each in singular_trends:
                                        trend_token = ' ' + each + ' '
                                        for article in self.article_type_list:
                                                singular_article = inflection.singularize(article)
                                                singular_article = ' ' + singular_article +  ' '
                                                len_found        = trend_token.find(singular_article)
                                                if len_found >= 0:
                                                        no_of_matches = no_of_matches + 1
                        if no_of_matches > 1:
                                self.mult_trends.append(trend)
                                self.mult_scores.append(matching_score)
                                self.mult_count.append(no_of_matches)

##############################################################################################################
#
# Write trends which are identified to have multiple trends into an output file
#
##############################################################################################################

        def WriteOutput(self):
                
                output_trends = zip(self.mult_trends, self.mult_scores, self.mult_count)
                with open('/home/ubuntu/cleaning/output/multiple_trends.csv', 'wt') as f:
                        dw = csv.writer(f, delimiter='\t')
                        for row in output_trends:
                                dw.writerow(row)
                f.close()
                                
##############################################################################################################
#
# Main function which will call all the sub functions
#
##############################################################################################################

def main():
        obj_split = SplittingOfTrends()
        obj_split.Load_Input()
        obj_split.ProcessTrends()
        obj_split.WriteOutput()
    
# Boiler plate
if __name__ == '__main__':
        main()  