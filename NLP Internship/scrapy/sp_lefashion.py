import scrapy
import re
from datetime import datetime
import urllib
import json
import string

class LeFashionSpider(scrapy.Spider):
    name = 'lefashion'
    # allowed_domains = ['https://www.bloglovin.com', 'https://www.lefashion.com']
    start_urls = ['https://www.bloglovin.com/blogs/le-fashion-39894']
 
    # To create output directory
    outputdir           = '/home/ubuntu/crawled_files/lefashion/' + (datetime.now().strftime('%d_%m_%Y'))

    def parse(self, response): 
      # extract all the text within the script tag
      fulltext       = response.xpath("//script[contains(.,'www.lefashion.com')]/text()").extract()
      # An empty list which will store all the urls related to 'lefashion'
      lefashionlinks = []
      # Regex to find all the links related to 'lefashion'
      lefashionlinks = re.findall('"link":"http:\S+www\.lefashion\.com\S+\.html', str(fulltext))
      replLinks      = [link.replace('"link":"','') for link in lefashionlinks]
      urls           = [link.replace('\\','') for link in replLinks]
      
      # To loop through all the urls retrieved
      for url in urls:
         url                 = response.urljoin(url)       
         yield scrapy.Request(url=url, meta={'source_url':response.urljoin(url)}, callback=self.parse_details)
         
      
      # To extract the paginations blogs
      for i in range(2,16):         
         newurl = 'https://www.bloglovin.com/api/v2/posts?blog=39894&page=%s&page_type=blog_profile&page_context=latest' % i
         yield scrapy.Request(url=newurl, callback=self.parse_json)
      
    def parse_details(self, response):        
        
        # To retrieve the author of the blog
        spanauthor    = response.xpath('//*[@id="Blog1"]/div[1]/div/div/div/div[1]/div[3]/div[1]/span[1]/span').extract()
        # To retrieve the author of the post
        author        = re.search(r'>([\w\W\s]+)<', str(spanauthor))
        
        # Create an empty list for tags
        tags = [] 
        # Xpath to retrieve all the tags
        spantags      = response.xpath('//*[@id="Blog1"]/div[1]/div/div/div/div[1]/div[3]/div[2]/span')
        
        # Loop to go through all the tags and fetch them using regular expression
        for a in spantags.xpath('.//a'):
          tagline = a.extract()
          tagmatch = re.search(r'"tag">([\w\W\s]+)<', tagline)
          tags.append(tagmatch.group(1))
        
        # Xpath to retrieve the blog date
        spandate    = response.xpath('//*[@id="Blog1"]/div[1]/div/h2/span').extract()
        dateext     = re.search('>(.+)<', str(spandate))
        datestr     = dateext.group(1)
        date_object = datetime.strptime(datestr, "%m.%d.%Y")
        dateofblog  = date_object.strftime('%Y-%m-%d')
        
        # Xpath to retrieve the blog title
        spantitle = response.xpath('//*[@id="Blog1"]/div[1]/div/div/div/div[1]/h3/a').extract()
        blogtitle = re.search('>([\w\W\s]+)<', str(spantitle))
        
        # Xpath to retrieve the blog content
        #fullcontent = response.xpath('//*[@id="Blog1"]/div[1]/div/div/div/div[1]/div[2]/text()').extract()
        fullcontent = response.xpath('.//*[@id="Blog1"]/div[1]/div/div/div/div[1]/div[2]//text()').extract()
                 
        # To retrieve all comments
        # To create an empty list for comments
        comments = []
        # Xpath to retrieve all the comments
        commentpath = response.xpath('//div[@id="comment-holder"]')
        # Loop to go through all the comments
	for p in commentpath.xpath('.//p/text()'):
	   newcomment = p.extract()
	   comments.append(newcomment)            
        
        # To extract the main image url
        img_url = response.xpath('//*[@id="Blog1"]/div[1]/div[1]/div/div[1]/div/div[2]/a[1]/img/@src').extract()
        
        # To construct output file 
        url                 = response.meta['source_url']
        currDateTime        = datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S')
        currDateTime        = string.replace(currDateTime, ' ', '_')
        currDateTime        = string.replace(currDateTime, '-', '_')
        currDateTime        = string.replace(currDateTime, ':', '_')
        newurl              = string.replace(url, '.html', '')
        newurl              = string.replace(newurl, 'http://www.lefashion.com/', '')
        end                 = len(newurl)
        newurl              = newurl[8:end]  
        newurl              = string.replace(newurl, '-', '_')
        # To construct output file name
        #outputdir           = '/home/ubuntu/crawled_files/lefashion/' + (datetime.now().strftime('%Y_%m_%d_%H_%M_%S'))
        #outputdir           = '/home/ubuntu/crawled_files/lefashion/'
        outputfilename      =  self.outputdir + '/output_blogvin_lefashion_' + newurl + '_' + currDateTime + '.json'
        
        # Response items to give back
        item = {
          "author"            : author.group(1),
          "tags"              : tags,
          "dateOfBlog"        : dateofblog,
          "title"             : blogtitle.group(1),
          "content"           : fullcontent,
          "comments"          : comments,
          "timestamp"         : str(datetime.utcnow()),
          "outputfilename"    : outputfilename,
          "source_url"        : response.meta['source_url'],
          "image_url"         : img_url,
          "source_domain"     : "lefashion.com",
          "referral_domain"   : "bloglovin.com",
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
