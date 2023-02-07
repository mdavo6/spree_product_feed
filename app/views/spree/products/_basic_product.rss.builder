current_currency = "AUD"

product_collection               = Spree::Property.where(name: "Collection").first
google_merchant_color            = Spree::Property.where(name: "Resin Colour").first

collection = product.product_properties.where(property_id: product_collection.id).first               if product_collection
color      = product.product_properties.where(property_id: google_merchant_color.id).first            if google_merchant_color

taxon = product.taxons.first
taxon_path = taxon.permalink
taxon_path = taxon_path.gsub("/"," > ")

product.meta_title.blank? ? xml.tag!("g:title", product.name) : xml.tag!("g:title", product.meta_title)

if product.meta_description.present?
  xml.tag!("g:description", product.meta_description)
else
  xml.tag!("g:description", strip_tags(product.description))
end

xml.tag!("g:link", 'https://' + current_store.url + '/products/' + product.slug + '?currency=AUD')

unless product.images.empty?
  product.images.each_with_index do |image, index|
    if index == 0
      structured_feed_images_url = structured_feed_images(product)
      structured_feed_images_url.end_with?("USD") ? structured_feed_images_url.slice!(-13,13) : structured_feed_images_url
      xml.tag!("g:image_link", structured_feed_images_url)
    else
      image_url = image.url(:large)).url
      image_url.end_with?("USD") ? image_url.slice!(-13,13) : image_url
      xml.tag!("additional_image_link", image_url)
    end
  end
end

xml.tag!("g:brand", "BoldB")
xml.tag!("g:availability", product.in_stock? ? "in stock" : "out of stock")

if defined?(product.compare_at_price) && !product.compare_at_price.nil?
  if product.compare_at_price > product.price
    xml.tag!("g:price", product.compare_at_price.to_s + " " + current_currency)
    xml.tag!("g:sale_price", product.price_in(current_currency).amount.to_s + " " + current_currency)
  else
    xml.tag!("g:price", product.price_in(current_currency).amount.to_s + " " + current_currency)
  end
else
  xml.tag!("g:price", product.price_in(current_currency).amount.to_s + " " + current_currency)
end

xml.tag!("g:" + product.unique_identifier_type, product.unique_identifier)
xml.tag!("g:sku", structured_sku(product))

if product.has_google_product_category?
  google_product_property = Spree::Property.where(name: "Google Product Category").first
  google_product_category = product.product_properties.where(property_id: google_product_property.id).first
  xml.tag!("g:google_product_category", google_product_category.value)
end

if product.has_gender_property?
  gender_property = Spree::Property.where(name: "Gender").first
  gender = product.product_properties.where(property_id: gender_property.id).first
  xml.tag!("g:gender", gender.value)
end

if product.has_age_group_property?
  age_group_property = Spree::Property.where(name: "Age Group").first
  age_group = product.product_properties.where(property_id: age_group_property.id).first
  xml.tag!("g:age_group", age_group.value)
end

if product.has_product_colour_property?
  product_colour_property = Spree::Property.where(name: "Product Colour").first
  product_colour = product.product_properties.where(property_id: product_colour_property.id).first
  xml.tag!("g:color", product_colour.value)
end

if product.has_size_property?
  size_property = Spree::Property.where(name: "Size").first
  size = product.product_properties.where(property_id: size_property.id).first
  xml.tag!("g:size", size.value)
end

xml.tag!("g:product_type", taxon_path)
xml.tag!("g:id", structured_sku(product))
xml.tag!("g:condition", "new")

unless product.product_properties.blank?
  xml << render(partial: "props", locals: {product: product})
end

# Remove shipping_weight to prevent shipping error
# xml.tag! "shipping_weight", "#{product.weight.to_i} g"
xml.tag! "custom_label_0", collection.value if collection
xml.tag! "custom_label_1", product.name
