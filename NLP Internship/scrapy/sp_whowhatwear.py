import scrapy
import re
from datetime import datetime
import urllib
import json
import string
import codecs
import urllib2
import dateparser
import arrow

class WhoWhatWearSpider(scrapy.Spider):
    name            = 'whowhatwear'
    start_urls      = ['http://www.whowhatwear.co.uk/section/fashion-trends']
    #start_urls      = ['http://www.whowhatwear.co.uk/brown-colour-trend']

    # To create output directory
    outputdir       = '/home/ubuntu/crawled_files/whowhatwear/' + (datetime.now().strftime('%d_%m_%Y'))
    
    def parse(self, response): 
      urls = []
      urlpath = response.xpath('//*[@class="article-list-content"]//a/@href').extract()
      for each in urlpath:
           new_url = 'http://www.whowhatwear.co.uk' + each
           urls.append(new_url)
      
      # To loop through all the urls retrieved
      for url in urls:
         url                 = response.urljoin(url)       
         yield scrapy.Request(url=url, meta={'source_url':response.urljoin(url)}, callback=self.parse_details)    

      # To extract the paginations blogs
      for i in range(2,12):         
         newurl = 'http://www.whowhatwear.co.uk/section/fashion-trends/page/%s' % i
         yield scrapy.Request(url=newurl, callback=self.parse_json)
         
    def parse_details(self, response):        
        
        # To retrieve the Xpath of the author of the blog
        spanauthor    = response.xpath('//*[@class="author-name"]/a').extract()
        # To retrieve the author of the post
        authorext     = re.search(r'>([\w\W\s]+)<', str(spanauthor))                
        if authorext:
                author        = authorext.group(1)
        else:
                spanauthor    = response.xpath('//*[@class="author-name"]/span').extract()
                authorext     = re.search(r'>([\w\W\s]+)<', str(spanauthor))
                if authorext:
                      author        = authorext.group(1)
                else:
                      author        = ''     
        
        # Xpath to retrieve the blog title
        spantitle   = response.xpath('//*[@class="widgets-list-headline"]/h1').extract()
        blogtitlext = re.search('>([\w\W\s]+)<', str(spantitle))
        if blogtitlext:
             blogtitle   = blogtitlext.group(1)
        else:        
            spantitle   = response.xpath('//*[@class="exclusive-template-headline-container"]/h1').extract()
            blogtitlext = re.search('>([\w\W\s]+)<', str(spantitle))
            if blogtitlext:
                 blogtitle   = blogtitlext.group(1)
            else:
                 blogtitle   = ''
        
        # Create an empty list for tags
        tagpath = response.xpath('//*[@class="click-gallery-view click-gallery-slide gallery-slide"]//span').extract()
        tags = []
        for eachtag in tagpath:
             tagmatch = re.search(r'>([\w\W\s]+)<', eachtag)
             tags.append(tagmatch.group(1))
               
        # Xpath to retrieve the blog date
        spandate    = response.xpath('//*[@class="post-date inline"]').extract()
        dateext     = re.search('>([\w\W\s]+)<', str(spandate))
        if dateext:
            datestr     = dateext.group(1)
            date_object = dateparser.parse(datestr)
            dateofblog  = date_object.strftime('%Y-%m-%d')
        else:
            dateofblog  = str(arrow.utcnow().format('YYYY-MM-DD'))
        
        ##### Content extraction starts here #####
        # To extract the main content
	contentlist    = response.xpath('//*[@class="text"]//text()').extract()
	contentraw     = ' '.join(contentlist)
	data_encode    = contentraw.encode('ascii', 'ignore')
	data_clean     = data_encode.decode().replace('\n','')
	data_clean     = data_clean.replace('  ','')	
	
	# To extract content from the gallery with images   
	content_tagged_list   = response.xpath('//*[@class="caption-description"]//p/text()').extract()
	contentraw_tagged     = ' '.join(content_tagged_list) 
	data_encode_tagged    = contentraw_tagged.encode('ascii', 'ignore')
	data_clean_tagged     = data_encode_tagged.replace('  ','')	
	
	# Combine the content extracted in two phases
        fullcontent    = data_clean + ' ' + data_clean_tagged
        ##### Content extraction ends here #####
        
        # To retrieve all comments
        # To create an empty list for comments
        comments = []
        
        # To extract all the images from the blog in 2 parts: Main page image extraction and gallery imges extraction
        main_img_url       = response.xpath('//*[@class="proportional image-container"]/img/@src').extract()
        other_img_urls     = response.xpath('//*[@class="image-container"]/img/@src').extract()
        img_urls           = main_img_url + other_img_urls
        
        
        # To construct output file 
        url                 = response.meta['source_url']
        currDateTime        = datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S')
        currDateTime        = string.replace(currDateTime, ' ', '_')
        currDateTime        = string.replace(currDateTime, '-', '_')
        currDateTime        = string.replace(currDateTime, ':', '_')
        newurl              = string.replace(url, 'http://www.whowhatwear.co.uk/', '')
        end                 = len(newurl)
        newurl              = string.replace(newurl, '-', '_')
        # To construct output file name
        outputdir           = '/home/ubuntu/crawled_files/whowhatwear/' + (datetime.now().strftime('%Y_%m_%d_%H_%M_%S'))
        outputdir           = '/home/ubuntu/crawled_files/whowhatwear/'
        outputfilename      =  self.outputdir + '/output_whowhatwear_' + newurl + '_' + currDateTime + '.json'
        
        # Response items to give back
        item = {
          "author"            : author,
          "tags"              : tags,
          "dateOfBlog"        : dateofblog,
          "title"             : blogtitle,
          "content"           : fullcontent,
          "comments"          : comments,
          "timestamp"         : str(datetime.utcnow()),
          "outputfilename"    : outputfilename,
          "source_url"        : response.meta['source_url'],
          "image_url"         : img_urls,
          "source_domain"     : "whowhatwear.co.uk",
          "referral_domain"   : "whowhatwear.co.uk",
        }
        
        # Return the final response
        yield item


    """ 
     Function to crawl pagination pages 
    """
    def parse_json(self, response):     
      dataraw            = response.text
      data_clean         = dataraw.encode('ascii', 'ignore')
      text_str           = str(data_clean)
      text_data          = text_str.replace('\\','')
      whowhatwearlinks   = []
      whowhatwearlinks   = re.findall('a href="(\/[a-zA-Z-]+)">', str(text_data))
      pasturls           = []
      pasturls           = ['http://www.whowhatwear.co.uk' + link for link in whowhatwearlinks]
      for url in pasturls:
         yield scrapy.Request(url=url, meta={'source_url':url}, callback=self.parse_details)
      
      




