import re
import os
import sys
import csv
import json
import string
import nltk
from nltk.tokenize import word_tokenize
from nltk.corpus import stopwords
from nltk.stem.wordnet import WordNetLemmatizer
from gensim.models import Word2Vec
from glove import Corpus, Glove

def process_files():

        full_content = []
        file = open('/home/ubuntu/corpus/fashionfordummy.txt', 'r') 
        text_data = file.read()
        full_content          = data_Cleaning(text_data)
        return full_content
    
def data_Cleaning(text_data):

    # Remove unicode characters from the list
    data_clean                  = text_data.encode('ascii', 'ignore')
    
    # Remove new line characters
    content_no_new_line         = data_clean.decode().replace('\n', '')
    
    # Convert json  content to string
    str_content                 = str(content_no_new_line)
    
    # Convert data to lower case
    data                        = str_content.lower()   
        
    # Split the data to sentences on  '.'
    sentences                   = data.split('.')
    
    full_content                = []
    # Complete preprocessing to clean the data
    for num,line in enumerate(sentences):
        tokenized_docs               = []
        tokenized_docs              = nltk.word_tokenize(line)
        
        # Remove punctuations
        tokenized_docs_no_punctuation   = [] 
        translator                      = str.maketrans({key: '' for key in string.punctuation})
        tokenized_docs_no_punctuation   = [token.translate(translator) for token in tokenized_docs]
        
        # To remove all English stopwords
        tokenized_docs_no_stopwords  = []
        stop_words                   = set(stopwords.words('english'))
        tokenized_docs_no_stopwords  = [token for token in tokenized_docs_no_punctuation if not token in stop_words]
        
        # To remove English stopwords using an additional list
        my_stopword_list = set(['a','able','about','above','according','accordingly','across','actually','after','afterwards','again','against','aint','all','allow','allows','almost','alone','along','already','also','although','always','am','among','amongst','an','and','another','any','anybody','anyhow','anyone','anything','anyway','anyways','anywhere','apart','appear','appreciate','appropriate','are','arent','around','as','aside','ask','asking','associated','at','available','away','awfully','b','be','became','because','become','becomes','becoming','been','before','beforehand','behind','being','believe','below','beside','besides','best','better','between','beyond','both','brief','browser','but','by','c','came','can','cannot','cant','cause','causes','certain','certainly','changes','clearly','cmon','co','com','come','comes','concerning','consequently','consider','considering','contain','containing','contains','corresponding','complete','content','could','couldnt','course','cs','currently','d','definitely','described','despite','did','didnt','different','do','document','does','doesnt','doing','done','dont','down','downwards','during','e','each','edu','eg','eight','either','else','elsewhere','enough','entirely','especially','et','etc','even','ever','every','everybody','everyone','everything','everywhere','ex','exactly','example','except','f','far','few','fifth','first','five','followed','following','follows','for','former','formerly','forth','four','from','function','further','furthermore','g','generously', 'get','gets','getting','given','gives','go','goes','going','gone','got','gotten','greetings','h','had','hadnt','happens','hardly','has','hasnt','have','havent','having','he','hed','hell','hello','help','hence','her','here','hereafter','hereby','herein','heres','hereupon','hers','herself','hes','hi','him','himself','his','hither','hopefully','how','howbeit','however','hows','http','https','i','id','ie','if','ignored','ill','im','immediate', 'immediately','in','inasmuch','inc','indeed','indicate','indicated','indicates','inner','insofar','instead','into','inward','init','is','isnt','it','itd','itll','its','itself','ive','j','js','javascript','just','k','keep','keeps','kept','know','known','knows','knew','l','last','lately','later','latter','latterly','least','less','lest','let','lets','like','liked','likely','little','location','look','looking','looks','ltd','m','mainly','many','may','maybe','me','mean','meanwhile','merely','might','more','moreover','most','mostly','much','must','mustnt','my','myself','n','name','namely','nd','near','nearly','necessary','need','needs','neither','never','nevertheless','new','next','nine','no','nobody','non','none','noone','nor','normally','not','nothing','novel','now','nowhere','o','obviously','object','of','off','often','oh','ok','okay','old','on','once','one','ones','only','onto','or','other','others','otherwise','ought','our','ours','ourselves','out','outside','over','overall','own','p','particular','particularly','per','perfect','perhaps','photo','placed','please','plus','popular','possible','presumably','probably','provides','q','que','quite','qv','r','rather','rd','re','really','reasonably','regarding','regardless','regards','relatively','respectively','rewardstyle','right','s','said','same','saw','say','saying','says','script','second','secondly','see','seeing','seem','seemed','seeming','seems','seen','self','selves','sensible','sent','serious','seriously','seven','several','shall','she','should','shouldnt','since','six','so','some','somebody','somehow','someone','something','sometime','sometimes','somewhat','somewhere','soon','sorry','specified','specify','specifying','src','still','stp','sub','such','sup','sure','t','take','taken','tell','tends','th','than','thank','thanks','thanx','that','thats','the','their','theirs','them','themselves','then','thence','there','thereafter','thereby','therefore','therein','theres','thereupon','these','they','theyd','theyll','theyre','theyve','think','third','this','thorough','thoroughly','those','though','thought','three','through','throughout','thru','thus','to','together','too','took','toward','towards','tried','tries','truly','try','trying','ts','twice','two','u','un','under','unfortunately','unless','unlikely','until','unto','up','upon','us','use','used','useful','uses','using','usually','value','various','very','via','viz','vs','w','want','wants','was','wasnt','way','we','wed','welcome','well','went','were','werent','weve','what','whatever','whats','when','whence','whenever','where','whereafter','whereas','whereby','wherein','wheres','whereupon','wherever','whether','which','while','whither','who','whoever','whole','whom','whos','whose','why','will','willing','wish','with','within','without','wonder','wont','would','wouldnt','var','x','y','yes','yet','you','youd','youll','your','youre','yours','yourself','yourselves','youve','z','zero'])
        filtered_data    = []
        filtered_data    = [token for token in tokenized_docs_no_stopwords if not token in my_stopword_list]
        if len(filtered_data) > 0:
                # Lemmatizing
                wordnet = WordNetLemmatizer()
                clean_data = []
                # Here verbs are changed to present tense and plurals are changed to singular
                for word in filtered_data:
                        if word != '' and word.isdigit() ==0:
                                word     = wordnet.lemmatize(word, 'v')
                                new_word = wordnet.lemmatize(word)
                                clean_data.append(new_word)
                full_content.append(clean_data)
    
    return full_content
       
