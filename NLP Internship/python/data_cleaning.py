import csv
import codecs
import glob
import os
from unidecode import unidecode

trends_3_words                  = []
trends_4_words                  = []
trends_5_words                  = []
trends_above_5_words            = []
trends_3_words_clean            = []
trends_4_words_clean            = []
trends_5_words_clean            = []
trends_above_5_words_clean      = []

##############################################################################################################
#
# Delete existing output files
#
##############################################################################################################

directory='/home/ubuntu/cleaning/output'
os.chdir(directory)
files=glob.glob('*.csv')
for filename in files:
    os.unlink(filename)
    
##############################################################################################################
#
# Loading stop words : 1) General English stopwords 2) Makeup related stopwords
#
##############################################################################################################

# Loading stop words
stop_word_file = '/home/ubuntu/cleaning/lookup/CompleteStopFile.txt'
stop_word_list = []
for word in open(stop_word_file):
        word = word.replace('\n', '')
        word = ' ' + word + ' '
        word = word.lower()
        stop_word_list.append(word)

# Append unicode character list to stopword list
stop_word_list.append('u2026')
stop_word_list.append('u2002')
stop_word_list.append('u2003')
stop_word_list.append('u2004')
stop_word_list.append('u2005')
stop_word_list.append('u2006')
stop_word_list.append('u2010')
stop_word_list.append('u2011')
stop_word_list.append('u2012')
stop_word_list.append('u2013')
stop_word_list.append('u2014')
stop_word_list.append('u2015')
stop_word_list.append('u2018')
stop_word_list.append('u2019')
stop_word_list.append('u201a')
stop_word_list.append('u201b')
stop_word_list.append('u201c')
stop_word_list.append('u201d')
stop_word_list.append('u201e')
stop_word_list.append('u201f')

# Sort the stopword list on length of the entry in descending order
stop_word_list.sort(key=len, reverse=True)


# Loading stopwords related to makeup
makeup_stop_word_file = '/home/ubuntu/cleaning/lookup/Makeup_StopFile.txt'
makeup_stop_word_list = []
for word in open(makeup_stop_word_file):
        word = word.replace('\n', '')
        word = ' ' + word + ' '
        word = word.lower()
        makeup_stop_word_list.append(word)
makeup_stop_word_list.sort(key=len, reverse=True)

##############################################################################################################
#
# Stopword list creation ends here
#
##############################################################################################################

##############################################################################################################
#
# Load the input file : ranked_final.csv
#
##############################################################################################################

with codecs.open('/home/ubuntu/cleaning/input/ranked_final.csv', 'r', encoding='utf-8') as csvfile:
        csv_reader = csv.reader(csvfile, delimiter='\t')
        for row in csv_reader:
                trend        = row[0]
                trend_length = len(trend.split())
                if trend_length <= 3:
                        trends_3_words.append(row)
                elif trend_length == 4:
                        trends_4_words.append(row)        
                elif trend_length == 5:
                        trends_5_words.append(row)
                else:
                        trends_above_5_words.append(row)
csvfile.close()

##############################################################################################################
#
# Input file load ends here
#
##############################################################################################################

##############################################################################################################
#                                 Cleansing starts here
##############################################################################################################
#
# Load all makeup related trends to a seperate file : makeup_trends.csv
# All other trends are cleansed and loaded to arrays: 
#               trends_3_words_clean, trends_4_words_clean, trends_5_words_clean, trends_above_5_words_clean
#
##############################################################################################################
        
# Create a file which will hold all those trends which are related to makeup
f1 = open('/home/ubuntu/cleaning/output/makeup_trends.csv', 'w')
header = "trend, score"
f1.write(header)
f1.write('\n')

