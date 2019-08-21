import sys
import csv
import string
import codecs

trends                         = []
types                   = []
sub_categories          = []
article_types           = []
genders                 = []
scores                  = []
trends_tags_added         = []
colors                         = []
colors_sorted                = []
colors_matched                 = []
fabrics                 = []
fabrics_sorted                = []
fabrics_matched         = []
patterns                = []
patterns_sorted                = []
patterns_matched         = []
sleeves                        = []
sleeves_sorted                = []
sleeves_matched         = []
needleworks                = []
needleworks_sorted        = []
needleworks_matched         = []
embellishments                = []
embellishments_sorted        = []
embellishments_matched         = []
styles                        = []
styles_sorted                = []
styles_matched                 = []

# To load all the colors and fabrics from tags_taxonomy.csv into an array
def TagsArray():       
        
        with open('tags_taxonomy.csv','r') as f:
                reader=csv.reader(f,delimiter='\t')
                for item,type in reader:
                        if type == 'color':
                                colors.append(item.strip().lower())
                        elif type == 'fabric':
                                fabrics.append(item.strip().lower())
                        elif type == 'pattern':
                                patterns.append(item.strip().lower())
                        elif type == 'sleeve':
                                sleeves.append(item.strip().lower())
                        elif type == 'needlework':
                                needleworks.append(item.strip().lower())
                        elif type == 'embellishment':
                                embellishments.append(item.strip().lower())
                        elif type == 'style':
                                styles.append(item.strip().lower())                                
                                
# To read the input file  
def ReadFile():

        with codecs.open('trends_scored.csv','r', encoding = 'utf-8') as f:
                next(f) # skip headings
                reader=csv.reader(f,delimiter='\t')
                for trend,type,sub_category,article_type,gender,score in reader:
                        trend_clean = trend.replace('  ', ' ').lower()
                        trends.append(trend_clean)
                        types.append(type)
                        sub_categories.append(sub_category)
                        article_types.append(article_type)
                        genders.append(gender)
                        scores.append(score)

# To extract the color present in the trend
def Color_Extraction():
        
        colors_sorted = sorted(colors, key=len, reverse=True)
        for trend in trends:
                trend_new = ' ' + trend + ' '
                color_found = ''
                for color in colors_sorted:
                    color_new = ' ' + color + ' '
                    if trend_new.find(color_new) != -1:
                            color_found = color
                            break
                colors_matched.append(color_found)                          

# To extract the fabric present in the trend
def Fabric_Extraction():
        
        fabrics_sorted = sorted(fabrics, key=len, reverse=True)
        for trend in trends:
                trend_new = ' ' + trend + ' '
                fabric_found = ''
                for fabric in fabrics_sorted:
                    fabric_new = ' ' + fabric + ' '
                    if trend_new.find(fabric_new) != -1:
                            fabric_found = fabric
                            break
                fabrics_matched.append(fabric_found)  
        
# To extract the pattern present in the trend
def Pattern_Extraction():
        
        patterns_sorted = sorted(patterns, key=len, reverse=True)
        for trend in trends:
                trend_new = ' ' + trend + ' '
                pattern_found = ''
                for pattern in patterns_sorted:
                    pattern_new = ' ' + pattern + ' '
                    if trend_new.find(pattern_new) != -1:
                            pattern_found = pattern
                            break
                patterns_matched.append(pattern_found)  
        
# To extract the sleeve present in the trend
def Sleeve_Extraction():
        
        sleeves_sorted = sorted(sleeves, key=len, reverse=True)
        for trend in trends:
                trend_new = ' ' + trend + ' '
                sleeve_found = ''
                for sleeve in sleeves_sorted:
                    sleeve_new = ' ' + sleeve + ' '
                    if trend_new.find(sleeve_new) != -1:
                            sleeve_found = sleeve
                            break
                sleeves_matched.append(sleeve_found)  
        
# To extract the needlework present in the trend
def Needlework_Extraction():
        
        needleworks_sorted = sorted(needleworks, key=len, reverse=True)
        for trend in trends:
                trend_new = ' ' + trend + ' '
                needlework_found = ''
                for needlework in needleworks_sorted:
                    needlework_new = ' ' + needlework + ' '
                    if trend_new.find(needlework_new) != -1:
                            needlework_found = needlework
                            break
                needleworks_matched.append(needlework_found)  
        trends_tags_added = zip(trends, colors_matched, fabrics_matched, patterns_matched, sleeves_matched, needleworks_matched)        

# To extract the embellishment present in the trend
def Embellishment_Extraction():
        
        embellishments_sorted = sorted(embellishments, key=len, reverse=True)
        for trend in trends:
                trend_new = ' ' + trend + ' '
                embellishment_found = ''
                for embellishment in embellishments_sorted:
                    embellishment_new = ' ' + embellishment + ' '
                    if trend_new.find(embellishment_new) != -1:
                            embellishment_found = embellishment
                            break
                embellishments_matched.append(embellishment_found)          

# To extract the style present in the trend
def Style_Extraction():
        
        styles_sorted = sorted(styles, key=len, reverse=True)
        for trend in trends:
                trend_new = ' ' + trend + ' '
                style_found = ''
                for style in styles_sorted:
                    style_new = ' ' + style + ' '
                    if trend_new.find(style_new) != -1:
                            style_found = style
                            break
                styles_matched.append(style_found) 
                
def WriteFile():
        trends_tags_added = zip(trends, types, sub_categories, article_types, genders, scores, colors_matched, fabrics_matched, patterns_matched, sleeves_matched, needleworks_matched, embellishments_matched, styles_matched)
        f1 = open('tagged_trends.csv', 'w')
        header = "trend, type, sub_category, article_type, gender, score, color, fabric, pattern, sleeve, needlework, embellishment, style"
        f1.write(header)
        f1.write('\n')
        for item in trends_tags_added:
                item_str = str(item)
                item_str = item_str.replace('(', '')
                item_str = item_str.replace(')', '')
                item_str = item_str.replace("'", '')            
                item_str = item_str.replace(",", '\t')
                f1.write(item_str)
                f1.write('\n')
        f1.close()
        
def main():
        TagsArray()
        ReadFile()
        Color_Extraction()
        Fabric_Extraction()
        Pattern_Extraction()
        Sleeve_Extraction()
        Needlework_Extraction()
        Embellishment_Extraction()
        Style_Extraction()
        WriteFile()
         
# Boiler plate
if __name__ == '__main__':
 main()
