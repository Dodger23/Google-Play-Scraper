library(readxl)
library(rvest) 
library(xlsx)

data = as.data.frame(read_excel("data/Sourcing Input List.xlsx" ) )
names(data) = make.names(names(data))
#print(data)
get_app_link = function (name)
{
  # if there is any spaces in the name replace them with "%20" to be a valid link 
  name = gsub(" " , "%20" , name)
  
  # search google play apps with the name
  url = paste0("https://play.google.com/store/search?q=", name , "&c=apps&hl=en")
  
  # read the html page of the search  
  name_search  = read_html(url)
  # class .poRVub contains is the class of divs contains the apps links 
  # get the first node of this class == get the first app in ssearch 
  name_search = name_search %>% html_node(".poRVub")  
  
  #get the link in the <a> tag of this div 
  href_link = xml_attrs(name_search)
  
  # paste the link with the main google play start link 
  appUrl = paste0("https://play.google.com" ,  as.character(href_link["href"] ) )
}

get_app_details = function(url)
{
  #read the app page
  app_page = read_html(url)
  
  get_reviews_score = function()
  {
    # class .BHMmbe contains the reviews score 
    review_score = app_page %>% html_node(".BHMmbe")
    
    # get the attribute "aria-label" which contains the rate score
    # take only the score from the sentence 
    review_score= as.character(substr(xml_attrs(review_score)["aria-label"] , 7 , 9))
    review_score
  }
  
  get_developer_website = function ()
  {
    # get all node with the class .hrTbp 
    dev_webiste = app_page %>% html_nodes(".hrTbp")
    
    # take the 4th one of these nodes (divs) which contains the developer website and take the link of the <a> tag
    dev_webiste = as.character(xml_attrs( dev_webiste[[4]] )["href"] )
    
    dev_webiste
  }
  
  get_app_downloads = function()
  {
    # get all the nodes with the class ".htlgb" which are children  of class ".IQ1z0d" 
    app_downloads = app_page %>% html_nodes(".IQ1z0d .htlgb")
    # take the 6th node of the list which contains the nummber of app installs 
    app_downloads = as.character( app_downloads[[6]] %>% html_text()  )
    app_downloads
  }
  ret = c(get_reviews_score() , get_developer_website() , get_app_downloads())
  ret
}

# initializenew data frame columns 
data$play_store_url = rep("" , nrow(data))
data$reviews_score = rep(0 , nrow(data))
data$dev_website = rep("" , nrow(data))
data$number_of_downloads = rep(0 , nrow(data))

for(i in 1:nrow(data))
{
  # get the app play url 
  data[i ,"play_store_url" ] =  get_app_link( data[i , "Company.Name"] )
  # wait because google play close the connection when there is many continues requests 
  if(i%%2==0)
    Sys.sleep(15)
  details = get_app_details(data[i, "play_store_url"]) 
  data[i , "reviews_score"] = details[1]
  data[i , "dev_website"] = details[2]
  data[i , "number_of_downloads"] = details[3]
  # wait because google play close the connection when there is many continues requests 
  print(data[i, ])
  if(i%%2==0)
    Sys.sleep(15) 
  
}

write.xlsx(data , "data/ans.xlsx")


