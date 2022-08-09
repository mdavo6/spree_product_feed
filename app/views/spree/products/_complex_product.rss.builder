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

unless variant.images.empty?
  variant.images.each_with_index do |image, index|
    if index == 0
      structured_feed_images_url = structured_feed_images(variant).to_s
      structured_feed_images_url.end_with?("USD") ? structured_feed_images_url.slice(-13,13) : structured_feed_images_url
      xml.tag!("g:image_link", structured_feed_images_url)
    else
      image_url = main_app.rails_blob_url(image.attachment).to_s
      image_url.end_with?("USD") ? image_url.slice(-13,13) : image_url
      xml.tag!("additional_image_link", image_url)
    end
  end
end

xml.tag!("g:brand", "BoldB")
xml.tag!("g:availability", variant.in_stock? ? "in stock" : "out of stock")

if defined?(variant.compare_at_price) && !variant.compare_at_price.nil?
  if variant.compare_at_price > product.price
    xml.tag!("g:price", variant.compare_at_price.to_s + " " + current_currency)
    xml.tag!("g:sale_price", variant.price_in(current_currency).amount.to_s + " " + current_currency)
  else
    xml.tag!("g:price", variant.price_in(current_currency).amount.to_s + " " + current_currency)
  end
else
  xml.tag!("g:price", variant.price_in(current_currency).amount.to_s + " " + current_currency)
end

xml.tag!("g:" + variant.unique_identifier_type, variant.unique_identifier)
xml.tag!("g:sku", variant.sku)
xml.tag!("g:google_product_category", taxon.google_product_category) if product.taxons.first.google_product_category.present?

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
xml.tag!("g:id", variant.sku)
xml.tag!("g:condition", "new")
xml.tag!("g:item_group_id", product.sku)

options_xml_hash = Spree::Variants::XmlFeedOptionsPresenter.new(variant).xml_options
options_xml_hash.each do |ops|
  if ops.option_type[:name] == "color"
    # Necklaces
    if product.has_necklace_material_property?
      necklace_material_property = Spree::Property.where(name: "Necklace Material").first
      necklace_material = product.product_properties.where(property_id: necklace_material_property.id).first
      if necklace_material.value.downcase.include?("cord")
        if ops.name == "Aqua"
          xml.tag!("g:color", "light blue/light brown")
        elsif ops.name == "Ultramarine"
          xml.tag!("g:color", "dark blue/light brown")
        end
      elsif necklace_material.value.downcase.include?("chain")
        if ops.name == "Aqua"
          xml.tag!("g:color", "light blue/silver")
        elsif ops.name == "Ultramarine"
          xml.tag!("g:color", "dark blue/silver")
        end
      end
    # Earrings
    elsif product.has_google_product_category? && google_product_category.value == "194"
      if ops.name == "Aqua"
        xml.tag!("g:color", "light blue/silver")
      elsif ops.name == "Ultramarine"
        xml.tag!("g:color", "dark blue/silver")
      end
    # Rings
    elsif product.has_google_product_category? && google_product_category.value == "200"
      if ops.name == "Aqua"
        xml.tag!("g:color", "light blue")
      elsif ops.name == "Ultramarine"
        xml.tag!("g:color", "dark blue")
      end
    end
  # Bangle
  elsif ops.option_type[:name] == "Bangle"
    if ops.name.include?("Aqua")
      xml.tag!("g:color", "light blue")
    elsif ops.name.include?("Ultramarine")
      xml.tag!("g:color", "dark blue")
    end
    if ops.name.include?("Small")
      xml.tag!("g:size", "S")
    elsif ops.name.include?("Large")
      xml.tag!("g:size", "L")
    end
  else
    xml.tag!("g:" + ops.option_type.presentation.downcase, ops.presentation)
  end
end

unless product.product_properties.blank?
  xml << render(partial: "props", locals: {product: product})
end

# Remove shipping_weight to prevent shipping error
# xml.tag! "shipping_weight", "#{variant.weight.to_i} g"
xml.tag! "custom_label_0", collection.value if collection
xml.tag! "custom_label_1", product.name