for row in trends_3_words:
        trend_old   = row[0]  
        trend = ' ' + trend_old +  ' '        
        makeup_flag = 'N'
        for word in makeup_stop_word_list:
                if word in trend and makeup_flag == 'N':
                        makeup_flag = 'Y'
                        str_row = str(row)
                        str_row = str_row.replace('[','')
                        str_row = str_row.replace(']','')
                        str_row = str_row.replace("'",'')
                        f1.write(str_row)
                        f1.write('\n')
        if makeup_flag == 'N':
                for stop_word in stop_word_list:
                        if stop_word in trend:
                                trend = trend.replace(stop_word, ' ')
                # Fixing plurals 
                trend                = trend.replace('suits', 'suit')
                trend                = trend.replace('dresses', 'dress')
                trend                = trend.replace('skirts', 'skirt')
                trend                = trend.replace('hats', 'hat')
                trend                = trend.replace('coats', 'coat')
                trend                = trend.replace('sweaters', 'sweater')
                trend                = trend.replace('clutches', 'clutch')
                trend                = trend.replace('cardigans', 'cardigan')
                trend                = trend.replace('jackets', 'jacket')
                trend                = trend.replace('tops', 'top')
                trend                = trend.replace('sunglasses', 'sunglass')
                trend                = trend.replace('scarves', 'scarf')
                trend                = trend.replace('shoe', 'shoes')
                trend                = trend.replace('shoess', 'shoes')
                trend                = trend.replace('sandal', 'sandals')
                trend                = trend.replace('sandalss', 'sandals')
                trend                = trend.replace('wedge', 'wedges')
                trend                = trend.replace('wedgess', 'wedges')
                trend                = trend.replace('glove', 'gloves')
                trend                = trend.replace('glovess', 'gloves')
                trend                = trend.replace('espadrille', 'espadrilles')
                trend                = trend.replace('espadrilless', 'espadrilles')
                trend                = trend.replace('sleeves', 'sleeve')
                trend                = trend.replace('bags', 'bag')
                trend                = trend.replace('sleeves', 'sleeve')
                trend                = trend.replace('tshirt', 't-shirt')
                trend                = trend.replace('cardigans', 'cardigan')
                trend                = trend.replace('puffers', 'puffer')
                trend                = trend.replace('parkas', 'parka')
                trend                = trend.replace('trench coats', 'trench coat')
                trend                = trend.replace('kimonos', 'kimono')
                trend                = trend.replace('waistcoats', 'waistcoat')
                trend                = trend.replace('blazers', 'blazer')
                trend                = trend.replace('jumpsuits', 'jumpsuit')
                trend                = trend.replace('bikinis', 'bikini')
                trend                = trend.replace('shirts', 'shirt')
                trend                = trend.replace('blouses', 'blouse')
                trend                = trend.replace('t-shirts', 't-shirt')
                trend                = trend.replace('tee', 't-shirt')
                trend                = trend.replace('tees', 't-shirt')
                trend                = trend.replace('trouser', 'trousers')
                trend                = trend.replace('trouserss', 'trousers')
                trend                = trend.replace('culotte', 'culottes')
                trend                = trend.replace('culottess', 'culottes')
                trend                = trend.replace('jogger', 'joggers')
                trend                = trend.replace('joggerss', 'joggers')
                trend                = trend.replace('palazzos', 'palazzos')
                trend                = trend.replace('legging', 'leggings')
                trend                = trend.replace('leggingss', 'leggings')
                trend                = trend.replace('jean', 'jeans')
                trend                = trend.replace('jeanss', 'jeans')
                trend                = trend.replace('jegging', 'jeggings')
                trend                = trend.replace('jeggingss', 'jeggings')
                trend                = trend.replace('boot', 'boots')
                trend                = trend.replace('bootss', 'boots')
                trend                = trend.replace('sneaker', 'sneakers')
                trend                = trend.replace('sneakerss', 'sneakers')
                trend                = trend.replace('handbags', 'handbag')
                trend                = trend.replace('beanies', 'beanie')
                trend                = trend.replace('jewelleries', 'jewellery')
                trend                = trend.replace('belts', 'belt')
                trend                = trend.replace('sunnies', 'sunglass')
                trend                = trend.replace('bracelet', 'bracelets')
                trend                = trend.replace('braceletss', 'bracelets')
                trend                = trend.replace('necklace', 'necklaces')
                trend                = trend.replace('necklacess', 'necklaces')
                trend                = trend.replace('anklet', 'anklets')
                trend                = trend.replace('ankletss', 'anklets')
                trend                = trend.replace('choker', 'chokers')
                trend                = trend.replace('chokerss', 'chokers')
                trend                = trend.replace('earring', 'earrings')
                trend                = trend.replace('earringss', 'earrings')
                trend                = trend.replace('capri', 'capris')
                trend                = trend.replace('capriss', 'capris')
                trend                = trend.replace('purses', 'purse')
                trend                = trend.replace('capriss', 'capris')
                trend                = trend.replace('capriss', 'capris')
                trend                = trend.replace('frocks', 'frock')
                trend                = trend.replace('gowns', 'gown')
                trend                = trend.replace('pant', 'pants')
                trend                = trend.replace('pantss', 'pants')
                trend                = trend.replace('tshirts', 't-shirt')
                trend                = trend.replace('tops', 'top')
                trend                = trend.replace('wallets', 'wallet')
                trend                = trend.replace('tops', 'top')
                trend                = trend.replace('booties', 'boots')
                trend                = trend.replace('mule', 'mules')
                trend                = trend.replace('muless', 'mules')
                trend                = trend.replace('watches', 'watch')
                trend                = trend.replace('bathing suits', 'bathing suit')
                trend                = trend.replace('accessories', 'accessory')          
                trend                = trend.replace('loafer', 'loafers')
                trend                = trend.replace('loaferss', 'loafers')
                trend                = trend.replace('pantsuits', 'pantsuit')
                trend                = trend.replace('pant suit', 'pantsuit')
                trend                = trend.replace('retrostyle', 'retro style')
                trend                = trend.replace('retroinspired', 'retro inspired')
                trend                = trend.replace('skorts', 'skort')
                trend                = trend.replace('chino', 'chinos')
                trend                = trend.replace('chinoss', 'chinos')
                trend                = trend.replace('slingbag', 'sling bag')
                # Plural fix ends here
                # To remove unicode characters
                ##trend                = unidecode(trend)
                trends_3_words_to_go = trend_old + ',' + trend + ',' + row[1]
                trends_3_words_clean.append(trends_3_words_to_go)                
                        
