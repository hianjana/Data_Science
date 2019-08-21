# -*- coding: utf-8 -*-
import scrapy
from scrapy.selector import Selector
from scrapy.http import HtmlResponse
import re
from datetime import datetime
import urllib
import json
import string
import dateparser

class BlueHydrangeasSpider(scrapy.Spider):
    name = 'thebluehydrangeas'
    start_urls = ['https://www.bloglovin.com/blogs/blue-hydrangeas-petite-fashion-lifestyle-18173087']
    
    # To create output directory
    outputdir           = '/home/ubuntu/crawled_files/thebluehydrangeas/' + (datetime.now().strftime('%d_%m_%Y'))
    
    def parse(self, response): 
      # extract all the text within the script tag
      fulltext       = response.xpath("//script[contains(.,'www.thebluehydrangeas.com')]/text()").extract()
      # An empty list which will store all the urls related to 'thebluehydrangeas'
      thebluehydrangeas = []
      # Regex to find all the links related to 'thebluehydrangeas'
      thebluehydrangeaslinks = re.findall('"link":"https:\S+www\.thebluehydrangeas\.com\S+content', str(fulltext))
      replLinks              = [link.replace('"link":"','') for link in thebluehydrangeaslinks]
      replLinks1             = [link.replace('","content','') for link in replLinks]
      urls                   = [link.replace('\\','') for link in replLinks1]
      
      # To loop through all the urls retrieved
      for url in urls:
         url                 = response.urljoin(url)       
         yield scrapy.Request(url=url, meta={'source_url':response.urljoin(url)}, callback=self.parse_details)
         
      
      # To extract the paginations blogs
      for i in range(2,7):         
         newurl = 'https://www.bloglovin.com/api/v2/posts?page=%s&blog=18173087&page_type=blog_profile&page_context=latest' % i
         request = scrapy.Request(url=newurl, callback=self.parse_json)         
         request.headers['User-Agent'] = (
	             'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.113 Safari/537.36')
         yield request   
             
    
    def parse_details(self, response):

        # Xpath to retrieve the blog title
        title 	  = response.xpath('/html/body/div[1]/div/div/main/article/header/h1').extract()
        blogtitle = re.search('>([\w\W\s]+)<', str(title))
        
        # Author of the blog
        author          = 'The Blue Hydrangeas'
        
        # Create an empty list for tags
        tags = []
        # Xpath to retrieve all the tags
        spantags      = response.xpath('/html/body/div[1]/div/div/main/article/header/p/span')        
        # Loop to go through all the tags and fetch them using regular expression
        for a in spantags.xpath('.//a'):
          tagline = a.extract()
          tagmatch = re.search(r'"category tag">([\w\W\s]+)<', tagline)
          tags.append(tagmatch.group(1))
        
        # Xpath to retrieve the blog date
        spandateofblog    = response.xpath('/html/body/div[1]/div/div/main/article/header/p/time').extract()
        dateext           = re.search(r'>([\w\W\s]+)<', str(spandateofblog))
        datestr           = dateext.group(1)
        date_object       = dateparser.parse(datestr)
        dateofblog        = date_object.strftime('%Y-%m-%d')           
        
        # Xpath to retrieve the main image
        img_url = response.xpath('/html/body/div[1]/div/div/main/article/div/p[1]/img/@src').extract()
               
        fullcontent = response.xpath('/html/body/div[1]/div/div/main/article/div//p//text()').extract()
           
        # To retrieve all comments
        # To create an empty list for comments
        comments = []
        # Xpath to retrieve all the comments
        commentpath = response.xpath('//div[@class="comment-content"]')
        # Loop to go through all the comments
	for p in commentpath.xpath('.//p/text()'):
	   newcomment = p.extract()
	   comments.append(newcomment)            

        # To construct output file 
        url                 = response.meta['source_url']
        currDateTime        = datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S')
        currDateTime        = string.replace(currDateTime, ' ', '_')
        currDateTime        = string.replace(currDateTime, '-', '_')
        currDateTime        = string.replace(currDateTime, ':', '_')
        newurl              = string.replace(url, 'https://www.thebluehydrangeas.com', '')
        newurl              = string.replace(newurl, '-', '_')
        newurl              = string.replace(newurl, '/', '')
        newurl              = string.replace(newurl, 'http:www.thebluehydrangeas.com', '')
        end                 = len(newurl)
        newurl              = newurl[0:end]   
        print "New file name is: " + newurl
        # To construct output file name
        outputfilename      =  self.outputdir + '/output_blogvin_thebluehydrangeas_' + newurl + '_' + currDateTime + '.json'
        
        # Response items to give back
        item = {
          'author'           : author,
          'tags'             : tags,
          'dateOfBlog'       : dateofblog,
          'title'            : blogtitle.group(1),
          'content'          : fullcontent,
          'comments'         : comments,
          'timestamp'        : str(datetime.utcnow()),
          "outputfilename"   : outputfilename,
          "source_url"       : response.meta['source_url'],
          "image_url"        : img_url,
          "source_domain"    : "thebluehydrangeas.com",
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
     