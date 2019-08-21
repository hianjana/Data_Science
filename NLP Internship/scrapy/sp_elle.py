import scrapy
import re
from datetime import datetime
import urllib
import json
import string
import codecs
import urllib2


class ElleSpider(scrapy.Spider):
    name            = 'elle'
    start_urls      = ['http://www.elle.com/fashion/trend-reports']

    # To create output directory
    outputdir       = '/home/ubuntu/crawled_files/elle/' + (datetime.now().strftime('%d_%m_%Y'))

    def parse(self, response): 
      # To extract all the links in a page
      links = []
      urls  = []
      links = response.xpath('//a[@class="full-item-title item-title"]/@href').extract()
      urls  = ['http://www.elle.com' + s for s in links]
      
      # To loop through all the urls retrieved
      for url in urls:
         url                 = response.urljoin(url)  
         yield scrapy.Request(url=url, meta={'source_url':response.urljoin(url)}, callback=self.parse_details)
      
      # To extract the paginations blogs
      for i in range(2,10):
         pagination = 'http://www.elle.com/ajax/infiniteload/?id=bcfd1129-0c10-42ea-a24c-71ab4138049d&class=CoreModels%5Csections%5CSubSectionModel&viewset=section&page='
         pagination = urllib.unquote(pagination).decode('utf8')
         pagination =  codecs.decode(pagination, 'unicode_escape')
         pagination_url = (pagination + '%d') % i                        
         yield scrapy.Request(url=pagination_url, meta={'source_url_page':response.urljoin(pagination_url)}, callback=self.parse_pagination)
    
    def parse_details(self, response):     
        # To identify whether the page has slideshow or a vertical scroll
        fullbody = response.xpath('/html/body').extract()
        scroll_type = re.search(r'class="([a-zA-Z\s-]+)"', str(fullbody))
        
        if scroll_type.group(1) == 'locale-en gallery':
        
                # Xpath to retrieve the blog title
                spantitle = response.xpath('//div[@class="content-header-inner"]/h1').extract()
                blogtitle = re.search('>([\w\W\s]+)<', str(spantitle))
                title     = blogtitle.group(1)
                
                # Xpath to retrieve the author of the blog
                spanauthor      = response.xpath('//div[@class="byline content-info-byline"]/a').extract()
                authoroftheblog = re.search(r'"name">([a-zA-Z\s]+)<', str(spanauthor))
                if authoroftheblog:
                   author = authoroftheblog.group(1)
                else:
                   author = ''
                
                # Retrieve the blog date
                spandate         = response.xpath('//div[@class="content-info-date js-date"]').extract()
                dateext          = re.search('>([\w\W\s]+)<', str(spandate))                
                dateclean        = string.replace(dateext.group(1), '\\n', '')
                datestr          = string.replace(dateclean, '\\t', '')
                formatter_string = "%b %d, %Y"
                date_object      = datetime.strptime(datestr, formatter_string)
                dateofblog       = date_object.strftime('%Y-%m-%d')
                
                # Create an empty list for tags
                tags = [] 
                # Xpath to retrieve all the tags
                spantags      = response.xpath('//*[@class="slideshow-slide-hed"]/text()').extract()
                tagline = [tag.replace('\n','') for tag in spantags]
                tagline = [tag.replace('\t','') for tag in tagline]
                for tag in tagline:
                    if tag not in tags:
                      tags.append(tag)

                # Xpath to retrieve the blog content
                fullcontent = response.xpath('//*[@id="slideshow-lede"]/div[2]/p/text()').extract()   
          
                # To retrieve all comments
                # To create an empty list for comments
                # In this case, there are no comments
                comments = []        
        
                # Create an empty list for image urls
                img_url = []
                # To extract all the image urls
                img_xpath = response.xpath('/html/body/div[2]/div[2]')
                for img in img_xpath.xpath('.//img/@data-src'):
                  url = img.extract()
                  url_ext = re.search('([a-zA-Z-:\/\.\d_]+)\?', url)
                  img_url.append(url_ext.group(1))

        #if scroll_type.group(1) == 'locale-en listicle':
        else:
                # Xpath to retrieve the blog title
                spantitle = response.xpath('//div[@class="content-header-inner"]/h1').extract()
                blogtitle = re.search('>([\w\W\s]+)<', str(spantitle))
                title     = blogtitle.group(1)
        
                # Xpath to retrieve the author of the blog
                spanauthor      = response.xpath('//div[@class="byline content-info-byline"]/a').extract()
                authoroftheblog = re.search(r'"name">([a-zA-Z\s]+)<', str(spanauthor))
                if authoroftheblog:
                   author = authoroftheblog.group(1)
                else:
                   author = ''                
        
                # Retrieve the blog date
                spandate      = response.xpath('//div[@class="content-info-date js-date"]').extract()
                dateext          = re.search('>([\w\W\s]+)<', str(spandate))                
                dateclean        = string.replace(dateext.group(1), '\\n', '')
                datestr          = string.replace(dateclean, '\\t', '')
                formatter_string = "%b %d, %Y"
                date_object      = datetime.strptime(datestr, formatter_string)
                dateofblog       = date_object.strftime('%Y-%m-%d')
        
                # Create an empty list for tags
                tags = [] 
                # Xpath to retrieve all the tags
                spantags      = response.xpath('/html/body/div[2]/div[3]/div[1]/div[5]')
                # Loop to go through all the tags and fetch them using regular expression
                for p in spantags.xpath('.//p/text()'):
                  tagline = p.extract()
                  tagline = string.replace(tagline, '\n', '')
                  tagline = tagline.lstrip(' ')
                  tagline = tagline.rstrip(' ')
                  tags.append(tagline)           
                  
                # Xpath to retrieve the blog content
                fullcontent = response.xpath('/html/body/div[2]/div[3]/div[1]/div[3]/p//text()').extract()        
          
                # To retrieve all comments
                # To create an empty list for comments
                # In this case, there are no comments
                comments = []        
        
                # Create an empty list for image urls
                img_url = []
                # To extract all the image urls
                img_xpath = response.xpath('/html/body/div[2]/div[3]/div[1]')
                for img in img_xpath.xpath('.//img/@data-src'):
                  url     = img.extract()
                  url_ext = re.search('([a-zA-Z-:\/\.\d_]+)\?', url)
                  img_url.append(url_ext.group(1))

        # To construct output file 
        url                = response.meta['source_url']
        currDateTime        = datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S')
        currDateTime        = string.replace(currDateTime, ' ', '_')
        currDateTime        = string.replace(currDateTime, '-', '_')
        currDateTime        = string.replace(currDateTime, ':', '_')
        newurl              = string.replace(url, 'http://www.elle.com/fashion/trend-reports/', '')
        end                 = len(newurl)
        newurl              = newurl[0:end]  
        newurl              = string.replace(newurl, '-', '_')
        newurl              = string.replace(newurl, '/', '_')
	
        # To construct output file name
        #outputdir           = '/home/ubuntu/crawled_files/elle/' + (datetime.now().strftime('%d_%m_%Y'))
        #outputfilename      =  self.outputdir + '/output_blogvin_lefashion_' + newurl + '_' + currDateTime + '.json'
        outputfilename      =  self.outputdir + '/output_elle_' + newurl + currDateTime + '.json'
        
        # To create list of seasons and synonyms
        list_of_seasons = ['Spring/Summer', 'Autumn/Winter', 'Fall/Winter', 'spring-summer', 'autumn-winter', 'fall-winter', 'SS', 'AW', 'FW', 'spring','summer','autumn', 'fall', 'winter']
        curr_month = datetime.now().strftime('%m')
        curr_month = int(curr_month)
        
        # To identify current season
        if curr_month >= 3 and curr_month <= 5:
	     curr_season = 'Spring'
	elif curr_month >= 6 and curr_month <= 8:
	     curr_season = 'Summer'
	elif curr_month >= 9 and curr_month <= 11:
	     curr_season = 'Fall'     
	else:
	     curr_season = 'Winter'          
        
        # To identify blog season from title or link
        title_lower = title.strip().lower()
        season_found = ''
	for season in list_of_seasons:
	      season_lower = season.lower()
	      if title_lower.find(season_lower) != -1:
	          season_found = season
	          break
	      else:
	          for season in list_of_seasons:
	              season_lower = season.lower()
	              if url.find(season_lower) != -1:
	                   season_found = season
	                   break 

	if season_found == '':
	     blog_season = curr_season
	else:
             blog_season = season_found
             
        # To identify blog year  
        list_of_years = []
	curr_year = datetime.now().strftime('%Y')
	next_year = int(curr_year) + 1
	list_of_years.append(curr_year)
	list_of_years.append(str(next_year))
	
	year_found = ''
	for y in list_of_years:
	      if title_lower.find(y) != -1:
	          year_found = y
	          break
	      else:
	          for y in list_of_years:
	              if url.find(y) != -1:
	                   year_found = y
	                   break 	          
	          
	if year_found == '':
	     blog_year = int(curr_year)
	else:
             blog_year = int(year_found)

        # To identify if the blog content is about current season or it is about an upcoming season
        
        if blog_year != int(curr_year):
             context_flg = 'Diff'
        else:
             if curr_season.lower() == 'spring' and (blog_season.lower() == 'spring/summer' or blog_season.lower() == 'spring-summer' or blog_season.lower() == 'SS' or blog_season.lower() == 'spring'):
                  context_flg = 'Same'
             elif curr_season.lower() == 'summer' and (blog_season.lower() == 'spring/summer' or blog_season.lower() == 'spring-summer' or blog_season.lower() == 'SS' or blog_season.lower() == 'summer'):
                  context_flg = 'Same'
             elif curr_season.lower() == 'fall' and (blog_season.lower() == 'autumn/winter' or blog_season.lower() == 'fall/winter' or blog_season.lower() == 'autumn-winter' or blog_season.lower() == 'fall-winter' or blog_season.lower() == 'AW' or blog_season.lower() == 'FW' or blog_season.lower() == 'autumn' or blog_season.lower() == 'fall'):
                  context_flg = 'Same'
             elif curr_season.lower() == 'winter' and (blog_season.lower() == 'autumn/winter' or blog_season.lower() == 'fall/winter' or blog_season.lower() == 'autumn-winter' or blog_season.lower() == 'fall-winter' or blog_season.lower() == 'AW' or blog_season.lower() == 'FW' or blog_season.lower() == 'winter'):
                  context_flg = 'Same'
             else:
                  context_flg = 'Diff'
                  
        # Response items to give back
        item = {
          "author"            : author,
          "tags"              : tags,
          "dateOfBlog"        : dateofblog,
          "title"             : title,
          "content"           : fullcontent,
          "comments"          : comments,
          "timestamp"         : str(datetime.utcnow()),
          "outputfilename"    : outputfilename,
          "source_url"        : response.meta['source_url'],
          "image_url"         : img_url,
          "source_domain"     : "elle.com",
          "referral_domain"   : "elle.com",
          "blog_season"       : blog_season,
          "blog_year"         : blog_year,
          "current_season"    : curr_season,
          "current_year"      : int(curr_year),
          "context_flg"       : context_flg,
        }
        
        # Return the final response
        yield item
        
        
    """ 
     Function to crawl pagination pages 
    """
    def parse_pagination(self, response):    
       full_response = urllib2.urlopen(response.meta['source_url_page'])
       data          = full_response.read()
       pastPosts     = re.findall('full-item-title item-title" href="([/a-zA-Z\d-]+)">', str(data))
       pastUrls      = ['http://www.elle.com' + s for s in pastPosts]
       for pastUrl in pastUrls:
         yield scrapy.Request(url=pastUrl, meta={'source_url':pastUrl}, callback=self.parse_details)