for row in trends_4_words:
        trend_old = row[0]
        trend = ' ' + trend_old +  ' '        
        makeup_flag = 'N'
        for word in makeup_stop_word_list:
                if word in trend and makeup_flag == 'N':
                        makeup_flag = 'Y'
                        str_row = str(row)
                        str_row = str_row.replace('[','')
                        str_row = str_row.replace(']','')
                        str_row = str_row.replace("'",'')
                        f1.write(str_row)
                        f1.write('\n')
        if makeup_flag == 'N':
                for stop_word in stop_word_list:
                        if stop_word in trend:
                                trend = trend.replace(stop_word, ' ')
                                
                # Fixing plurals 
                trend                = trend.replace('suits', 'suit')
                trend                = trend.replace('dresses', 'dress')
                trend                = trend.replace('skirts', 'skirt')
                trend                = trend.replace('hats', 'hat')
                trend                = trend.replace('coats', 'coat')
                trend                = trend.replace('sweaters', 'sweater')
                trend                = trend.replace('clutches', 'clutch')
                trend                = trend.replace('cardigans', 'cardigan')
                trend                = trend.replace('jackets', 'jacket')
                trend                = trend.replace('tops', 'top')
                trend                = trend.replace('sunglasses', 'sunglass')
                trend                = trend.replace('scarves', 'scarf')
                trend                = trend.replace('shoe', 'shoes')
                trend                = trend.replace('shoess', 'shoes')
                trend                = trend.replace('sandal', 'sandals')
                trend                = trend.replace('sandalss', 'sandals')
                trend                = trend.replace('wedge', 'wedges')
                trend                = trend.replace('wedgess', 'wedges')
                trend                = trend.replace('glove', 'gloves')
                trend                = trend.replace('glovess', 'gloves')
                trend                = trend.replace('espadrille', 'espadrilles')
                trend                = trend.replace('espadrilless', 'espadrilles')
                trend                = trend.replace('sleeves', 'sleeve')
                trend                = trend.replace('bags', 'bag')
                trend                = trend.replace('sleeves', 'sleeve')
                trend                = trend.replace('tshirt', 't-shirt')
                trend                = trend.replace('cardigans', 'cardigan')
                trend                = trend.replace('puffers', 'puffer')
                trend                = trend.replace('parkas', 'parka')
                trend                = trend.replace('trench coats', 'trench coat')
                trend                = trend.replace('kimonos', 'kimono')
                trend                = trend.replace('waistcoats', 'waistcoat')
                trend                = trend.replace('blazers', 'blazer')
                trend                = trend.replace('jumpsuits', 'jumpsuit')
                trend                = trend.replace('bikinis', 'bikini')
                trend                = trend.replace('shirts', 'shirt')
                trend                = trend.replace('blouses', 'blouse')
                trend                = trend.replace('t-shirts', 't-shirt')
                trend                = trend.replace('tee', 't-shirt')
                trend                = trend.replace('tees', 't-shirt')
                trend                = trend.replace('trouser', 'trousers')
                trend                = trend.replace('trouserss', 'trousers')
                trend                = trend.replace('culotte', 'culottes')
                trend                = trend.replace('culottess', 'culottes')
                trend                = trend.replace('jogger', 'joggers')
                trend                = trend.replace('joggerss', 'joggers')
                trend                = trend.replace('palazzos', 'palazzos')
                trend                = trend.replace('legging', 'leggings')
                trend                = trend.replace('leggingss', 'leggings')
                trend                = trend.replace('jean', 'jeans')
                trend                = trend.replace('jeanss', 'jeans')
                trend                = trend.replace('jegging', 'jeggings')
                trend                = trend.replace('jeggingss', 'jeggings')
                trend                = trend.replace('boot', 'boots')
                trend                = trend.replace('bootss', 'boots')
                trend                = trend.replace('sneaker', 'sneakers')
                trend                = trend.replace('sneakerss', 'sneakers')
                trend                = trend.replace('handbags', 'handbag')
                trend                = trend.replace('beanies', 'beanie')
                trend                = trend.replace('jewelleries', 'jewellery')
                trend                = trend.replace('belts', 'belt')
                trend                = trend.replace('sunnies', 'sunglass')
                trend                = trend.replace('bracelet', 'bracelets')
                trend                = trend.replace('braceletss', 'bracelets')
                trend                = trend.replace('necklace', 'necklaces')
                trend                = trend.replace('necklacess', 'necklaces')
                trend                = trend.replace('anklet', 'anklets')
                trend                = trend.replace('ankletss', 'anklets')
                trend                = trend.replace('choker', 'chokers')
                trend                = trend.replace('chokerss', 'chokers')
                trend                = trend.replace('earring', 'earrings')
                trend                = trend.replace('earringss', 'earrings')
                trend                = trend.replace('capri', 'capris')
                trend                = trend.replace('capriss', 'capris')
                trend                = trend.replace('purses', 'purse')
                trend                = trend.replace('capriss', 'capris')
                trend                = trend.replace('capriss', 'capris')
                trend                = trend.replace('frocks', 'frock')
                trend                = trend.replace('gowns', 'gown')
                trend                = trend.replace('pant', 'pants')
                trend                = trend.replace('pantss', 'pants')
                trend                = trend.replace('tshirts', 't-shirt')
                trend                = trend.replace('tops', 'top')
                trend                = trend.replace('wallets', 'wallet')
                trend                = trend.replace('tops', 'top')
                trend                = trend.replace('booties', 'boots')
                trend                = trend.replace('mule', 'mules')
                trend                = trend.replace('muless', 'mules')
                trend                = trend.replace('watches', 'watch')
                trend                = trend.replace('bathing suits', 'bathing suit')
                trend                = trend.replace('accessories', 'accessory')  
                trend                = trend.replace('loafer', 'loafers')
                trend                = trend.replace('loaferss', 'loafers')  
                trend                = trend.replace('pantsuits', 'pantsuit')
                trend                = trend.replace('pant suit', 'pantsuit')
                trend                = trend.replace('retrostyle', 'retro style')
                trend                = trend.replace('retroinspired', 'retro inspired')  
                trend                = trend.replace('skorts', 'skort')   
                trend                = trend.replace('chino', 'chinos')
                trend                = trend.replace('chinoss', 'chinos')    
                trend                = trend.replace('slingbag', 'sling bag')
                # Plural fix ends here              
                trends_4_words_to_go = trend_old + ',' + trend + ',' + row[1]
                trends_4_words_clean.append(trends_4_words_to_go) 