def parse_Word2Vec(full_content):
    corpus = Corpus()
    corpus.fit(full_content, window=10)
    glove = Glove(no_components=100, learning_rate=0.05)
    glove.fit(corpus.matrix, epochs=30, no_threads=4, verbose=True)
    glove.add_dictionary(corpus.dictionary)
    
    # Open file to write the results
    f2 = open('/home/ubuntu/corpus/results.txt', 'w')
    
    # Loop through all the article types in the file
    with open('/home/ubuntu/corpus/article_types.csv', 'r') as f:
        reader = csv.reader(f,delimiter = "\t")
        for row in reader:
                article_type                  = row[0]
                translator                      = str.maketrans({key: '' for key in string.punctuation})
                article_type_no_punctuation   = article_type.translate(translator)
                wordnet                       = WordNetLemmatizer()
                article_type_clean            = wordnet.lemmatize(article_type_no_punctuation)
                try:                        
                        match           = glove.most_similar(article_type_clean,number=10)
                        matched_item    = match[0][0]                        
                        print(article_type_clean + ' -> ' + str(matched_item))
                        f2.write(article_type + '\n')
                        f2.write(str(matched_item + '\n'))
                except:
                        pass
                        print('failed for: ' + article_type)
    f2.close()
    
def main():
   full_content = process_files()
   parse_Word2Vec(full_content)
   
# Boiler plate
if __name__ == '__main__':
 main()   