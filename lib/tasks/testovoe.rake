namespace :testovoe do
  def url_valid?(url)
    url = URI.parse(url) rescue false
    url.kind_of?(URI::HTTP) || url.kind_of?(URI::HTTPS)
  end

  def mechanize_new_connection (uri)
    require 'rubygems'
    require 'mechanize'
    require 'nokogiri'

    mechanize = Mechanize.new
    url = URI(uri)
    page = mechanize.get(url)
    return page
  end

  def parser_products (page, search_query, search_name, search_price, search_status, category)
    page.search(search_query).each do |good|
      url = good.at_css("a")['href']
      name = good.css(search_name).text.strip
      price = good.css(search_price).text.strip.split(' ')[0].gsub(',', '.').to_f
      status = good.css(search_status).text.strip

      product = Product.find_by url: url
      product = Product.create(name: name, url: url, price: price, status: status) if !product

      connection = Connection.where(category_id: category.id, product_id: product.id)
      product.connections.create(category: category, product: product) if !connection
    end
  end

  desc "get and save the site category structure"
  task task1: :environment do
    require 'awesome_nested_set/move'

    page = mechanize_new_connection ('https://www.tohome.com/index.aspx')

    page.search("div#catMenu ul#leftnav ul[class='set_bg1'] li a").each do |item|
      name = item.text.strip
      url = item['href']

      category = Category.find_by url: url

      if (item['class'] == 'subject')
        @parent.reload if @parent
        category ? @parent = category : @parent = Category.create(name: name, url: url)
      else
        Category.create(name: name, url: url).move_to_child_of(@parent) if !category
      end
    end
    @parent.reload if @parent
  end

  desc "bypassing the category structure on the site and saving the product"
  task task2: :environment do
    categories = Category.all.order(:id)
    categories.each do |category|
      next if !url_valid?(category.url)

      page = mechanize_new_connection (category.url)

      parser_products(page, "span#lblProductDesc div[class='mainbox']",
                      "div[class='prdInfo'] h2[class='prdTitle']",
                      "div[class='prdInfo'] span[class='prdPrice-new']",
                      "div[class='product-status'] span", category)

      list_of_pages = page.css("span#lblPageLink a[class='textpagelink']")
      if list_of_pages
        list_of_pages.reject{|v| v.text.strip == "»"}.each do |link|
          page = mechanize_new_connection (link['href'])
          parser_products(page, "span#lblProductDesc div[class='mainbox']",
                          "div[class='prdInfo'] h2[class='prdTitle']",
                          "div[class='prdInfo'] span[class='prdPrice-new']",
                          "div[class='product-status'] span", category)
        end
      end
    end
  end

  desc "clening database Category"
  task task3: :environment do
    Category.destroy_all
  end

  desc "clening databases Product and Connection"
  task task4: :environment do
    Product.destroy_all
    Connection.destroy_all
  end
end

