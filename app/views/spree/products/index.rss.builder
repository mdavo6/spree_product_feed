# frozen_string_literal: true

xml = Builder::XmlMarkup.new
xml.instruct! :xml, version: "1.0"
xml.rss("xmlns:g" => "http://base.google.com/ns/1.0", :version => "2.0") {
  xml.channel {
    xml.title(current_store.name)
    xml.link(current_store.url)
    xml.description("RSS feed of our unique jewellery")

    if defined?(current_store.default_locale) && !current_store.default_locale.nil?
      xml.language(current_store.default_locale.downcase)
    else
      xml.language("en-us")
    end

    @products = @products.except(:limit, :offset)
    @products.each do |product|
      if product.feed_active?
        if product.variants_and_option_values(current_currency).any?
          product.variants.each do |variant|
            if variant.show_in_product_feed?
              xml.item do
                xml << render(partial: "complex_product", locals: {product: product, variant: variant}).gsub(/^/, "      ")
              end
            end
          end
        else
          xml.item do
            xml << render(partial: "basic_product", locals: {product: product}).gsub(/^/, "      ")
          end
        end
      end
    end
  }
}