for row in trends_5_words:
        trend_old = row[0]
        trend = ' ' + trend_old +  ' '        
        makeup_flag = 'N'
        for word in makeup_stop_word_list:
                if word in trend and makeup_flag == 'N':
                        makeup_flag = 'Y'
                        str_row = str(row)
                        str_row = str_row.replace('[','')
                        str_row = str_row.replace(']','')
                        str_row = str_row.replace("'",'')
                        f1.write(str_row)
                        f1.write('\n')
        if makeup_flag == 'N':
                for stop_word in stop_word_list:
                        if stop_word in trend:
                                trend = trend.replace(stop_word, ' ')
                
                # Fixing plurals 
                trend                = trend.replace('suits', 'suit')
                trend                = trend.replace('dresses', 'dress')
                trend                = trend.replace('skirts', 'skirt')
                trend                = trend.replace('hats', 'hat')
                trend                = trend.replace('coats', 'coat')
                trend                = trend.replace('sweaters', 'sweater')
                trend                = trend.replace('clutches', 'clutch')
                trend                = trend.replace('cardigans', 'cardigan')
                trend                = trend.replace('jackets', 'jacket')
                trend                = trend.replace('tops', 'top')
                trend                = trend.replace('sunglasses', 'sunglass')
                trend                = trend.replace('scarves', 'scarf')
                trend                = trend.replace('shoe', 'shoes')
                trend                = trend.replace('shoess', 'shoes')
                trend                = trend.replace('sandal', 'sandals')
                trend                = trend.replace('sandalss', 'sandals')
                trend                = trend.replace('wedge', 'wedges')
                trend                = trend.replace('wedgess', 'wedges')
                trend                = trend.replace('glove', 'gloves')
                trend                = trend.replace('glovess', 'gloves')
                trend                = trend.replace('espadrille', 'espadrilles')
                trend                = trend.replace('espadrilless', 'espadrilles')
                trend                = trend.replace('sleeves', 'sleeve')
                trend                = trend.replace('bags', 'bag')
                trend                = trend.replace('sleeves', 'sleeve')  
                trend                = trend.replace('tshirt', 't-shirt')
                trend                = trend.replace('cardigans', 'cardigan')
                trend                = trend.replace('puffers', 'puffer')
                trend                = trend.replace('parkas', 'parka')
                trend                = trend.replace('trench coats', 'trench coat')
                trend                = trend.replace('kimonos', 'kimono')
                trend                = trend.replace('waistcoats', 'waistcoat')
                trend                = trend.replace('blazers', 'blazer')
                trend                = trend.replace('jumpsuits', 'jumpsuit')
                trend                = trend.replace('bikinis', 'bikini')
                trend                = trend.replace('shirts', 'shirt')
                trend                = trend.replace('blouses', 'blouse')
                trend                = trend.replace('t-shirts', 't-shirt')
                trend                = trend.replace('tee', 't-shirt')
                trend                = trend.replace('tees', 't-shirt')
                trend                = trend.replace('trouser', 'trousers')
                trend                = trend.replace('trouserss', 'trousers')
                trend                = trend.replace('culotte', 'culottes')
                trend                = trend.replace('culottess', 'culottes')
                trend                = trend.replace('jogger', 'joggers')
                trend                = trend.replace('joggerss', 'joggers')
                trend                = trend.replace('palazzos', 'palazzos')
                trend                = trend.replace('legging', 'leggings')
                trend                = trend.replace('leggingss', 'leggings')
                trend                = trend.replace('jean', 'jeans')
                trend                = trend.replace('jeanss', 'jeans')
                trend                = trend.replace('jegging', 'jeggings')
                trend                = trend.replace('jeggingss', 'jeggings')
                trend                = trend.replace('boot', 'boots')
                trend                = trend.replace('bootss', 'boots')
                trend                = trend.replace('sneaker', 'sneakers')
                trend                = trend.replace('sneakerss', 'sneakers')
                trend                = trend.replace('handbags', 'handbag')
                trend                = trend.replace('beanies', 'beanie')
                trend                = trend.replace('jewelleries', 'jewellery')
                trend                = trend.replace('belts', 'belt')
                trend                = trend.replace('sunnies', 'sunglass')
                trend                = trend.replace('bracelet', 'bracelets')
                trend                = trend.replace('braceletss', 'bracelets')
                trend                = trend.replace('necklace', 'necklaces')
                trend                = trend.replace('necklacess', 'necklaces')
                trend                = trend.replace('anklet', 'anklets')
                trend                = trend.replace('ankletss', 'anklets')
                trend                = trend.replace('choker', 'chokers')
                trend                = trend.replace('chokerss', 'chokers')
                trend                = trend.replace('earring', 'earrings')
                trend                = trend.replace('earringss', 'earrings')
                trend                = trend.replace('capri', 'capris')
                trend                = trend.replace('capriss', 'capris')
                trend                = trend.replace('purses', 'purse')
                trend                = trend.replace('capriss', 'capris')
                trend                = trend.replace('capriss', 'capris')
                trend                = trend.replace('frocks', 'frock')
                trend                = trend.replace('gowns', 'gown')
                trend                = trend.replace('pant', 'pants')
                trend                = trend.replace('pantss', 'pants')
                trend                = trend.replace('tshirts', 't-shirt')
                trend                = trend.replace('tops', 'top')
                trend                = trend.replace('wallets', 'wallet')
                trend                = trend.replace('tops', 'top')
                trend                = trend.replace('booties', 'boots')
                trend                = trend.replace('mule', 'mules')
                trend                = trend.replace('muless', 'mules')
                trend                = trend.replace('watches', 'watch')
                trend                = trend.replace('bathing suits', 'bathing suit')
                trend                = trend.replace('accessories', 'accessory')   
                trend                = trend.replace('loafer', 'loafers')
                trend                = trend.replace('loaferss', 'loafers')    
                trend                = trend.replace('pantsuits', 'pantsuit')
                trend                = trend.replace('pant suit', 'pantsuit')
                trend                = trend.replace('retrostyle', 'retro style')
                trend                = trend.replace('retroinspired', 'retro inspired')   
                trend                = trend.replace('skorts', 'skort')    
                trend                = trend.replace('chino', 'chinos')
                trend                = trend.replace('chinoss', 'chinos')   
                trend                = trend.replace('slingbag', 'sling bag')
                # Plural fix ends here              
                trends_5_words_to_go = trend_old + ',' + trend + ',' + row[1]
                trends_5_words_clean.append(trends_5_words_to_go)                         


