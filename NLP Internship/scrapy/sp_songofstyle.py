import scrapy
import re
from datetime import datetime
import urllib
import json
import string
import dateparser

class SongofStyleSpider(scrapy.Spider):
    name = 'songofstyle'
    start_urls = ['https://www.bloglovin.com/blogs/song-style-493482']
    
    # To create output directory
    outputdir           = '/home/ubuntu/crawled_files/songofstyle/' + (datetime.now().strftime('%d_%m_%Y'))
       
    def parse(self, response): 
      # extract all the text within the script tag
      fulltext       = response.xpath("//script[contains(.,'www.songofstyle.com')]/text()").extract()
      # An empty list which will store all the urls related to 'songofstyle
      songofstylelinks = []
      # Regex to find all the links related to 'songofstyle'
      songofstylelinks = re.findall('"link":"http:\S+www\.songofstyle\.com\S+\.html', str(fulltext))
      replLinks      = [link.replace('"link":"','') for link in songofstylelinks]
      urls           = [link.replace('\\','') for link in replLinks]
      
      # To loop through all the urls retrieved
      for url in urls:
         url                 = response.urljoin(url)       
         yield scrapy.Request(url=url, meta={'source_url':response.urljoin(url)}, callback=self.parse_details)
               
      # To extract the paginations blogs
      for i in range(2,19):         
         newurl = 'https://www.bloglovin.com/api/v2/posts?page=%s&blog=493482&page_type=blog_profile&page_context=latest' % i
         yield scrapy.Request(url=newurl, callback=self.parse_json)
         
    def parse_details(self, response):        
        
        # To retrieve the author of the post
        author    = 'Aimee Song'
        
        # Xpath to retrieve the blog title
        title             = response.xpath('//h1[@class="entry-title"]/text()').extract()
        blogtitle         = title[0]
	
        # Xpath to retrieve the blog date
        spandateofblog    = response.xpath('//div[@class="entry-date"]/text()').extract()
        dateext           = re.search(r'\\n\\t\\t\\t\\t\\t([\w\W\s]+)\\t\\t\\t\\t', str(spandateofblog))
        datestr           = dateext.group(1)
        date_object       = dateparser.parse(datestr)
        dateofblog        = date_object.strftime('%Y-%m-%d')         
        
        # There are no tags in the blog
        tags = []
        # Xpath to retrieve all the tags
        spantags      = response.xpath('//*[@id="post-entry"]')     
        # Loop to go through all the tags and fetch them using regular expression
        for a in spantags.xpath('.//a/text()'):
          tagline = a.extract()
          tags.append(tagline)            
        
        # Xpath to retrieve the blog content
        fullcontent = response.xpath('//*[@id="post-entry"]//p//text()').extract()
          
        # To retrieve all comments
        # To create an empty list for comments
        comments = []
        # Xpath to retrieve all the comments
        commentpath = response.xpath('//div[@class="comment-text"]')
        # Loop to go through all the comments
	for p in commentpath.xpath('.//p/text()'):
	   newcomment = p.extract()
	   comments.append(newcomment)       
        
        # Create an empty list for image urls
        img_url = []
        # To extract all the image urls
        img_xpath = response.xpath('//*[@id="post-entry"]')
        for img in img_xpath.xpath('.//img/@src'):
          url = img.extract()
          img_url.append(url)        
        
        # To construct output file 
        url                 = response.meta['source_url']
        currDateTime        = datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S')
        currDateTime        = string.replace(currDateTime, ' ', '_')
        currDateTime        = string.replace(currDateTime, '-', '_')
        currDateTime        = string.replace(currDateTime, ':', '_')
        newurl              = string.replace(url, 'http://www.songofstyle.com', '')
        newurl              = string.replace(newurl, '/', '_')        
        end                 = len(newurl)
        newurl              = newurl[8:end]  
        newurl              = string.replace(newurl, '-', '_')
        
        # To construct output file name
        outputfilename      =  self.outputdir + '/output_blogvin_song_of_style_' + newurl + '_' + currDateTime + '.json'
        
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
          "image_url"         : img_url,
          "source_domain"     : "songofstyle.com",
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
          
       
       
