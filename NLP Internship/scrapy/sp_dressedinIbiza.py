import arrow
import scrapy
import re
from datetime import datetime
import urllib
import json
import string

class DressedInIbizaSpider(scrapy.Spider):
    name = 'dressedinIbiza'
    start_urls = ['https://www.bloglovin.com/blogs/dressedin-ibiza-fashion-trends-directly-from-13607465']

    # To create output directory
    outputdir           = '/home/ubuntu/crawled_files/dressedinIbiza/' + (datetime.now().strftime('%d_%m_%Y'))
        
    def parse(self, response): 
      # extract all the text within the script tag
      fulltext       = response.xpath("//script[contains(.,'dressedin-ibiza')]/text()").extract()
      # An empty list which will store all the urls related to 'dressedinIbiza'
      dressedinIbizalinks = []
      # Regex to find all the links related to 'dressedinIbiza'
      dressedinIbizalinks = re.findall('"post_public_url":"https:\S+dressedin-ibiza\S+likes', str(fulltext))
      replLinks              = [link.replace('"post_public_url":"','') for link in dressedinIbizalinks]
      replLinks1             = [link.replace('","likes','') for link in replLinks]
      urls                   = [link.replace('\\','') for link in replLinks1]
            
      # To loop through all the urls retrieved
      for url in urls:
         url                 = response.urljoin(url)       
         yield scrapy.Request(url=url, meta={'source_url':response.urljoin(url)}, callback=self.parse_details)
         
      
      # To extract the paginations blogs
      for i in range(2,5):         
         newurl = 'https://www.bloglovin.com/api/v2/posts?page=%s&blog=13607465&page_type=blog_profile&page_context=latest' % i
         yield scrapy.Request(url=newurl, callback=self.parse_json)
         
    def parse_details(self, response):        
        
        # To retrieve the author of the post
        author_raw     = response.xpath('/html/body/div[3]/div[2]/div/div[1]/div/div[2]/p[1]/span/em').extract()
        author_str     = re.search('>(.+)<', str(author_raw))
        if author_str:
          author_ext     = author_str.group(1)
          author         = author_ext.replace('Written by ', "")
        else:
          author         = 'dressedin-ibiza.com'
        
        # There are no tags in the blog
        tags = ''
        
        # Xpath to retrieve the blog date
        spandate = response.xpath('/html/body/div[4]/div[1]/section[1]/div/a/span').extract()
        date_of_blog = re.search('>dressedin-ibiza.com(.+)<',str(spandate))
        if date_of_blog:
            dateext          = date_of_blog.group(1)
            datestr          = dateext.replace(' \\xb7 ',"") 
            formatter_string = "%b %d, %Y"            
            try:
               date_object      = datetime.strptime(datestr, formatter_string)
               dateofblog       = date_object.strftime('%Y-%m-%d')
            except:
               dateofblog       = str(arrow.utcnow().format('YYYY-MM-DD'))
        else:
            dateofblog       = str(arrow.utcnow().format('YYYY-MM-DD'))
        
        # Xpath to retrieve the blog title
        title     = response.xpath('/html/body/div[4]/div[1]/section[2]/a/h1').extract()
        blogtitle = re.search('>([\w\W\s]+)<', str(title))
        
        # Xpath to retrieve the blog content
        fullcontent = response.xpath('/html/body/div[4]/div[1]/section[2]/div[1]//p//text()').extract()
          
        # There are no comments in this blog
        comments = ''         
        
        # Create an empty list for image urls
        img_url = []
        # To extract all the image urls
        img_xpath = response.xpath('/html/body/div[4]/div[1]/section[2]')
        for img in img_xpath.xpath('.//img/@src'):
          url = img.extract()
          img_url.append(url)        
        
        # To construct output file 
        url                 = response.meta['source_url']
        currDateTime        = datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S')
        currDateTime        = string.replace(currDateTime, ' ', '_')
        currDateTime        = string.replace(currDateTime, '-', '_')
        currDateTime        = string.replace(currDateTime, ':', '_')
        newurl              = string.replace(url, 'https://www.bloglovin.com/blogs/dressedin-ibiza-fashion-trends-directly-from-13607465', '')
        newurl              = string.replace(newurl, '/', '_')        
        end                 = len(newurl)
        newurl              = newurl[0:end]  
        newurl              = string.replace(newurl, '-', '_')
        
        # To construct output file name
        outputfilename      =  self.outputdir + '/output_blogvin_dressedinIbiza_' + newurl + '_' + currDateTime + '.json'
        
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
          "source_domain"    : "dressedin-ibiza.com",
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
         pastUrl = data["meta"]["resolved"]["smallpost"][post]["post_public_url"]
         yield scrapy.Request(url=pastUrl, meta={'source_url':pastUrl}, callback=self.parse_details)
          
       
       