for row in trends_above_5_words:
        trend_old = row[0]
        trend = ' ' + trend_old +  ' '        
        makeup_flag = 'N'
        for word in makeup_stop_word_list:
                if word in trend and makeup_flag == 'N':
                        makeup_flag = 'Y'
                        str_row = str(row)
                        str_row = str_row.replace('[','')
                        str_row = str_row.replace(']','')
                        str_row = str_row.replace("'",'')
                        f1.write(str_row)
                        f1.write('\n')
        if makeup_flag == 'N':
                for stop_word in stop_word_list:
                        if stop_word in trend:
                                trend = trend.replace(stop_word, ' ')
                                
                # Fixing plurals 
                trend                = trend.replace('suits', 'suit')
                trend                = trend.replace('dresses', 'dress')
                trend                = trend.replace('skirts', 'skirt')
                trend                = trend.replace('hats', 'hat')
                trend                = trend.replace('coats', 'coat')
                trend                = trend.replace('sweaters', 'sweater')
                trend                = trend.replace('clutches', 'clutch')
                trend                = trend.replace('cardigans', 'cardigan')
                trend                = trend.replace('jackets', 'jacket')
                trend                = trend.replace('tops', 'top')
                trend                = trend.replace('sunglasses', 'sunglass')
                trend                = trend.replace('scarves', 'scarf')
                trend                = trend.replace('shoe', 'shoes')
                trend                = trend.replace('shoess', 'shoes')
                trend                = trend.replace('sandal', 'sandals')
                trend                = trend.replace('sandalss', 'sandals')
                trend                = trend.replace('wedge', 'wedges')
                trend                = trend.replace('wedgess', 'wedges')
                trend                = trend.replace('glove', 'gloves')
                trend                = trend.replace('glovess', 'gloves')
                trend                = trend.replace('espadrille', 'espadrilles')
                trend                = trend.replace('espadrilless', 'espadrilles')
                trend                = trend.replace('sleeves', 'sleeve')
                trend                = trend.replace('bags', 'bag')
                trend                = trend.replace('sleeves', 'sleeve')
                trend                = trend.replace('tshirt', 't-shirt')
                trend                = trend.replace('cardigans', 'cardigan')
                trend                = trend.replace('puffers', 'puffer')
                trend                = trend.replace('parkas', 'parka')
                trend                = trend.replace('trench coats', 'trench coat')
                trend                = trend.replace('kimonos', 'kimono')
                trend                = trend.replace('waistcoats', 'waistcoat')
                trend                = trend.replace('blazers', 'blazer')
                trend                = trend.replace('jumpsuits', 'jumpsuit')
                trend                = trend.replace('bikinis', 'bikini')
                trend                = trend.replace('shirts', 'shirt')
                trend                = trend.replace('blouses', 'blouse')
                trend                = trend.replace('t-shirts', 't-shirt')
                trend                = trend.replace('tee', 't-shirt')
                trend                = trend.replace('tees', 't-shirt')
                trend                = trend.replace('trouser', 'trousers')
                trend                = trend.replace('trouserss', 'trousers')
                trend                = trend.replace('culotte', 'culottes')
                trend                = trend.replace('culottess', 'culottes')
                trend                = trend.replace('jogger', 'joggers')
                trend                = trend.replace('joggerss', 'joggers')
                trend                = trend.replace('palazzos', 'palazzos')
                trend                = trend.replace('legging', 'leggings')
                trend                = trend.replace('leggingss', 'leggings')
                trend                = trend.replace('jean', 'jeans')
                trend                = trend.replace('jeanss', 'jeans')
                trend                = trend.replace('jegging', 'jeggings')
                trend                = trend.replace('jeggingss', 'jeggings')
                trend                = trend.replace('boot', 'boots')
                trend                = trend.replace('bootss', 'boots')
                trend                = trend.replace('sneaker', 'sneakers')
                trend                = trend.replace('sneakerss', 'sneakers')
                trend                = trend.replace('handbags', 'handbag')
                trend                = trend.replace('beanies', 'beanie')
                trend                = trend.replace('jewelleries', 'jewellery')
                trend                = trend.replace('belts', 'belt')
                trend                = trend.replace('sunnies', 'sunglass')
                trend                = trend.replace('bracelet', 'bracelets')
                trend                = trend.replace('braceletss', 'bracelets')
                trend                = trend.replace('necklace', 'necklaces')
                trend                = trend.replace('necklacess', 'necklaces')
                trend                = trend.replace('anklet', 'anklets')
                trend                = trend.replace('ankletss', 'anklets')
                trend                = trend.replace('choker', 'chokers')
                trend                = trend.replace('chokerss', 'chokers')
                trend                = trend.replace('earring', 'earrings')
                trend                = trend.replace('earringss', 'earrings')
                trend                = trend.replace('capri', 'capris')
                trend                = trend.replace('capriss', 'capris')
                trend                = trend.replace('purses', 'purse')
                trend                = trend.replace('capriss', 'capris')
                trend                = trend.replace('capriss', 'capris')
                trend                = trend.replace('frocks', 'frock')
                trend                = trend.replace('gowns', 'gown')
                trend                = trend.replace('pant', 'pants')
                trend                = trend.replace('pantss', 'pants')
                trend                = trend.replace('tshirts', 't-shirt')
                trend                = trend.replace('tops', 'top')
                trend                = trend.replace('wallets', 'wallet')
                trend                = trend.replace('tops', 'top')
                trend                = trend.replace('booties', 'boots')
                trend                = trend.replace('mule', 'mules')
                trend                = trend.replace('muless', 'mules')
                trend                = trend.replace('watches', 'watch')
                trend                = trend.replace('bathing suits', 'bathing suit')
                trend                = trend.replace('accessories', 'accessory') 
                trend                = trend.replace('loafer', 'loafers')
                trend                = trend.replace('loaferss', 'loafers') 
                trend                = trend.replace('pantsuits', 'pantsuit')
                trend                = trend.replace('pant suit', 'pantsuit')
                trend                = trend.replace('retrostyle', 'retro style')
                trend                = trend.replace('retroinspired', 'retro inspired') 
                trend                = trend.replace('skorts', 'skort')   
                trend                = trend.replace('chino', 'chinos')
                trend                = trend.replace('chinoss', 'chinos')    
                trend                = trend.replace('slingbag', 'sling bag')
                # Plural fix ends here             
                trends_above_5_words_to_go = trend_old + ',' + trend + ',' + row[1]
                trends_above_5_words_clean.append(trends_above_5_words_to_go)                       

