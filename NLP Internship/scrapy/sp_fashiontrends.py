import scrapy
import re
from datetime import datetime
import urllib
import json
import string
import urllib2
import dateparser

class FashionTrendsSpider(scrapy.Spider):
    name = 'fashiontrends'
    start_urls = ['https://www.bloglovin.com/blogs/fashion-trends-daily-3050065']

    # To create output directory
    outputdir           = '/home/ubuntu/crawled_files/fashiontrends/' + (datetime.now().strftime('%d_%m_%Y'))
    
    def parse(self, response): 
      # extract all the text within the script tag
      fulltext       = response.xpath("//script[contains(.,'fashiontrendsdaily.com')]/text()").extract()
      # An empty list which will store all the urls related to 'fashiontrends'
      fashiontrendslinks = []
      # Regex to find all the links related to 'fashiontrends'
      fashiontrendslinks = re.findall('"link":"http:\S+www\.fashiontrendsdaily\.com\S+content', str(fulltext))
      replLinks              = [link.replace('"link":"','') for link in fashiontrendslinks]
      replLinks1             = [link.replace('","content','') for link in replLinks]
      urls                   = [link.replace('\\','') for link in replLinks1]
      
      # To loop through all the urls retrieved
      for url in urls:
         url                 = response.urljoin(url)       
         yield scrapy.Request(url=url, meta={'source_url':response.urljoin(url)}, callback=self.parse_details)
         
      
      # To extract the paginations blogs
      for i in range(2,19):         
         newurl = 'https://www.bloglovin.com/api/v2/posts?page=%s&blog=3050065&page_type=blog_profile&page_context=latest' % i
         yield scrapy.Request(url=newurl, callback=self.parse_json)
         
    def parse_details(self, response):        
        
        # Author of the post
        author        = 'Fashion Trends Daily Staff'
        
        # Create an empty list for tags
        tags = [] 
        # Xpath to retrieve all the tags
        spantags      = response.xpath('//*[@id="main"]/div[1]/p[2]')
        
        # Loop to go through all the tags and fetch them using regular expression
        for a in spantags.xpath('.//a'):
          tagline = a.extract()
          tagmatch = re.search(r'"tag">([\w\W\s]+)<', tagline)
          tags.append(tagmatch.group(1))
        
        # Xpath to retrieve the blog date
        spandate    = response.xpath('//*[@id="main"]/div[1]/p[1]/span[1]').extract()
        dateext     = re.search('>(.+)\s\|', str(spandate))
        datestr     = dateext.group(1)
        date_object = dateparser.parse(datestr)
        dateofblog  = date_object.strftime('%Y-%m-%d')       
        
        # Xpath to retrieve the blog title
        spantitle = response.xpath('//*[@id="main"]/div[1]/h1/a').extract()
        blogtitle = re.search('>([\w\W\s]+)<', str(spantitle))
        
        # Xpath to retrieve the blog content
        fullcontent = response.xpath('//*[@id="main"]/div[1]/div//p//text()').extract()      
          
        # To retrieve all comments
        # There are no comments in this blog
        comments = ''           
        
        # Create an empty list for image urls
        img_url = []
        # To extract all the image urls. Currently no images are extracted through this spider
        # img_xpath = response.xpath('//*[@id="main"]/div[1]/div')

        
        # To construct output file 
        url                 = response.meta['source_url']
        currDateTime        = datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S')
        currDateTime        = string.replace(currDateTime, ' ', '_')
        currDateTime        = string.replace(currDateTime, '-', '_')
        currDateTime        = string.replace(currDateTime, ':', '_')
        newurl              = string.replace(url, '.html', '')
        newurl              = string.replace(newurl, 'http://www.fashiontrendsdaily.com/', '')
        end                 = len(newurl)
        newurl              = newurl[0:end]  
        newurl              = string.replace(newurl, '-', '_')
        newurl              = string.replace(newurl, '/', '_')
        
        # To construct output file name
        outputfilename      =  self.outputdir + '/output_blogvin_fashiontrends_' + newurl + '_' + currDateTime + '.json'
        
        # Response items to give back
        item = {
          "author"           : author,
          "tags"             : tags,
          "dateOfBlog"       : dateofblog,
          "title"            : blogtitle.group(1),
          "content"          : fullcontent,
          "comments"         : comments,
          "timestamp"        : str(datetime.utcnow()),
          "outputfilename"   : outputfilename,
          "source_url"       : response.meta['source_url'],
          "image_url"        : img_url,
          "source_domain"    : "fashiontrendsdaily.com",
          "referral_domain"  : "bloglovin.com",            
        }
        
        # Return the final response
        yield item
           
    """ 
     Function to crawl pagination pages 
    """
    def parse_json(self, response):     
       data = json.loads(response.text)
       pastPosts = data["meta"]["resolved"]["smallpost"].keys()
       for post in pastPosts:
         pastUrl = data["meta"]["resolved"]["smallpost"][post]["link"]
         yield scrapy.Request(url=pastUrl, meta={'source_url':pastUrl}, callback=self.parse_details)
          
       
       