# Close the file which has captured trends related to makeup
f1.close()

##############################################################################################################
#                                 Cleansing ends here
##############################################################################################################

##############################################################################################################
#
# Writing all the cleansed trends into files starts here
#
##############################################################################################################

# Write all the trends with 3 words
f3 = open('/home/ubuntu/cleaning/output/trends_3_words.csv', 'w')
header = "orig_trend, clean_trend, score"
f3.write(header)
f3.write('\n')
for item in trends_3_words_clean:
     if str(item) != '':
        f3.write(str(item))
        f3.write('\n')
f3.close()

# Write all the trends with 4 words
f4 = open('//home/ubuntu/cleaning/output/trends_4_words.csv', 'w')
header = "orig_trend, clean_trend, score"
f4.write(header)
f4.write('\n')
for item in trends_4_words_clean:
    if str(item) != '':
        f4.write(str(item))
        f4.write('\n')
f4.close()

# Write all the trends with 5 words
f5 = open('/home/ubuntu/cleaning/output/trends_5_words.csv', 'w')
header = "orig_trend, clean_trend, score"
f5.write(header)
f5.write('\n')
for item in trends_5_words_clean:
    if str(item) != '':
        f5.write(str(item))
        f5.write('\n')
f5.close()

# Write all the trends with more than 5 words
f6 = open('/home/ubuntu/cleaning/output/trends_above_5_words_clean.csv', 'w')
header = "orig_trend, clean_trend, score"
f6.write(header)
f6.write('\n')
for item in trends_above_5_words_clean:
        f6.write(str(item))
        f6.write('\n')
f6.close()

##############################################################################################################
#
# Writing into files ends here
#
##############################################################################################################